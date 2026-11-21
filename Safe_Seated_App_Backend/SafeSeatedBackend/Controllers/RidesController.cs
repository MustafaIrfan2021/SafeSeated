using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/rides")]
[Authorize]
public sealed class RidesController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public RidesController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> CreateRide(RideWriteRequest request, CancellationToken cancellationToken)
    {
        var values = GetRideValues(request);
        var validationError = ValidateRideValues(values, requireAll: true);
        if (validationError != null)
            return validationError;

        var driver = await GetCurrentDriverAsync(cancellationToken);
        if (driver == null)
            return Forbid();
        if (driver.Status != UserStatus.Verified || driver.DriverProfile == null)
            return Forbid();
        if (values.Seats!.Value > driver.DriverProfile.SeatCapacity)
            return FieldError(nameof(request.TotalSeats), "Ride seats cannot exceed your vehicle seat capacity.");

        var now = DateTime.UtcNow;
        var ride = new Ride
        {
            DriverId = driver.Id,
            PickupArea = values.Pickup!,
            Destination = values.Destination!,
            DepartureTime = values.DepartureTime!.Value.UtcDateTime,
            PricePerSeat = values.Fare!.Value,
            SeatsOffered = values.Seats!.Value,
            Notes = values.Notes?.Trim(),
            Status = RideStatus.Active,
            CreatedAt = now
        };

        _db.Rides.Add(ride);
        await _db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetRide), new { id = ride.Id }, ToRideResponse(ride, driver));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetRide(Guid id, CancellationToken cancellationToken)
    {
        var ride = await GetRideQuery()
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        return ride == null ? NotFound() : Ok(ToRideResponse(ride, ride.Driver));
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> SearchRides(
        [FromQuery] string? pickup = null,
        [FromQuery] string? destination = null,
        [FromQuery] DateTime? date = null,
        [FromQuery] int seats = 1,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string sortBy = "DepartureTime",
        CancellationToken cancellationToken = default)
    {
        if (seats < 1 || seats > 4)
            return FieldError(nameof(seats), "Seats must be between 1 and 4.");

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var now = DateTime.UtcNow;
        var query = _db.Rides
            .AsNoTracking()
            .Where(ride =>
                ride.Status == RideStatus.Active &&
                ride.DepartureTime > now &&
                ride.Driver.Status == UserStatus.Verified &&
                ride.Driver.DriverProfile != null &&
                ride.Driver.DriverProfile.IsOnline &&
                (string.IsNullOrWhiteSpace(pickup) || ride.PickupArea.Contains(pickup)) &&
                (string.IsNullOrWhiteSpace(destination) || ride.Destination.Contains(destination)) &&
                ride.SeatsOffered - (ride.Bookings
                    .Where(booking =>
                        booking.Status == BookingStatus.Accepted
                        || booking.Status == BookingStatus.Active)
                    .Sum(booking => (int?)booking.SeatsRequested) ?? 0) >= seats);
        if (date.HasValue)
        {
            var searchDate = date.Value.Date;

            query = query.Where(ride => ride.DepartureTime.Date == searchDate);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        query = sortBy.ToLowerInvariant() switch
        {
            "price" or "fare" => query.OrderBy(ride => ride.PricePerSeat),
            "price_desc" or "fare_desc" => query.OrderByDescending(ride => ride.PricePerSeat),
            _ => query.OrderBy(ride => ride.DepartureTime)
        };

        var rides = await query
            .Include(ride => ride.Driver)
                .ThenInclude(driver => driver.DriverProfile)
            .Include(ride => ride.Bookings.Where(booking =>
                booking.Status == BookingStatus.Accepted
                || booking.Status == BookingStatus.Active))
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            data = rides.Select(ride => ToRideResponse(ride, ride.Driver)),
            pagination = new { page, pageSize, totalCount, totalPages = (totalCount + pageSize - 1) / pageSize }
        });
    }

    [HttpGet("/api/drivers/me/rides")]
    public async Task<IActionResult> GetMyRides(CancellationToken cancellationToken)
    {
        var driverId = GetUserId();
        if (!await _db.Users.AnyAsync(user => user.Id == driverId && user.Role == UserRole.Driver, cancellationToken))
            return Forbid();

        var rides = await GetRideQuery()
            .Where(ride => ride.DriverId == driverId)
            .OrderByDescending(ride => ride.CreatedAt)
            .ToListAsync(cancellationToken);
        return Ok(rides.Select(ride => ToRideResponse(ride, ride.Driver)));
    }

    [HttpPatch("{id:guid}")]
    public async Task<IActionResult> UpdateRide(Guid id, RideWriteRequest request, CancellationToken cancellationToken)
    {
        var ride = await GetRideQuery().FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (ride == null)
            return NotFound();
        if (ride.DriverId != GetUserId())
            return Forbid();
        if (ride.Status != RideStatus.Active)
            return Conflict(new ProblemDetails { Status = 409, Title = "Only active rides can be updated." });

        var values = GetRideValues(request, ride);
        var validationError = ValidateRideValues(values, requireAll: false);
        if (validationError != null)
            return validationError;

        var acceptedSeats = ride.Bookings
            .Where(booking => booking.Status is BookingStatus.Accepted or BookingStatus.Active)
            .Sum(booking => booking.SeatsRequested);
        if (values.Seats!.Value < acceptedSeats)
            return FieldError(nameof(request.TotalSeats), $"Seats cannot be reduced below {acceptedSeats} accepted seats.");

        var driver = ride.Driver;
        if (driver.DriverProfile == null || values.Seats.Value > driver.DriverProfile.SeatCapacity)
            return FieldError(nameof(request.TotalSeats), "Ride seats cannot exceed your vehicle seat capacity.");

        ride.PickupArea = values.Pickup!;
        ride.Destination = values.Destination!;
        ride.DepartureTime = values.DepartureTime!.Value.UtcDateTime;
        ride.PricePerSeat = values.Fare!.Value;
        ride.SeatsOffered = values.Seats.Value;
        if (values.NotesWasProvided)
            ride.Notes = values.Notes?.Trim();

        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToRideResponse(ride, driver));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteRide(Guid id, CancellationToken cancellationToken)
    {
        var result = await CancelRideCoreAsync(id, cancellationToken);
        return result ?? NoContent();
    }

    [HttpPatch("/api/drivers/me/availability")]
    public async Task<IActionResult> UpdateAvailability(
        DriverAvailabilityRequest request,
        CancellationToken cancellationToken)
    {
        var driver = await GetCurrentDriverAsync(cancellationToken);
        if (driver?.DriverProfile == null)
            return Forbid();
        if (request.IsOnline && driver.Status != UserStatus.Verified)
            return Conflict(new ProblemDetails { Status = 409, Title = "Only verified drivers can go online." });

        driver.DriverProfile.IsOnline = request.IsOnline;
        await _db.SaveChangesAsync(cancellationToken);
        return Ok(new { isOnline = driver.DriverProfile.IsOnline });
    }

    private async Task<IActionResult?> CancelRideCoreAsync(Guid id, CancellationToken cancellationToken)
    {
        var ride = await GetRideQuery().FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (ride == null)
            return NotFound();
        if (ride.DriverId != GetUserId())
            return Forbid();
        if (ride.Status != RideStatus.Active)
            return Conflict(new ProblemDetails { Status = 409, Title = "Only active rides can be cancelled." });

        ride.Status = RideStatus.Cancelled;
        foreach (var booking in ride.Bookings.Where(booking =>
                     booking.Status is BookingStatus.Pending or BookingStatus.Accepted or BookingStatus.Active))
        {
            booking.Status = BookingStatus.Cancelled;
            booking.UpdatedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return null;
    }

    private IQueryable<Ride> GetRideQuery() =>
        _db.Rides
            .Include(ride => ride.Driver)
                .ThenInclude(driver => driver.DriverProfile)
            .Include(ride => ride.Bookings.Where(booking =>
                booking.Status == BookingStatus.Pending
                || booking.Status == BookingStatus.Accepted
                || booking.Status == BookingStatus.Active));

    private Task<User?> GetCurrentDriverAsync(CancellationToken cancellationToken) =>
        _db.Users
            .Include(user => user.DriverProfile)
            .FirstOrDefaultAsync(user => user.Id == GetUserId() && user.Role == UserRole.Driver, cancellationToken);

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private static RideValues GetRideValues(RideWriteRequest request, Ride? current = null)
    {
        var pickupProvided = request.Pickup != null;
        var destinationProvided = request.Destination != null;
        var departureProvided = request.DepartureTime.HasValue;
        var fareProvided = request.FarePerSeat.HasValue;
        var seatsProvided = request.TotalSeats.HasValue;

        return new RideValues(
            request.Pickup ?? current?.PickupArea,
            request.Destination ?? current?.Destination,
            request.DepartureTime ?? (current == null ? null : new DateTimeOffset(DateTime.SpecifyKind(current.DepartureTime, DateTimeKind.Utc))),
            request.FarePerSeat ?? current?.PricePerSeat,
            request.TotalSeats ?? current?.SeatsOffered,
            request.Notes ?? current?.Notes,
            request.Notes != null,
            pickupProvided,
            destinationProvided,
            departureProvided,
            fareProvided,
            seatsProvided);
    }

    private IActionResult? ValidateRideValues(RideValues values, bool requireAll)
    {
        if (requireAll && (!values.PickupProvided || !values.DestinationProvided
            || !values.DepartureProvided || !values.FareProvided || !values.SeatsProvided))
        {
            return FieldError(nameof(RideWriteRequest.Pickup), "Pickup, destination, departure time, fare, and total seats are required.");
        }
        if (string.IsNullOrWhiteSpace(values.Pickup))
            return FieldError(nameof(RideWriteRequest.Pickup), "Pickup is required.");
        if (string.IsNullOrWhiteSpace(values.Destination))
            return FieldError(nameof(RideWriteRequest.Destination), "Destination is required.");
        if (string.Equals(values.Pickup.Trim(), values.Destination.Trim(), StringComparison.OrdinalIgnoreCase))
            return FieldError(nameof(RideWriteRequest.Destination), "Pickup and destination must be different.");
        if (!values.DepartureTime.HasValue || values.DepartureTime.Value.UtcDateTime <= DateTime.UtcNow)
            return FieldError(nameof(RideWriteRequest.DepartureTime), "Departure time must be in the future.");
        if (values.Fare is null or <= 0)
            return FieldError(nameof(RideWriteRequest.FarePerSeat), "Fare per seat must be greater than zero.");
        if (values.Seats is null or < 1 or > 4)
            return FieldError(nameof(RideWriteRequest.TotalSeats), "Total seats must be between 1 and 4.");
        if (values.Notes?.Length > 500)
            return FieldError(nameof(RideWriteRequest.Notes), "Notes must not exceed 500 characters.");

        return null;
    }

    private static object ToRideResponse(Ride ride, User driver)
    {
        var bookedSeats = ride.Bookings
            .Where(booking => booking.Status is BookingStatus.Accepted or BookingStatus.Active)
            .Sum(booking => booking.SeatsRequested);
        var model = driver.DriverProfile?.VehicleMakeModel ?? string.Empty;
        return new
        {
            ride.Id,
            ride.DriverId,
            driverName = driver.FullName,
            driverRating = driver.DriverProfile?.AverageRating ?? 0,
            driverTotalReviews = 0,
            vehicleMakeModel = model,
            vehicleColor = driver.DriverProfile?.VehicleColor ?? string.Empty,
            plateNumber = driver.DriverProfile?.PlateNumber,
            pickup = ride.PickupArea,
            pickupArea = ride.PickupArea,
            ride.Destination,
            ride.DepartureTime,
            farePerSeat = ride.PricePerSeat,
            pricePerSeat = ride.PricePerSeat,
            totalSeats = ride.SeatsOffered,
            seatsOffered = ride.SeatsOffered,
            seatsAvailable = ride.SeatsOffered - bookedSeats,
            ride.Notes,
            status = ride.Status.ToString(),
            ride.CreatedAt
        };
    }

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    private sealed record RideValues(
        string? Pickup,
        string? Destination,
        DateTimeOffset? DepartureTime,
        decimal? Fare,
        int? Seats,
        string? Notes,
        bool NotesWasProvided,
        bool PickupProvided,
        bool DestinationProvided,
        bool DepartureProvided,
        bool FareProvided,
        bool SeatsProvided);
}

/// <summary>Fields used to create or update a ride.</summary>
public sealed class RideWriteRequest
{
    [StringLength(100)]
    public string? Pickup { get; set; }

    [StringLength(100)]
    public string? Destination { get; set; }

    public DateTimeOffset? DepartureTime { get; set; }

    [Range(0.01, 1000000)]
    public decimal? FarePerSeat { get; set; }

    [Range(1, 4)]
    public int? TotalSeats { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }
}

/// <summary>Driver's requested online availability.</summary>
public sealed class DriverAvailabilityRequest
{
    public bool IsOnline { get; set; }
}
