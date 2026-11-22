using System.Security.Claims;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Controllers;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Tests;

public sealed class EmergencyAlertsTests
{
    [Fact]
    public async Task CreateStoresAuthenticatedIdentityLocationAndAssociatedRide()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, passenger, ride, _) = await database.SeedAsync();
        var controller = database.CreateController(passenger.Id);

        var result = await controller.Create(
            new CreateEmergencyAlertRequest
            {
                ClientRequestId = Guid.NewGuid(),
                Latitude = 24.8607,
                Longitude = 67.0011,
                RideId = ride.Id
            },
            CancellationToken.None);

        Assert.IsType<CreatedResult>(result);
        var alert = await database.Context.EmergencyAlerts.SingleAsync();
        Assert.Equal(passenger.Id, alert.UserId);
        Assert.Equal(UserRole.Passenger, alert.ReporterRole);
        Assert.Equal(ride.Id, alert.RideId);
        Assert.Equal(24.8607, alert.Latitude);
        Assert.Equal(67.0011, alert.Longitude);
        Assert.Equal("Open", alert.Status);
        Assert.InRange(alert.CreatedAt, DateTime.UtcNow.AddMinutes(-1), DateTime.UtcNow.AddMinutes(1));
        Assert.NotEqual(driver.Id, alert.UserId);
    }

    [Fact]
    public async Task DuplicateRequestIdReturnsExistingAlertWithoutCreatingAnother()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _, _) = await database.SeedAsync();
        var requestId = Guid.NewGuid();
        var controller = database.CreateController(passenger.Id);
        var request = new CreateEmergencyAlertRequest
        {
            ClientRequestId = requestId,
            Latitude = 24.86,
            Longitude = 67.0
        };

        var first = await controller.Create(request, CancellationToken.None);
        database.Context.ChangeTracker.Clear();
        var second = await controller.Create(request, CancellationToken.None);

        Assert.IsType<CreatedResult>(first);
        Assert.IsType<OkObjectResult>(second);
        Assert.Single(await database.Context.EmergencyAlerts.ToListAsync());
    }

    [Fact]
    public async Task RideMustBelongToCallerAndAlertHistoryIsUserScoped()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, ride, otherPassenger) = await database.SeedAsync();
        var create = await database.CreateController(passenger.Id).Create(
            new CreateEmergencyAlertRequest { ClientRequestId = Guid.NewGuid() },
            CancellationToken.None);
        Assert.IsType<CreatedResult>(create);

        var unrelatedRideResult = await database.CreateController(otherPassenger.Id).Create(
            new CreateEmergencyAlertRequest
            {
                ClientRequestId = Guid.NewGuid(),
                RideId = ride.Id
            },
            CancellationToken.None);
        Assert.IsType<BadRequestObjectResult>(unrelatedRideResult);

        var ownAlerts = Assert.IsType<OkObjectResult>(
            await database.CreateController(otherPassenger.Id).GetMine(CancellationToken.None));
        Assert.Empty(Assert.IsAssignableFrom<IEnumerable<EmergencyAlertResponse>>(ownAlerts.Value));
    }

    [Fact]
    public async Task AdminListIsRoleRestrictedAndIncludesUserAndRideDetails()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, ride, _) = await database.SeedAsync();
        var admin = database.SeedAdmin();
        await database.Context.SaveChangesAsync();
        await database.CreateController(passenger.Id).Create(
            new CreateEmergencyAlertRequest
            {
                ClientRequestId = Guid.NewGuid(),
                RideId = ride.Id
            },
            CancellationToken.None);

        var adminResult = Assert.IsType<OkObjectResult>(
            await database.CreateController(admin.Id, UserRole.Admin)
                .GetForAdmin(CancellationToken.None));
        var item = Assert.Single(
            Assert.IsAssignableFrom<IEnumerable<AdminEmergencyAlertResponse>>(adminResult.Value));

        Assert.Equal(passenger.FullName, item.User.Name);
        Assert.Equal("Ayesha's contact", item.User.EmergencyContactName);
        Assert.Equal("03001234567", item.User.EmergencyContactPhone);
        Assert.Equal(ride.PickupArea, item.Ride?.Pickup);
        Assert.Equal(ride.Destination, item.Ride?.Destination);
        Assert.Equal("Admin", typeof(EmergencyAlertsController)
            .GetMethod(nameof(EmergencyAlertsController.GetForAdmin))!
            .GetCustomAttributes(typeof(AuthorizeAttribute), true)
            .Cast<AuthorizeAttribute>()
            .Single()
            .Roles);
    }

    [Fact]
    public async Task CoordinatesMustBeProvidedTogether()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _, _) = await database.SeedAsync();

        var result = await database.CreateController(passenger.Id).Create(
            new CreateEmergencyAlertRequest
            {
                ClientRequestId = Guid.NewGuid(),
                Latitude = 24.86
            },
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await database.Context.EmergencyAlerts.ToListAsync());
    }

    [Fact]
    public async Task DriverCanRaiseAlertForOwnedRideAndConfigureEmergencyContact()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, _, ride, _) = await database.SeedAsync();
        var alertResult = await database.CreateController(driver.Id, UserRole.Driver).Create(
            new CreateEmergencyAlertRequest
            {
                ClientRequestId = Guid.NewGuid(),
                RideId = ride.Id
            },
            CancellationToken.None);
        var profile = new ProfileController(database.Context);
        database.SetCurrentUser(profile, driver.Id, UserRole.Driver);

        var profileResult = await profile.PatchMe(new ProfilePatchRequest
        {
            EmergencyContactName = "Driver ICE contact",
            EmergencyContactPhone = "03001112222"
        });

        Assert.IsType<CreatedResult>(alertResult);
        Assert.IsType<OkObjectResult>(profileResult);
        Assert.Equal(UserRole.Driver, (await database.Context.EmergencyAlerts.SingleAsync()).ReporterRole);
        var savedProfile = await database.Context.DriverProfiles.SingleAsync();
        Assert.Equal("Driver ICE contact", savedProfile.EmergencyContactName);
        Assert.Equal("03001112222", savedProfile.EmergencyContactPhone);
    }

    [Fact]
    public void CoordinatesAreRangeValidated()
    {
        var request = new CreateEmergencyAlertRequest
        {
            ClientRequestId = Guid.NewGuid(),
            Latitude = 91,
            Longitude = -181
        };
        var errors = new List<ValidationResult>();

        var valid = Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            errors,
            validateAllProperties: true);

        Assert.False(valid);
        Assert.Equal(2, errors.Count);
    }

    private sealed class TestDatabase : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;

        private TestDatabase(SqliteConnection connection, SafeSeatedDbContext context)
        {
            _connection = connection;
            Context = context;
        }

        public SafeSeatedDbContext Context { get; }

        public static async Task<TestDatabase> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var options = new DbContextOptionsBuilder<SafeSeatedDbContext>()
                .UseSqlite(connection)
                .Options;
            var context = new SafeSeatedDbContext(options);
            await context.Database.EnsureCreatedAsync();
            return new TestDatabase(connection, context);
        }

        public async Task<(User Driver, User Passenger, Ride Ride, User OtherPassenger)> SeedAsync()
        {
            var driver = CreateUser(UserRole.Driver, "driver");
            driver.DriverProfile = new DriverProfile
            {
                UserId = driver.Id,
                Cnic = driver.Cnic,
                City = "Karachi",
                LicenseNumber = "DL-123",
                VehicleMakeModel = "Toyota Corolla",
                VehicleMake = "Toyota",
                VehicleColor = "White",
                PlateNumber = "ABC-123",
                VehicleModelYear = 2022,
                SeatsForPassengers = 3,
                SeatCapacity = 3,
                VehicleRegistrationNumber = "REG-123",
                IsOnline = true,
                EmergencyContactName = "Driver contact",
                EmergencyContactPhone = "03007654321"
            };
            var passenger = CreateUser(UserRole.Passenger, "passenger");
            passenger.PassengerProfile = CreatePassengerProfile(passenger);
            var otherPassenger = CreateUser(UserRole.Passenger, "other");
            otherPassenger.PassengerProfile = CreatePassengerProfile(otherPassenger);
            var ride = new Ride
            {
                DriverId = driver.Id,
                Driver = driver,
                PickupArea = "Campus",
                Destination = "City Center",
                DepartureTime = DateTime.UtcNow.AddDays(1),
                PricePerSeat = 300,
                SeatsOffered = 3,
                Status = RideStatus.Active
            };
            var booking = new Booking
            {
                RideId = ride.Id,
                Ride = ride,
                PassengerId = passenger.Id,
                Passenger = passenger,
                SeatsRequested = 1,
                FareTotal = 300,
                PickupTime = ride.DepartureTime,
                TravelDate = ride.DepartureTime.Date,
                Status = BookingStatus.Accepted
            };

            Context.Users.AddRange(driver, passenger, otherPassenger);
            Context.Rides.Add(ride);
            Context.Bookings.Add(booking);
            await Context.SaveChangesAsync();
            return (driver, passenger, ride, otherPassenger);
        }

        public User SeedAdmin()
        {
            var admin = CreateUser(UserRole.Admin, "admin");
            Context.Users.Add(admin);
            return admin;
        }

        public EmergencyAlertsController CreateController(Guid userId, UserRole role = UserRole.Passenger)
        {
            var controller = new EmergencyAlertsController(Context);
            SetCurrentUser(controller, userId, role);
            return controller;
        }

        public void SetCurrentUser(ControllerBase controller, Guid userId, UserRole role) =>
            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                        [
                            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                            new Claim(ClaimTypes.Role, role.ToString())
                        ],
                        authenticationType: "test"))
                }
            };

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }

        private static PassengerProfile CreatePassengerProfile(User user) => new()
        {
            UserId = user.Id,
            Cnic = user.Cnic,
            University = "University",
            StudentId = "STU-1",
            ProgramAndSemester = "Computer Science",
            Semester = "4",
            EmergencyContactName = "Ayesha's contact",
            EmergencyContactPhone = "03001234567"
        };

        private static User CreateUser(UserRole role, string name) => new()
        {
            Role = role,
            FullName = name,
            Phone = name switch
            {
                "driver" => "03000000001",
                "passenger" => "03000000002",
                "other" => "03000000003",
                _ => "03000000004"
            },
            Email = $"{name}@example.com",
            PasswordHash = "test-hash",
            Cnic = role == UserRole.Driver ? "1111111111111" : name == "passenger" ? "2222222222222" : name == "other" ? "3333333333333" : "4444444444444",
            Status = UserStatus.Verified
        };
    }
}
