using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/emergency-alerts")]
[Authorize]
public sealed class EmergencyAlertsController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public EmergencyAlertsController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    /// <summary>Creates an SOS alert for the authenticated passenger or driver.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(EmergencyAlertResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(EmergencyAlertResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        CreateEmergencyAlertRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
            return Unauthorized();
        if (request.ClientRequestId == Guid.Empty)
            return FieldError(nameof(request.ClientRequestId), "A request ID is required.");
        if (request.Latitude.HasValue != request.Longitude.HasValue)
            return FieldError(nameof(request.Latitude), "Latitude and longitude must be supplied together.");

        var user = await _db.Users
            .Include(candidate => candidate.PassengerProfile)
            .Include(candidate => candidate.DriverProfile)
            .FirstOrDefaultAsync(candidate => candidate.Id == userId, cancellationToken);
        if (user == null)
            return Unauthorized();
        if (user.Role is not UserRole.Passenger and not UserRole.Driver)
            return Forbid();

        var existing = await _db.EmergencyAlerts
            .AsNoTracking()
            .FirstOrDefaultAsync(
                alert => alert.UserId == userId && alert.ClientRequestId == request.ClientRequestId.ToString(),
                cancellationToken);
        if (existing != null)
            return Ok(ToResponse(existing));

        if (request.RideId.HasValue)
        {
            var rideIsAssociated = await _db.Rides.AnyAsync(
                ride => ride.Id == request.RideId.Value &&
                    (user.Role == UserRole.Driver
                        ? ride.DriverId == userId
                        : ride.Bookings.Any(booking =>
                            booking.PassengerId == userId &&
                            (booking.Status == BookingStatus.Accepted ||
                             booking.Status == BookingStatus.Active))),
                cancellationToken);
            if (!rideIsAssociated)
                return FieldError(nameof(request.RideId), "The ride is not associated with this account.");
        }

        var alert = new EmergencyAlert
        {
            UserId = user.Id,
            ReporterRole = user.Role,
            ClientRequestId = request.ClientRequestId.ToString(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            RideId = request.RideId,
            Status = "Open",
            CreatedAt = DateTime.UtcNow
        };
        _db.EmergencyAlerts.Add(alert);

        try
        {
            await _db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            var duplicate = await _db.EmergencyAlerts
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    item => item.UserId == userId && item.ClientRequestId == alert.ClientRequestId,
                    cancellationToken);
            if (duplicate == null)
                throw;
            return Ok(ToResponse(duplicate));
        }

        return Created("/api/emergency-alerts/me", ToResponse(alert));
    }

    /// <summary>Returns SOS alerts created by the authenticated user.</summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(IReadOnlyList<EmergencyAlertResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
            return Unauthorized();

        var alerts = await _db.EmergencyAlerts
            .AsNoTracking()
            .Where(alert => alert.UserId == userId)
            .OrderByDescending(alert => alert.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);
        return Ok(alerts.Select(ToResponse).ToList());
    }

    /// <summary>Returns recent SOS alerts with user and ride details for Admin review.</summary>
    [HttpGet("/api/admin/emergency-alerts")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(IReadOnlyList<AdminEmergencyAlertResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetForAdmin(CancellationToken cancellationToken)
    {
        var alerts = await _db.EmergencyAlerts
            .AsNoTracking()
            .Include(alert => alert.User)
                .ThenInclude(user => user.PassengerProfile)
            .Include(alert => alert.User)
                .ThenInclude(user => user.DriverProfile)
            .Include(alert => alert.Ride)
            .OrderByDescending(alert => alert.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);

        return Ok(alerts.Select(alert => new AdminEmergencyAlertResponse(
            alert.Id,
            alert.ReporterRole.ToString(),
            alert.Latitude,
            alert.Longitude,
            alert.RideId,
            ToDateTimeOffset(alert.CreatedAt),
            alert.Status,
            new EmergencyAlertUserResponse(
                alert.User.Id,
                alert.User.FullName,
                alert.User.Email,
                alert.User.Phone,
                alert.User.Role.ToString(),
                alert.User.PassengerProfile?.EmergencyContactName ?? alert.User.DriverProfile?.EmergencyContactName,
                alert.User.PassengerProfile?.EmergencyContactPhone ?? alert.User.DriverProfile?.EmergencyContactPhone),
            alert.Ride == null
                ? null
                : new EmergencyAlertRideResponse(
                    alert.Ride.Id,
                    alert.Ride.PickupArea,
                    alert.Ride.Destination,
                    alert.Ride.Status.ToString(),
                    ToDateTimeOffset(alert.Ride.DepartureTime)))).ToList());
    }

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId)
            ? userId
            : Guid.Empty;

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    private static EmergencyAlertResponse ToResponse(EmergencyAlert alert) =>
        new(
            alert.Id,
            alert.ReporterRole.ToString(),
            alert.Latitude,
            alert.Longitude,
            alert.RideId,
            ToDateTimeOffset(alert.CreatedAt),
            alert.Status);

    private static DateTimeOffset ToDateTimeOffset(DateTime value) =>
        new(DateTime.SpecifyKind(value, DateTimeKind.Utc));
}

/// <summary>Location and idempotency data for an SOS alert.</summary>
public sealed record CreateEmergencyAlertRequest
{
    /// <summary>Unique ID reused when retrying the same alert request.</summary>
    [Required]
    public required Guid ClientRequestId { get; init; }

    /// <summary>Latitude from the device, when location permission is available.</summary>
    [Range(-90, 90)]
    public double? Latitude { get; init; }

    /// <summary>Longitude from the device, when location permission is available.</summary>
    [Range(-180, 180)]
    public double? Longitude { get; init; }

    /// <summary>Optional ride associated with this alert.</summary>
    public Guid? RideId { get; init; }
}

/// <summary>Basic details of an SOS alert returned to its owner.</summary>
public sealed record EmergencyAlertResponse(
    Guid Id,
    string Role,
    double? Latitude,
    double? Longitude,
    Guid? RideId,
    DateTimeOffset CreatedAt,
    string Status);

/// <summary>User and emergency contact information visible to Admin.</summary>
public sealed record EmergencyAlertUserResponse(
    Guid Id,
    string Name,
    string Email,
    string Phone,
    string Role,
    string? EmergencyContactName,
    string? EmergencyContactPhone);

/// <summary>Ride information related to an SOS alert.</summary>
public sealed record EmergencyAlertRideResponse(
    Guid Id,
    string Pickup,
    string Destination,
    string Status,
    DateTimeOffset DepartureTime);

/// <summary>An SOS alert and its associated user and optional ride.</summary>
public sealed record AdminEmergencyAlertResponse(
    Guid Id,
    string Role,
    double? Latitude,
    double? Longitude,
    Guid? RideId,
    DateTimeOffset CreatedAt,
    string Status,
    EmergencyAlertUserResponse User,
    EmergencyAlertRideResponse? Ride);
