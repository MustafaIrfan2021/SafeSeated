using SafeSeatedBackend.Controllers;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Tests;

public class AuthValidationTests
{
    [Fact]
    public void PassengerRegistrationAcceptsPakistaniPhoneAndThirteenDigitCnic()
    {
        var request = new RegisterPassengerRequest
        {
            Name = "Ayesha Khan",
            Email = "ayesha@example.com",
            Phone = "03001234567",
            Cnic = "1234512345671",
            Password = "StrongPass123",
            University = "Example University",
            StudentId = "STU-1",
            Program = "Computer Science",
            Semester = "4",
            EmergencyContactName = "Fatima Khan",
            EmergencyContactPhone = "03331234567"
        };

        Assert.True(IsValid(request));
    }

    [Theory]
    [InlineData("12345-1234567-1", "03001234567")]
    [InlineData("1234512345671", "0300123")]
    public void PassengerRegistrationRejectsInvalidCnicOrPhone(string cnic, string phone)
    {
        var request = new RegisterPassengerRequest
        {
            Name = "Ayesha Khan",
            Email = "ayesha@example.com",
            Phone = phone,
            Cnic = cnic,
            Password = "StrongPass123",
            University = "Example University",
            StudentId = "STU-1",
            Program = "Computer Science",
            Semester = "4",
            EmergencyContactName = "Fatima Khan",
            EmergencyContactPhone = "03331234567"
        };

        Assert.False(IsValid(request));
    }

    [Fact]
    public void DriverRegistrationRejectsSeatCapacityAboveFour()
    {
        var request = new RegisterDriverRequest { SeatCapacity = 5, VehicleYear = DateTime.UtcNow.Year };

        Assert.Contains(Validate(request), error => error.MemberNames.Contains(nameof(request.SeatCapacity)));
    }

    private static bool IsValid(object value) => Validate(value).Count == 0;

    private static List<ValidationResult> Validate(object value)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(value, new ValidationContext(value), results, validateAllProperties: true);
        return results;
    }
}
