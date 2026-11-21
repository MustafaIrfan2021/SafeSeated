using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Controllers;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Tests;

public sealed class BookingControllerTests
{
    [Fact]
    public async Task CreateBookingRejectsRequestWhenAcceptedBookingsFillRide()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, firstPassenger, secondPassenger, ride) = await database.SeedRideAsync(seats: 2);
        database.Context.Bookings.Add(new Booking
        {
            RideId = ride.Id,
            PassengerId = firstPassenger.Id,
            SeatsRequested = 2,
            FareTotal = ride.PricePerSeat * 2,
            PickupTime = ride.DepartureTime,
            TravelDate = ride.DepartureTime.Date,
            Status = BookingStatus.Accepted
        });
        await database.Context.SaveChangesAsync();

        var controller = database.CreateController(secondPassenger.Id);
        var result = await controller.CreateBooking(
            new CreateBookingRequest { RideId = ride.Id, Seats = 1 },
            CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Single(await database.Context.Bookings.ToListAsync());
    }

    [Fact]
    public async Task CreateBookingCalculatesFareFromRidePrice()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _, ride) = await database.SeedRideAsync(seats: 2);

        var result = await database.CreateController(passenger.Id).CreateBooking(
            new CreateBookingRequest { RideId = ride.Id, Seats = 2 },
            CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        Assert.NotNull(created.Value);
        Assert.Equal(500m, (decimal)created.Value.GetType().GetProperty("fareTotal")!.GetValue(created.Value)!);
        Assert.Equal(500m, (await database.Context.Bookings.SingleAsync()).FareTotal);
    }

    [Fact]
    public async Task CreateBookingRejectsDuplicatePendingBooking()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _, ride) = await database.SeedRideAsync(seats: 2);
        var controller = database.CreateController(passenger.Id);
        var request = new CreateBookingRequest { RideId = ride.Id, Seats = 1 };
        var firstResult = await controller.CreateBooking(request, CancellationToken.None);

        var secondResult = await controller.CreateBooking(request, CancellationToken.None);

        Assert.IsType<CreatedAtActionResult>(firstResult);
        Assert.IsType<ConflictObjectResult>(secondResult);
        Assert.Single(await database.Context.Bookings.ToListAsync());
    }

    [Fact]
    public async Task DriverCannotAcceptBookingsThatExceedRideCapacity()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, firstPassenger, secondPassenger, ride) = await database.SeedRideAsync(seats: 2);
        var bookings = new[]
        {
            CreateBooking(ride, firstPassenger, seats: 2),
            CreateBooking(ride, secondPassenger, seats: 2)
        };
        database.Context.Bookings.AddRange(bookings);
        await database.Context.SaveChangesAsync();
        var controller = database.CreateController(driver.Id);

        var firstResult = await controller.UpdateBookingStatus(
            bookings[0].Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Accepted) },
            CancellationToken.None);
        var secondResult = await controller.UpdateBookingStatus(
            bookings[1].Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Accepted) },
            CancellationToken.None);

        Assert.IsType<OkObjectResult>(firstResult);
        Assert.IsType<ConflictObjectResult>(secondResult);
        Assert.Equal(BookingStatus.Accepted, bookings[0].Status);
        Assert.Equal(BookingStatus.Pending, bookings[1].Status);
    }

    [Fact]
    public async Task DriverCannotCompleteBookingBeforeTripIsActive()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, passenger, _, ride) = await database.SeedRideAsync(seats: 2);
        var booking = new Booking
        {
            RideId = ride.Id,
            PassengerId = passenger.Id,
            SeatsRequested = 1,
            FareTotal = ride.PricePerSeat,
            PickupTime = ride.DepartureTime,
            TravelDate = ride.DepartureTime.Date,
            Status = BookingStatus.Accepted
        };
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var controller = database.CreateController(driver.Id);
        var result = await controller.UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Completed) },
            CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Equal(BookingStatus.Accepted,
            (await database.Context.Bookings.SingleAsync()).Status);
    }

    [Fact]
    public async Task DriverCanActivateAndCompleteBookingAfterDepartureAndPassengerCanReviewIt()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, passenger, _, ride) = await database.SeedRideAsync(seats: 2);
        ride.DepartureTime = DateTime.UtcNow.AddMinutes(-1);
        var booking = CreateBooking(ride, passenger, seats: 1);
        booking.Status = BookingStatus.Accepted;
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var passengerController = database.CreateController(passenger.Id);
        var prematureReview = await passengerController.ReviewBooking(
            booking.Id,
            new ReviewBookingRequest { Rating = 5, Review = "Good ride" },
            CancellationToken.None);
        Assert.IsType<ConflictObjectResult>(prematureReview);

        var driverController = database.CreateController(driver.Id);
        var activeResult = await driverController.UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Active) },
            CancellationToken.None);
        var completedResult = await driverController.UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Completed) },
            CancellationToken.None);

        Assert.IsType<OkObjectResult>(activeResult);
        Assert.IsType<OkObjectResult>(completedResult);
        Assert.Equal(BookingStatus.Completed,
            (await database.Context.Bookings.SingleAsync()).Status);

        var reviewResult = await passengerController.ReviewBooking(
            booking.Id,
            new ReviewBookingRequest { Rating = 5, Review = "Good ride" },
            CancellationToken.None);
        Assert.IsType<OkObjectResult>(reviewResult);
        var reviewedBooking = await database.Context.Bookings.SingleAsync();
        Assert.Equal(5, reviewedBooking.Rating);
        Assert.Equal("Good ride", reviewedBooking.Review);
    }

    [Fact]
    public async Task AnotherUserCannotCompleteBooking()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, otherUser, ride) = await database.SeedRideAsync(seats: 2);
        ride.DepartureTime = DateTime.UtcNow.AddMinutes(-1);
        var booking = CreateBooking(ride, passenger, seats: 1);
        booking.Status = BookingStatus.Active;
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var result = await database.CreateController(otherUser.Id).UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Completed) },
            CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
        Assert.Equal(BookingStatus.Active,
            (await database.Context.Bookings.SingleAsync()).Status);
    }

    [Fact]
    public async Task DriverCannotStartBookingBeforeScheduledDeparture()
    {
        await using var database = await TestDatabase.CreateAsync();
        var (driver, passenger, _, ride) = await database.SeedRideAsync(seats: 2);
        var booking = CreateBooking(ride, passenger, seats: 1);
        booking.Status = BookingStatus.Accepted;
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var result = await database.CreateController(driver.Id).UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = nameof(BookingStatus.Active) },
            CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Equal(BookingStatus.Accepted,
            (await database.Context.Bookings.SingleAsync()).Status);
    }

    [Theory]
    [InlineData(BookingStatus.Accepted)]
    [InlineData(BookingStatus.Rejected)]
    public async Task PassengerCannotAcceptOrRejectTheirBooking(BookingStatus requestedStatus)
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, _, ride) = await database.SeedRideAsync(seats: 2);
        var booking = new Booking
        {
            RideId = ride.Id,
            PassengerId = passenger.Id,
            SeatsRequested = 1,
            FareTotal = ride.PricePerSeat,
            PickupTime = ride.DepartureTime,
            TravelDate = ride.DepartureTime.Date,
            Status = BookingStatus.Pending
        };
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var controller = database.CreateController(passenger.Id);
        var result = await controller.UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = requestedStatus.ToString() },
            CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Equal(BookingStatus.Pending,
            (await database.Context.Bookings.SingleAsync()).Status);
    }

    [Theory]
    [InlineData(BookingStatus.Accepted)]
    [InlineData(BookingStatus.Rejected)]
    public async Task AnotherUserCannotAcceptOrRejectBooking(BookingStatus requestedStatus)
    {
        await using var database = await TestDatabase.CreateAsync();
        var (_, passenger, otherUser, ride) = await database.SeedRideAsync(seats: 2);
        var booking = new Booking
        {
            RideId = ride.Id,
            PassengerId = passenger.Id,
            SeatsRequested = 1,
            FareTotal = ride.PricePerSeat,
            PickupTime = ride.DepartureTime,
            TravelDate = ride.DepartureTime.Date,
            Status = BookingStatus.Pending
        };
        database.Context.Bookings.Add(booking);
        await database.Context.SaveChangesAsync();

        var result = await database.CreateController(otherUser.Id).UpdateBookingStatus(
            booking.Id,
            new UpdateBookingStatusRequest { Status = requestedStatus.ToString() },
            CancellationToken.None);

        Assert.IsType<ForbidResult>(result);
        Assert.Equal(BookingStatus.Pending,
            (await database.Context.Bookings.SingleAsync()).Status);
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

        public async Task<(User Driver, User FirstPassenger, User SecondPassenger, Ride Ride)> SeedRideAsync(
            int seats)
        {
            var driver = CreateUser(UserRole.Driver, "driver");
            var firstPassenger = CreateUser(UserRole.Passenger, "first");
            var secondPassenger = CreateUser(UserRole.Passenger, "second");
            var ride = new Ride
            {
                DriverId = driver.Id,
                Driver = driver,
                PickupArea = "Campus",
                Destination = "City Center",
                DepartureTime = DateTime.UtcNow.AddDays(1),
                PricePerSeat = 250,
                SeatsOffered = seats,
                Status = RideStatus.Active
            };
            Context.Users.AddRange(driver, firstPassenger, secondPassenger);
            Context.Rides.Add(ride);
            await Context.SaveChangesAsync();
            return (driver, firstPassenger, secondPassenger, ride);
        }

        public BookingsController CreateController(Guid userId)
        {
            var controller = new BookingsController(Context)
            {
                ControllerContext = new ControllerContext
                {
                    HttpContext = new DefaultHttpContext
                    {
                        User = new ClaimsPrincipal(new ClaimsIdentity(
                            [new Claim(ClaimTypes.NameIdentifier, userId.ToString())],
                            authenticationType: "test"))
                    }
                }
            };
            return controller;
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }

        private static User CreateUser(UserRole role, string name) => new()
        {
            Role = role,
            FullName = name,
            Phone = role == UserRole.Driver ? "03000000001" : $"0300000000{(name == "first" ? 2 : 3)}",
            Email = $"{name}@example.com",
            PasswordHash = "test-hash",
            Cnic = role == UserRole.Driver ? "1111111111111" : name == "first" ? "2222222222222" : "3333333333333",
            Status = UserStatus.Verified
        };
    }

    private static Booking CreateBooking(Ride ride, User passenger, int seats) => new()
    {
        RideId = ride.Id,
        PassengerId = passenger.Id,
        SeatsRequested = seats,
        FareTotal = ride.PricePerSeat * seats,
        PickupTime = ride.DepartureTime,
        TravelDate = ride.DepartureTime.Date,
        Status = BookingStatus.Pending
    };
}
