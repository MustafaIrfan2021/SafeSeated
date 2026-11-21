using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Controllers;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Tests;

public sealed class RideRequestAndComplaintTests
{
    [Fact]
    public async Task RideRequestCanOnlyBeFulfilledOnce()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, _, rideRequest) = await database.SeedRideRequestAsync();
        var controller = database.CreateRideRequestsController(driver.Id);
        var offer = new AcceptRideRequest { TotalSeats = 3, FarePerSeat = 300 };

        var firstResult = await controller.AcceptRideRequest(rideRequest.Id, offer, CancellationToken.None);
        database.Context.ChangeTracker.Clear();
        var secondResult = await controller.AcceptRideRequest(rideRequest.Id, offer, CancellationToken.None);

        Assert.IsType<CreatedAtActionResult>(firstResult);
        Assert.IsType<ConflictObjectResult>(secondResult);
        Assert.Equal(1, await database.Context.Rides.CountAsync());
        Assert.Equal(1, await database.Context.Bookings.CountAsync());
        var fulfilledRequest = await database.Context.RideRequests.SingleAsync();
        Assert.Equal(RideRequestStatus.Accepted, fulfilledRequest.Status);
        Assert.Equal(driver.Id, fulfilledRequest.AcceptedByDriverId);
    }

    [Theory]
    [InlineData(2, 0)]
    [InlineData(2, 1_000_001)]
    [InlineData(4, 300)]
    [InlineData(1, 300)]
    public async Task RideRequestOfferRejectsInvalidSeatsOrFare(int seats, double fare)
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, _, rideRequest) = await database.SeedRideRequestAsync();
        var controller = database.CreateRideRequestsController(driver.Id);

        var result = await controller.AcceptRideRequest(
            rideRequest.Id,
            new AcceptRideRequest { TotalSeats = seats, FarePerSeat = (decimal)fare },
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(await database.Context.Rides.ToListAsync());
        Assert.Empty(await database.Context.Bookings.ToListAsync());
    }

    [Fact]
    public async Task ComplaintUsesAuthenticatedReporterAndOpenStatus()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _) = await database.SeedRideRequestAsync();
        var controller = database.CreateComplaintsController(passenger.Id);

        var result = await controller.CreateComplaint(
            new CreateComplaintRequest { Description = "  Unsafe pickup location.  " },
            CancellationToken.None);

        var created = Assert.IsType<CreatedResult>(result);
        Assert.NotNull(created.Value);
        var complaint = await database.Context.Complaints.SingleAsync();
        Assert.Equal(passenger.Id, complaint.PassengerId);
        Assert.Equal("Unsafe pickup location.", complaint.Description);
        Assert.Equal(ComplaintStatus.Open, complaint.Status);

        var listResult = Assert.IsType<OkObjectResult>(
            await controller.GetMyComplaints(CancellationToken.None));
        Assert.Single(Assert.IsAssignableFrom<IEnumerable<object>>(listResult.Value));
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

        public async Task<(User Driver, User Passenger, RideRequest Request)> SeedRideRequestAsync()
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
                IsOnline = true
            };
            var passenger = CreateUser(UserRole.Passenger, "passenger");
            var rideRequest = new RideRequest
            {
                PassengerId = passenger.Id,
                Passenger = passenger,
                PickupArea = "Campus",
                Destination = "City Center",
                PickupTime = DateTime.UtcNow.AddDays(1),
                SeatsNeeded = 2,
                Status = RideRequestStatus.Open
            };
            Context.Users.AddRange(driver, passenger);
            Context.RideRequests.Add(rideRequest);
            await Context.SaveChangesAsync();
            return (driver, passenger, rideRequest);
        }

        public RideRequestsController CreateRideRequestsController(Guid userId)
        {
            var controller = new RideRequestsController(Context);
            SetUser(controller, userId);
            return controller;
        }

        public ComplaintsController CreateComplaintsController(Guid userId)
        {
            var controller = new ComplaintsController(Context);
            SetUser(controller, userId);
            return controller;
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }

        private static void SetUser(ControllerBase controller, Guid userId)
        {
            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                        [new Claim(ClaimTypes.NameIdentifier, userId.ToString())],
                        authenticationType: "test"))
                }
            };
        }

        private static User CreateUser(UserRole role, string name) => new()
        {
            Role = role,
            FullName = name,
            Phone = role == UserRole.Driver ? "03000000001" : "03000000002",
            Email = $"{name}@example.com",
            PasswordHash = "test-hash",
            Cnic = role == UserRole.Driver ? "1111111111111" : "2222222222222",
            Status = UserStatus.Verified
        };
    }
}
