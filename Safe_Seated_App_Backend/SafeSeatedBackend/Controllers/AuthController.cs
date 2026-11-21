using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SafeSeatedBackend.Models;
using SafeSeatedBackend.Data;
using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;
    private readonly IConfiguration _configuration;

    public AuthController(SafeSeatedDbContext db, IConfiguration configuration)
    {
        _db = db;
        _configuration = configuration;
    }

    [HttpPost("register/passenger")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterPassenger(RegisterPassengerRequest request)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);
        if (Encoding.UTF8.GetByteCount(request.Password) > 72)
            return PasswordLengthError();

        var duplicate = await FindDuplicateUserAsync(request.Email, request.Phone, request.Cnic);
        if (duplicate != null)
            return BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]>
            {
                [duplicate] = ["A user with this value is already registered."]
            }) { Status = StatusCodes.Status400BadRequest });

        var user = new User
        {
            FullName = request.Name.Trim(),
            Email = NormalizeEmail(request.Email),
            Phone = request.Phone,
            Cnic = request.Cnic,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRole.Passenger,
            Status = UserStatus.Pending,
            PassengerProfile = new PassengerProfile
            {
                Cnic = request.Cnic,
                University = request.University.Trim(),
                StudentId = request.StudentId.Trim(),
                ProgramAndSemester = request.Program.Trim(),
                Semester = request.Semester.Trim(),
                EmergencyContactName = request.EmergencyContactName.Trim(),
                EmergencyContactPhone = request.EmergencyContactPhone
            }
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return Created("/api/me", new { userId = user.Id, message = "Registration successful." });
    }

    [HttpPost("register/driver")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterDriver(RegisterDriverRequest request)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);
        if (Encoding.UTF8.GetByteCount(request.Password) > 72)
            return PasswordLengthError();

        if (request.VehicleYear > DateTime.UtcNow.Year + 1)
            return BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]>
            {
                [nameof(request.VehicleYear)] = ["Vehicle year cannot be more than next year."]
            }) { Status = StatusCodes.Status400BadRequest });

        if (await _db.DriverProfiles.AnyAsync(profile => profile.PlateNumber == request.PlateNumber.Trim()))
            return BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]>
            {
                [nameof(request.PlateNumber)] = ["Plate number is already registered."]
            }) { Status = StatusCodes.Status400BadRequest });

        var duplicate = await FindDuplicateUserAsync(request.Email, request.Phone, request.Cnic);
        if (duplicate != null)
            return BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]>
            {
                [duplicate] = ["A user with this value is already registered."]
            }) { Status = StatusCodes.Status400BadRequest });

        var user = new User
        {
            FullName = request.Name.Trim(),
            Email = NormalizeEmail(request.Email),
            Phone = request.Phone,
            Cnic = request.Cnic,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRole.Driver,
            Status = UserStatus.Pending,
            DriverProfile = new DriverProfile
            {
                Cnic = request.Cnic,
                City = request.City.Trim(),
                LicenseNumber = request.LicenceNumber.Trim(),
                VehicleMake = request.VehicleMake.Trim(),
                VehicleMakeModel = $"{request.VehicleMake.Trim()} {request.VehicleModel.Trim()}",
                VehicleColor = request.VehicleColour.Trim(),
                PlateNumber = request.PlateNumber.Trim(),
                VehicleModelYear = request.VehicleYear,
                SeatsForPassengers = request.SeatCapacity,
                SeatCapacity = request.SeatCapacity,
                VehicleRegistrationNumber = request.PlateNumber.Trim()
            }
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return Created("/api/me", new { userId = user.Id, message = "Registration successful." });
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        var email = NormalizeEmail(request.Email);
        var user = await _db.Users.FirstOrDefaultAsync(candidate => candidate.Email == email);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized(new ProblemDetails
            {
                Status = StatusCodes.Status401Unauthorized,
                Title = "Invalid email or password."
            });

        user.LastLoginAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        var key = _configuration["Jwt:SecretKey"]
            ?? throw new InvalidOperationException("JWT SecretKey is not configured.");
        if (Encoding.UTF8.GetByteCount(key) < 32)
            throw new InvalidOperationException("JWT SecretKey must be at least 32 bytes.");
        var issuer = _configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException("JWT Issuer is not configured.");
        var audience = _configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException("JWT Audience is not configured.");
        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role.ToString())
        };
        var expires = DateTime.UtcNow.AddMinutes(
            _configuration.GetValue<int?>("Jwt:AccessTokenExpiryMinutes") ?? 60);
        var token = new JwtSecurityToken(issuer, audience, claims, expires: expires, signingCredentials: credentials);

        return Ok(new
        {
            accessToken = new JwtSecurityTokenHandler().WriteToken(token),
            user = new
            {
                id = user.Id,
                name = user.FullName,
                email = user.Email,
                phone = user.Phone,
                role = user.Role.ToString(),
                verificationStatus = GetVerificationStatus(user.Status)
            }
        });
    }

    private async Task<string?> FindDuplicateUserAsync(string email, string phone, string cnic)
    {
        var normalizedEmail = NormalizeEmail(email);
        if (await _db.Users.AnyAsync(user => user.Email.ToLower() == normalizedEmail))
            return nameof(RegisterPassengerRequest.Email);
        if (await _db.Users.AnyAsync(user => user.Phone == phone))
            return nameof(RegisterPassengerRequest.Phone);
        if (await _db.Users.AnyAsync(user => user.Cnic == cnic))
            return nameof(RegisterPassengerRequest.Cnic);
        return null;
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    private IActionResult PasswordLengthError() =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]>
        {
            [nameof(RegisterPassengerRequest.Password)] = ["Password must be at most 72 UTF-8 bytes."]
        }) { Status = StatusCodes.Status400BadRequest });

    private static string GetVerificationStatus(UserStatus status) =>
        status.ToString();
}

public sealed class RegisterPassengerRequest
{
    [Required, StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required, RegularExpression(@"^03\d{9}$", ErrorMessage = "Enter a Pakistani mobile number such as 03001234567.")]
    public string Phone { get; set; } = string.Empty;

    [Required, RegularExpression(@"^\d{13}$", ErrorMessage = "CNIC must contain exactly 13 digits.")]
    public string Cnic { get; set; } = string.Empty;

    [Required, StringLength(72, MinimumLength = 8)]
    public string Password { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string University { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string StudentId { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string Program { get; set; } = string.Empty;

    [Required, StringLength(30)]
    public string Semester { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string EmergencyContactName { get; set; } = string.Empty;

    [Required, RegularExpression(@"^03\d{9}$")]
    public string EmergencyContactPhone { get; set; } = string.Empty;
}

public sealed class RegisterDriverRequest
{
    [Required, StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required, RegularExpression(@"^03\d{9}$")]
    public string Phone { get; set; } = string.Empty;

    [Required, RegularExpression(@"^\d{13}$", ErrorMessage = "CNIC must contain exactly 13 digits.")]
    public string Cnic { get; set; } = string.Empty;

    [Required, StringLength(72, MinimumLength = 8)]
    public string Password { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string City { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string LicenceNumber { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string VehicleMake { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string VehicleModel { get; set; } = string.Empty;

    [Required, StringLength(30)]
    public string VehicleColour { get; set; } = string.Empty;

    [Required, StringLength(15)]
    public string PlateNumber { get; set; } = string.Empty;

    [Range(1990, 2100)]
    public int VehicleYear { get; set; }

    [Range(1, 4)]
    public int SeatCapacity { get; set; }
}

public sealed class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}
