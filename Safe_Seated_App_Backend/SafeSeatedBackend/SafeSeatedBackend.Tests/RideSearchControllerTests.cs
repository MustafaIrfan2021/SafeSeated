using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using SafeSeatedBackend.Controllers;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Tests;

public sealed class RideSearchControllerTests
{
    [Fact]
    public async Task SearchRidesWorksWithoutFiltersAndPreservesFilteredSeatAvailability()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, rideDate, rideWithBooking) = await database.SeedRidesAsync();
        var controller = new RidesController(database.Context);

        var allRidesResult = Assert.IsType<OkObjectResult>(await controller.SearchRides());
        var allPagination = GetProperty(allRidesResult.Value!, "pagination");
        Assert.Equal(2, GetProperty<int>(allPagination, "totalCount"));

        var filteredResult = Assert.IsType<OkObjectResult>(await controller.SearchRides(
            pickup: "Campus",
            destination: "Downtown",
            date: rideDate,
            seats: 2,
            page: 1,
            pageSize: 1));
        var pagination = GetProperty(filteredResult.Value!, "pagination");
        Assert.Equal(1, GetProperty<int>(pagination, "totalCount"));

        var data = Assert.IsAssignableFrom<IEnumerable<object>>(
            GetProperty(filteredResult.Value!, "data"));
        var rideResponse = Assert.Single(data);
        Assert.Equal(rideWithBooking.Id, GetProperty<Guid>(rideResponse, "Id"));
        Assert.Equal(2, GetProperty<int>(rideResponse, "seatsAvailable"));
        Assert.Equal(driver.Id, rideWithBooking.DriverId);
    }

    private static object GetProperty(object instance, string name) =>
        instance.GetType().GetProperty(name)!.GetValue(instance)!;

    private static T GetProperty<T>(object instance, string name) =>
        (T)GetProperty(instance, name);

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

        public async Task<(User Driver, DateTime RideDate, Ride RideWithBooking)> SeedRidesAsync()
        {
            var driver = new User
            {
                Role = UserRole.Driver,
                FullName = "Test Driver",
                Phone = "03000000001",
                Email = "driver@example.com",
                PasswordHash = "test-hash",
                Cnic = "1111111111111",
                Status = UserStatus.Verified,
                DriverProfile = new DriverProfile
                {
                    City = "Karachi",
                    Cnic = "1111111111111",
                    LicenseNumber = "DL-123",
                    VehicleMake = "Toyota",
                    VehicleMakeModel = "Toyota Corolla",
                    VehicleColor = "White",
                    PlateNumber = "ABC-123",
                    VehicleModelYear = 2022,
                    SeatsForPassengers = 3,
                    SeatCapacity = 3,
                    VehicleRegistrationNumber = "REG-123",
                    IsOnline = true
                }
            };
            var passenger = new User
            {
                Role = UserRole.Passenger,
                FullName = "Test Passenger",
                Phone = "03000000002",
                Email = "passenger@example.com",
                PasswordHash = "test-hash",
                Cnic = "2222222222222",
                Status = UserStatus.Verified
            };
            var departure = DateTime.UtcNow.Date.AddDays(1).AddHours(9);
            var rideWithBooking = new Ride
            {
                DriverId = driver.Id,
                Driver = driver,
                PickupArea = "Campus",
                Destination = "Downtown",
                DepartureTime = departure,
                PricePerSeat = 200,
                SeatsOffered = 3,
                Status = RideStatus.Active
            };
            var otherRide = new Ride
            {
                DriverId = driver.Id,
                Driver = driver,
                PickupArea = "Station",
                Destination = "Downtown",
                DepartureTime = departure.AddHours(1),
                PricePerSeat = 100,
                SeatsOffered = 2,
                Status = RideStatus.Active
            };
            Context.Users.AddRange(driver, passenger);
            Context.Rides.AddRange(rideWithBooking, otherRide);
            Context.Bookings.Add(new Booking
            {
                RideId = rideWithBooking.Id,
                Ride = rideWithBooking,
                PassengerId = passenger.Id,
                Passenger = passenger,
                SeatsRequested = 1,
                FareTotal = rideWithBooking.PricePerSeat,
                PickupTime = departure,
                TravelDate = departure.Date,
                Status = BookingStatus.Accepted
            });
            await Context.SaveChangesAsync();
            return (driver, departure.Date, rideWithBooking);
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }
}
