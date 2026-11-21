using System.Data;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize]
public sealed class BookingsController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public BookingsController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking(CreateBookingRequest request, CancellationToken cancellationToken)
    {
        var passengerId = GetUserId();
        if (request.RideId == Guid.Empty)
            return FieldError(nameof(request.RideId), "Ride ID is required.");
        var seats = request.Seats ?? request.SeatsRequested;
        if (!seats.HasValue || seats.Value < 1 || seats.Value > 4)
            return FieldError(nameof(request.Seats), "Seats must be between 1 and 4.");

        await using var transaction = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        var passenger = await _db.Users.FirstOrDefaultAsync(
            user => user.Id == passengerId && user.Role == UserRole.Passenger, cancellationToken);
        if (passenger == null || passenger.Status != UserStatus.Verified)
            return Forbid();

        var ride = await _db.Rides
            .Include(item => item.Driver)
            .Include(item => item.Bookings.Where(booking =>
                booking.Status == BookingStatus.Accepted || booking.Status == BookingStatus.Active))
            .FirstOrDefaultAsync(item => item.Id == request.RideId, cancellationToken);
        if (ride == null)
            return NotFound(new ProblemDetails { Status = 404, Title = "Ride not found." });
        if (ride.Status != RideStatus.Active || ride.DepartureTime <= DateTime.UtcNow)
            return Conflict(new ProblemDetails { Status = 409, Title = "This ride is not available for booking." });

        var hasBooking = await _db.Bookings.AnyAsync(booking =>
            booking.RideId == ride.Id &&
            booking.PassengerId == passengerId &&
            (booking.Status == BookingStatus.Pending
                || booking.Status == BookingStatus.Accepted
                || booking.Status == BookingStatus.Active),
            cancellationToken);
        if (hasBooking)
            return Conflict(new ProblemDetails { Status = 409, Title = "You already have an active booking on this ride." });

        var availableSeats = ride.SeatsOffered - ride.Bookings.Sum(booking => booking.SeatsRequested);
        if (seats!.Value > availableSeats)
            return Conflict(new ProblemDetails { Status = 409, Title = $"Only {availableSeats} seats are available." });

        var booking = new Booking
        {
            RideId = ride.Id,
            PassengerId = passengerId,
            SeatsRequested = seats.Value,
            FareTotal = ride.PricePerSeat * seats.Value,
            PickupTime = request.PickupTime?.UtcDateTime ?? ride.DepartureTime,
            TravelDate = ride.DepartureTime.Date,
            Status = BookingStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Bookings.Add(booking);
        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return CreatedAtAction(nameof(GetBooking), new { id = booking.Id }, ToBookingResponse(booking, ride, passenger));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetBooking(Guid id, CancellationToken cancellationToken)
    {
        var booking = await GetBookingQuery()
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (booking == null)
            return NotFound();
        var userId = GetUserId();
        if (booking.PassengerId != userId && booking.Ride.DriverId != userId)
            return Forbid();

        return Ok(ToBookingResponse(booking, booking.Ride, booking.Passenger));
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetPassengerBookings(
        [FromQuery] string? status,
        CancellationToken cancellationToken)
    {
        var passengerId = GetUserId();
        if (!TryParseStatus(status, out var bookingStatus))
            return FieldError(nameof(status), "Booking status is invalid.");

        var query = GetBookingQuery().Where(booking => booking.PassengerId == passengerId);
        if (bookingStatus.HasValue)
            query = query.Where(booking => booking.Status == bookingStatus.Value);
        var bookings = await query.OrderByDescending(booking => booking.CreatedAt).ToListAsync(cancellationToken);
        return Ok(bookings.Select(booking => ToBookingResponse(booking, booking.Ride, booking.Passenger)));
    }

    [HttpGet("/api/drivers/me/bookings")]
    public async Task<IActionResult> GetDriverBookings(
        [FromQuery] string? status,
        CancellationToken cancellationToken)
    {
        var driverId = GetUserId();
        if (!TryParseStatus(status, out var bookingStatus))
            return FieldError(nameof(status), "Booking status is invalid.");

        var query = GetBookingQuery().Where(booking => booking.Ride.DriverId == driverId);
        if (bookingStatus.HasValue)
            query = query.Where(booking => booking.Status == bookingStatus.Value);
        var bookings = await query.OrderByDescending(booking => booking.CreatedAt).ToListAsync(cancellationToken);
        return Ok(bookings.Select(booking => ToBookingResponse(booking, booking.Ride, booking.Passenger)));
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateBookingStatus(
        Guid id,
        UpdateBookingStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<BookingStatus>(request.Status, true, out var status)
            || !Enum.IsDefined(status))
            return FieldError(nameof(request.Status), "Booking status is invalid.");

        return await ChangeStatusAsync(id, status, cancellationToken);
    }

    [HttpPost("{id:guid}/review")]
    public async Task<IActionResult> ReviewBooking(Guid id, ReviewBookingRequest request, CancellationToken cancellationToken)
    {
        if (request.Rating is < 1 or > 5)
            return FieldError(nameof(request.Rating), "Rating must be between 1 and 5.");
        if (request.Review?.Length > 500)
            return FieldError(nameof(request.Review), "Review cannot exceed 500 characters.");

        var passengerId = GetUserId();
        var booking = await _db.Bookings
            .Include(item => item.Ride)
                .ThenInclude(ride => ride.Driver)
                    .ThenInclude(driver => driver.DriverProfile)
            .FirstOrDefaultAsync(item => item.Id == id && item.PassengerId == passengerId, cancellationToken);
        if (booking == null)
            return NotFound();
        if (booking.Status != BookingStatus.Completed)
            return Conflict(new ProblemDetails { Status = 409, Title = "Only completed bookings can be reviewed." });
        if (booking.Rating.HasValue)
            return Conflict(new ProblemDetails { Status = 409, Title = "This booking has already been reviewed." });

        booking.Rating = request.Rating;
        booking.Review = request.Review?.Trim();
        booking.RatedAt = DateTime.UtcNow;
        var ratings = await _db.Bookings
            .Where(item => item.Ride.DriverId == booking.Ride.DriverId && item.Rating.HasValue)
            .Select(item => item.Rating.GetValueOrDefault())
            .ToListAsync(cancellationToken);
        if (booking.Ride.Driver.DriverProfile != null)
            booking.Ride.Driver.DriverProfile.AverageRating = Math.Round(ratings.Append(request.Rating).Average(), 1);

        await _db.SaveChangesAsync(cancellationToken);
        return Ok(new { message = "Review submitted successfully.", booking.Rating, booking.Review });
    }

    private async Task<IActionResult> ChangeStatusAsync(Guid id, BookingStatus nextStatus, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var booking = await GetBookingQuery().FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (booking == null)
            return NotFound();

        var isPassenger = booking.PassengerId == userId;
        var isDriver = booking.Ride.DriverId == userId;
        var allowed = nextStatus switch
        {
            BookingStatus.Cancelled => isPassenger && booking.Status == BookingStatus.Pending,
            BookingStatus.Accepted => isDriver && booking.Status == BookingStatus.Pending,
            BookingStatus.Rejected => isDriver && booking.Status == BookingStatus.Pending,
            BookingStatus.Active => isDriver && booking.Status == BookingStatus.Accepted,
            BookingStatus.Completed => isDriver && booking.Status == BookingStatus.Active,
            _ => false
        };
        if (!allowed)
        {
            if (!isPassenger && !isDriver)
                return Forbid();
            return Conflict(new ProblemDetails { Status = 409, Title = $"Cannot change booking from {booking.Status} to {nextStatus}." });
        }

        if (nextStatus is BookingStatus.Active or BookingStatus.Completed
            && booking.Ride.DepartureTime > DateTime.UtcNow)
        {
            return Conflict(new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title = "The ride cannot be started or completed before its scheduled departure."
            });
        }

        if (nextStatus == BookingStatus.Accepted)
        {
            await using var transaction = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
            var otherAcceptedSeats = await _db.Bookings
                .Where(item => item.RideId == booking.RideId &&
                    item.Id != booking.Id &&
                    (item.Status == BookingStatus.Accepted || item.Status == BookingStatus.Active))
                .SumAsync(item => (int?)item.SeatsRequested, cancellationToken) ?? 0;
            if (booking.SeatsRequested > booking.Ride.SeatsOffered - otherAcceptedSeats)
                return Conflict(new ProblemDetails { Status = 409, Title = "There are not enough seats remaining." });

            booking.Status = nextStatus;
            booking.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Ok(new { bookingId = booking.Id, status = booking.Status.ToString() });
        }

        booking.Status = nextStatus;
        booking.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(new { bookingId = booking.Id, status = booking.Status.ToString() });
    }

    private IQueryable<Booking> GetBookingQuery() =>
        _db.Bookings
            .Include(booking => booking.Ride)
                .ThenInclude(ride => ride.Driver)
            .Include(booking => booking.Passenger);

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private static bool TryParseStatus(string? value, out BookingStatus? status)
    {
        status = null;
        if (string.IsNullOrWhiteSpace(value))
            return true;
        if (int.TryParse(value, out _) || !Enum.TryParse(value, true, out BookingStatus parsed) || !Enum.IsDefined(parsed))
            return false;
        status = parsed;
        return true;
    }

    private static object ToBookingResponse(Booking booking, Ride ride, User passenger) => new
    {
        booking.Id,
        booking.RideId,
        booking.PassengerId,
        driverId = ride.DriverId,
        passengerName = passenger.FullName,
        driverName = ride.Driver.FullName,
        pickupArea = ride.PickupArea,
        destination = ride.Destination,
        seatsRequested = booking.SeatsRequested,
        seats = booking.SeatsRequested,
        fareTotal = booking.FareTotal,
        pickupTime = booking.PickupTime,
        departureTime = ride.DepartureTime,
        status = booking.Status.ToString(),
        travelDate = booking.TravelDate,
        pricePerSeat = ride.PricePerSeat,
        rating = booking.Rating ?? 0,
        booking.Review,
        booking.CreatedAt,
        booking.UpdatedAt
    };

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });
}

/// <summary>Fields used to request seats on a ride.</summary>
public sealed class CreateBookingRequest
{
    [Required]
    public Guid RideId { get; set; }

    [Range(1, 4)]
    public int? Seats { get; set; }

    [Range(1, 4)]
    public int? SeatsRequested { get; set; }

    public DateTimeOffset? PickupTime { get; set; }
}

/// <summary>Fields used to submit a booking review.</summary>
public sealed class ReviewBookingRequest
{
    [Range(1, 5)]
    public int Rating { get; set; }

    [StringLength(500)]
    public string? Review { get; set; }
}

/// <summary>Target status for a booking transition.</summary>
public sealed class UpdateBookingStatusRequest
{
    [Required]
    public string Status { get; set; } = string.Empty;
}
