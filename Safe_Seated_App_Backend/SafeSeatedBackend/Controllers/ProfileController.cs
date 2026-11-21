using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Models;
using SafeSeatedBackend.Data;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public ProfileController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    [HttpGet("/api/me")]
    public async Task<IActionResult> GetMe()
    {
        var user = await GetCurrentUserQuery().FirstOrDefaultAsync();
        return user == null ? NotFound() : Ok(ToProfile(user));
    }

    [HttpPatch("/api/me")]
    public async Task<IActionResult> PatchMe(ProfilePatchRequest request)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        var emptyField = new (string Name, string? Value)[]
        {
            (nameof(request.Name), request.Name),
            (nameof(request.Email), request.Email),
            (nameof(request.Phone), request.Phone),
            (nameof(request.Cnic), request.Cnic),
            (nameof(request.University), request.University),
            (nameof(request.StudentId), request.StudentId),
            (nameof(request.Program), request.Program),
            (nameof(request.Semester), request.Semester),
            (nameof(request.EmergencyContactName), request.EmergencyContactName),
            (nameof(request.EmergencyContactPhone), request.EmergencyContactPhone),
            (nameof(request.City), request.City),
            (nameof(request.LicenceNumber), request.LicenceNumber),
            (nameof(request.VehicleMake), request.VehicleMake),
            (nameof(request.VehicleModel), request.VehicleModel),
            (nameof(request.VehicleColour), request.VehicleColour),
            (nameof(request.PlateNumber), request.PlateNumber)
        }.FirstOrDefault(field => field.Value != null && string.IsNullOrWhiteSpace(field.Value));
        if (emptyField.Value != null)
            return FieldError(emptyField.Name, "Value cannot be empty.");

        var userId = GetUserId();
        var user = await _db.Users
            .Include(candidate => candidate.PassengerProfile)
            .Include(candidate => candidate.DriverProfile)
            .FirstOrDefaultAsync(candidate => candidate.Id == userId);

        if (user == null)
            return NotFound();

        var email = request.Email?.Trim().ToLowerInvariant();
        if (email != null && await _db.Users.AnyAsync(candidate => candidate.Id != userId && candidate.Email == email))
            return FieldError(nameof(request.Email), "Email is already registered.");

        if (request.Phone != null && await _db.Users.AnyAsync(candidate => candidate.Id != userId && candidate.Phone == request.Phone))
            return FieldError(nameof(request.Phone), "Phone number is already registered.");

        var cnic = request.Cnic;
        if (cnic != null && await _db.Users.AnyAsync(candidate => candidate.Id != userId && candidate.Cnic == cnic))
            return FieldError(nameof(request.Cnic), "CNIC is already registered.");

        var verificationDetailsChanged = false;
        if (request.Name != null)
            user.FullName = request.Name.Trim();
        if (email != null)
            user.Email = email;
        if (request.Phone != null)
            user.Phone = request.Phone;
        if (cnic != null && user.Cnic != cnic)
        {
            user.Cnic = cnic;
            verificationDetailsChanged = true;
            if (user.PassengerProfile != null)
                user.PassengerProfile.Cnic = cnic;
            if (user.DriverProfile != null)
                user.DriverProfile.Cnic = cnic;
        }

        if (user.PassengerProfile != null)
        {
            UpdateIfProvided(request.University, value => user.PassengerProfile.University = value);
            UpdateIfProvided(request.StudentId, value => user.PassengerProfile.StudentId = value);
            UpdateIfProvided(request.Program, value => user.PassengerProfile.ProgramAndSemester = value);
            UpdateIfProvided(request.Semester, value => user.PassengerProfile.Semester = value);
            UpdateIfProvided(request.EmergencyContactName, value => user.PassengerProfile.EmergencyContactName = value);
            UpdateIfProvided(request.EmergencyContactPhone, value => user.PassengerProfile.EmergencyContactPhone = value);
        }
        else if (user.DriverProfile != null)
        {
            var driver = user.DriverProfile;
            if (request.PlateNumber != null && await _db.DriverProfiles.AnyAsync(
                    profile => profile.UserId != userId && profile.PlateNumber == request.PlateNumber))
                return FieldError(nameof(request.PlateNumber), "Plate number is already registered.");
            if (request.LicenceNumber != null && driver.LicenseNumber != request.LicenceNumber)
                verificationDetailsChanged = true;
            if (request.VehicleMake != null && driver.VehicleMake != request.VehicleMake)
                verificationDetailsChanged = true;
            if (request.VehicleModel != null && !driver.VehicleMakeModel.EndsWith(request.VehicleModel, StringComparison.OrdinalIgnoreCase))
                verificationDetailsChanged = true;
            if (request.VehicleColour != null && driver.VehicleColor != request.VehicleColour)
                verificationDetailsChanged = true;
            if (request.PlateNumber != null && driver.PlateNumber != request.PlateNumber)
                verificationDetailsChanged = true;
            if (request.VehicleYear.HasValue && driver.VehicleModelYear != request.VehicleYear.Value)
                verificationDetailsChanged = true;
            if (request.SeatCapacity.HasValue && driver.SeatCapacity != request.SeatCapacity.Value)
                verificationDetailsChanged = true;

            UpdateIfProvided(request.City, value => driver.City = value);
            UpdateIfProvided(request.LicenceNumber, value => driver.LicenseNumber = value);
            UpdateIfProvided(request.VehicleMake, value => driver.VehicleMake = value);
            UpdateIfProvided(request.VehicleColour, value => driver.VehicleColor = value);
            UpdateIfProvided(request.PlateNumber, value =>
            {
                driver.PlateNumber = value;
                driver.VehicleRegistrationNumber = value;
            });
            if (request.VehicleModel != null)
                driver.VehicleMakeModel = $"{driver.VehicleMake} {request.VehicleModel}".Trim();
            if (request.VehicleYear.HasValue)
                driver.VehicleModelYear = request.VehicleYear.Value;
            if (request.SeatCapacity.HasValue)
            {
                driver.SeatCapacity = request.SeatCapacity.Value;
                driver.SeatsForPassengers = request.SeatCapacity.Value;
            }
        }

        if (verificationDetailsChanged)
            user.Status = UserStatus.Pending;

        await _db.SaveChangesAsync();
        return Ok(ToProfile(user));
    }

    private IQueryable<User> GetCurrentUserQuery()
    {
        var userId = GetUserId();
        return _db.Users
            .Include(user => user.PassengerProfile)
            .Include(user => user.DriverProfile)
            .Where(user => user.Id == userId);
    }

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    private static void UpdateIfProvided(string? value, Action<string> update)
    {
        if (value != null)
            update(value.Trim());
    }

    private static object ToProfile(User user) => new
    {
        id = user.Id,
        name = user.FullName,
        email = user.Email,
        phone = user.Phone,
        cnic = user.Cnic,
        role = user.Role.ToString(),
        verificationStatus = user.Status.ToString(),
        createdAt = user.CreatedAt,
        passengerProfile = user.PassengerProfile == null ? null : new
        {
            user.PassengerProfile.Cnic,
            user.PassengerProfile.University,
            user.PassengerProfile.StudentId,
            program = user.PassengerProfile.ProgramAndSemester,
            user.PassengerProfile.Semester,
            user.PassengerProfile.EmergencyContactName,
            user.PassengerProfile.EmergencyContactPhone
        },
        driverProfile = user.DriverProfile == null ? null : new
        {
            user.DriverProfile.Cnic,
            user.DriverProfile.City,
            licenceNumber = user.DriverProfile.LicenseNumber,
            user.DriverProfile.VehicleMake,
            vehicleModel = user.DriverProfile.VehicleMakeModel,
            vehicleColour = user.DriverProfile.VehicleColor,
            user.DriverProfile.PlateNumber,
            vehicleYear = user.DriverProfile.VehicleModelYear,
            seatCapacity = user.DriverProfile.SeatCapacity,
            user.DriverProfile.IsOnline
        }
    };
}

public sealed class ProfilePatchRequest
{
    [StringLength(100)]
    public string? Name { get; set; }

    [EmailAddress, StringLength(100)]
    public string? Email { get; set; }

    [RegularExpression(@"^03\d{9}$")]
    public string? Phone { get; set; }

    [RegularExpression(@"^\d{13}$")]
    public string? Cnic { get; set; }

    public string? University { get; set; }
    public string? StudentId { get; set; }
    public string? Program { get; set; }
    public string? Semester { get; set; }
    public string? EmergencyContactName { get; set; }

    [RegularExpression(@"^03\d{9}$")]
    public string? EmergencyContactPhone { get; set; }

    public string? City { get; set; }
    public string? LicenceNumber { get; set; }
    public string? VehicleMake { get; set; }
    public string? VehicleModel { get; set; }
    public string? VehicleColour { get; set; }
    public string? PlateNumber { get; set; }

    [Range(1990, 2100)]
    public int? VehicleYear { get; set; }

    [Range(1, 4)]
    public int? SeatCapacity { get; set; }
}

