using System.Data;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/ride-requests")]
[Authorize]
public sealed class RideRequestsController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public RideRequestsController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> CreateRideRequest(
        CreateRideRequest request,
        CancellationToken cancellationToken)
    {
        var passenger = await _db.Users.FirstOrDefaultAsync(
            user => user.Id == GetUserId() && user.Role == UserRole.Passenger, cancellationToken);
        if (passenger == null || passenger.Status != UserStatus.Verified)
            return Forbid();

        var pickup = request.Pickup;
        var requestedTime = request.RequestedTime;
        var seats = request.Seats;
        if (string.IsNullOrWhiteSpace(pickup))
            return FieldError(nameof(request.Pickup), "Pickup is required.");
        if (string.IsNullOrWhiteSpace(request.Destination))
            return FieldError(nameof(request.Destination), "Destination is required.");
        if (string.Equals(pickup.Trim(), request.Destination.Trim(), StringComparison.OrdinalIgnoreCase))
            return FieldError(nameof(request.Destination), "Pickup and destination must be different.");
        if (!requestedTime.HasValue || requestedTime.Value.UtcDateTime <= DateTime.UtcNow)
            return FieldError(nameof(request.RequestedTime), "Requested time must be in the future.");
        if (!seats.HasValue || seats.Value < 1 || seats.Value > 4)
            return FieldError(nameof(request.Seats), "Seats must be between 1 and 4.");

        var rideRequest = new RideRequest
        {
            PassengerId = passenger.Id,
            PickupArea = pickup.Trim(),
            Destination = request.Destination.Trim(),
            PickupTime = requestedTime.Value.UtcDateTime,
            SeatsNeeded = seats!.Value,
            Status = RideRequestStatus.Open,
            CreatedAt = DateTime.UtcNow
        };
        _db.RideRequests.Add(rideRequest);

        await _db.SaveChangesAsync(cancellationToken);
        return Created("/api/ride-requests/me", ToRideRequestResponse(rideRequest));
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyRideRequests(CancellationToken cancellationToken)
    {
        var passengerId = GetUserId();
        var requests = await _db.RideRequests
            .Where(request => request.PassengerId == passengerId)
            .OrderByDescending(request => request.CreatedAt)
            .ToListAsync(cancellationToken);
        return Ok(requests.Select(ToRideRequestResponse));
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> CancelRideRequest(Guid id, CancellationToken cancellationToken)
    {
        var passengerId = GetUserId();
        var updated = await _db.RideRequests
            .Where(item => item.Id == id
                && item.PassengerId == passengerId
                && item.Status == RideRequestStatus.Open)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(item => item.Status, RideRequestStatus.Cancelled),
                cancellationToken);
        if (updated == 0)
        {
            var exists = await _db.RideRequests.AnyAsync(
                item => item.Id == id && item.PassengerId == passengerId,
                cancellationToken);
            if (!exists)
                return NotFound();
            return Conflict(new ProblemDetails { Status = 409, Title = "Only open ride requests can be cancelled." });
        }

        return Ok(new { id, status = RideRequestStatus.Cancelled.ToString() });
    }

    [HttpGet("open")]
    public async Task<IActionResult> GetOpenRideRequests(CancellationToken cancellationToken)
    {
        var driver = await _db.Users
            .Include(user => user.DriverProfile)
            .FirstOrDefaultAsync(user => user.Id == GetUserId() && user.Role == UserRole.Driver, cancellationToken);
        if (driver?.DriverProfile == null)
            return Forbid();
        if (driver.Status != UserStatus.Verified || !driver.DriverProfile.IsOnline)
            return Forbid();

        var requests = await _db.RideRequests
            .Include(request => request.Passenger)
            .Where(request => request.Status == RideRequestStatus.Open && request.PickupTime > DateTime.UtcNow)
            .OrderBy(request => request.PickupTime)
            .ToListAsync(cancellationToken);
        return Ok(requests.Select(request => new
        {
            request.Id,
            passengerName = request.Passenger.FullName,
            pickup = request.PickupArea,
            request.Destination,
            requestedTime = request.PickupTime,
            seats = request.SeatsNeeded,
            status = request.Status.ToString(),
            request.CreatedAt
        }));
    }

    [HttpPost("{id:guid}/offers")]
    public async Task<IActionResult> AcceptRideRequest(
        Guid id,
        AcceptRideRequest request,
        CancellationToken cancellationToken)
    {
        var driver = await _db.Users
            .Include(user => user.DriverProfile)
            .FirstOrDefaultAsync(user => user.Id == GetUserId() && user.Role == UserRole.Driver, cancellationToken);
        if (driver?.DriverProfile == null || driver.Status != UserStatus.Verified)
            return Forbid();

        var seats = request.TotalSeats;
        var fare = request.FarePerSeat;
        if (!seats.HasValue || seats.Value < 1 || seats.Value > 4)
            return FieldError(nameof(request.TotalSeats), "Total seats must be between 1 and 4.");
        if (fare is null || fare.Value < 0.01m || fare.Value > 1_000_000m)
            return FieldError(nameof(request.FarePerSeat), "Fare per seat must be between 0.01 and 1,000,000.");
        if (seats!.Value > driver.DriverProfile.SeatCapacity)
            return FieldError(nameof(request.TotalSeats), "Ride seats cannot exceed your vehicle seat capacity.");

        await using var transaction = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, cancellationToken);
        var rideRequest = await _db.RideRequests
            .AsNoTracking()
            .Include(item => item.Passenger)
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (rideRequest == null)
            return NotFound();
        if (rideRequest.Status != RideRequestStatus.Open)
            return Conflict(new ProblemDetails { Status = 409, Title = "This ride request is no longer open." });
        if (rideRequest.PickupTime <= DateTime.UtcNow)
            return Conflict(new ProblemDetails { Status = 409, Title = "This ride request has already expired." });
        if (seats.Value < rideRequest.SeatsNeeded)
            return FieldError(nameof(request.TotalSeats), "Offered seats cannot be fewer than requested seats.");

        var now = DateTime.UtcNow;
        var ride = new Ride
        {
            DriverId = driver.Id,
            PickupArea = rideRequest.PickupArea,
            Destination = rideRequest.Destination,
            DepartureTime = rideRequest.PickupTime,
            PricePerSeat = fare.Value,
            SeatsOffered = seats.Value,
            Status = RideStatus.Active,
            SourceRideRequestId = rideRequest.Id,
            CreatedAt = now
        };
        var booking = new Booking
        {
            Ride = ride,
            RideId = ride.Id,
            PassengerId = rideRequest.PassengerId,
            SeatsRequested = rideRequest.SeatsNeeded,
            FareTotal = fare.Value * rideRequest.SeatsNeeded,
            PickupTime = rideRequest.PickupTime,
            TravelDate = rideRequest.PickupTime.Date,
            Status = BookingStatus.Accepted,
            CreatedAt = now,
            UpdatedAt = now
        };

        var claimed = await _db.RideRequests
            .Where(item => item.Id == id && item.Status == RideRequestStatus.Open)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(item => item.Status, RideRequestStatus.Accepted)
                .SetProperty(item => item.AcceptedByDriverId, driver.Id)
                .SetProperty(item => item.CreatedRideId, ride.Id),
                cancellationToken);
        if (claimed == 0)
            return Conflict(new ProblemDetails { Status = 409, Title = "This ride request was accepted by another driver." });

        _db.Rides.Add(ride);
        _db.Bookings.Add(booking);
        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return CreatedAtAction(
            nameof(RidesController.GetRide), "Rides", new { id = ride.Id },
            new { rideId = ride.Id, bookingId = booking.Id, status = BookingStatus.Accepted.ToString() });
    }

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    private static object ToRideRequestResponse(RideRequest request) => new
    {
        request.Id,
        pickup = request.PickupArea,
        request.Destination,
        requestedTime = request.PickupTime,
        seats = request.SeatsNeeded,
        status = request.Status.ToString(),
        request.AcceptedByDriverId,
        request.CreatedRideId,
        request.CreatedAt
    };
}

/// <summary>Fields used by a passenger to request a ride.</summary>
public sealed class CreateRideRequest
{
    [StringLength(100)]
    public string? Pickup { get; set; }

    [Required, StringLength(100)]
    public string Destination { get; set; } = string.Empty;

    public DateTimeOffset? RequestedTime { get; set; }

    [Range(1, 4)]
    public int? Seats { get; set; }
}

/// <summary>Fields a driver offers when accepting a ride request.</summary>
public sealed class AcceptRideRequest
{
    [Range(1, 4)]
    public int? TotalSeats { get; set; }

    [Range(0.01, 1000000)]
    public decimal? FarePerSeat { get; set; }
}
