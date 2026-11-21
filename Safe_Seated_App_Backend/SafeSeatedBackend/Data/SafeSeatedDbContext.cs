using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Data;

/// <summary>
/// Entity Framework Core DbContext for SafeSeated
/// </summary>
public class SafeSeatedDbContext : DbContext
{
    public SafeSeatedDbContext(DbContextOptions<SafeSeatedDbContext> options) : base(options) { }

    // Core entities
    public DbSet<User> Users { get; set; }
    public DbSet<PassengerProfile> PassengerProfiles { get; set; }
    public DbSet<DriverProfile> DriverProfiles { get; set; }
    public DbSet<UserDocument> UserDocuments { get; set; }

    // Ride and booking
    public DbSet<Ride> Rides { get; set; }
    public DbSet<Booking> Bookings { get; set; }
    public DbSet<RideRequest> RideRequests { get; set; }

    // Support
    public DbSet<Complaint> Complaints { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure soft delete query filter
        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
        modelBuilder.Entity<Ride>().HasQueryFilter(r => !r.IsDeleted);
        modelBuilder.Entity<Booking>().HasQueryFilter(b => !b.IsDeleted);
        modelBuilder.Entity<RideRequest>().HasQueryFilter(rr => !rr.IsDeleted);
        modelBuilder.Entity<UserDocument>().HasQueryFilter(ud => !ud.IsDeleted);
        modelBuilder.Entity<Complaint>().HasQueryFilter(c => !c.IsDeleted);

        // User entity configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.HasIndex(u => u.Phone).IsUnique();
            entity.HasIndex(u => u.Cnic).IsUnique();
            entity.Property(u => u.Email).IsRequired().HasMaxLength(100);
            entity.Property(u => u.FullName).IsRequired().HasMaxLength(100).HasColumnName("Name");
            entity.Property(u => u.Phone).IsRequired().HasMaxLength(11);
            entity.Property(u => u.Cnic).IsRequired().HasMaxLength(13);
            entity.Property(u => u.Role).HasConversion<string>().HasMaxLength(50);
            entity.Property(u => u.Status).HasConversion<string>().HasMaxLength(50).HasColumnName("VerificationStatus");

            // 1:1 relationships
            entity.HasOne(u => u.PassengerProfile)
                .WithOne(pp => pp.User)
                .HasForeignKey<PassengerProfile>(pp => pp.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(u => u.DriverProfile)
                .WithOne(dp => dp.User)
                .HasForeignKey<DriverProfile>(dp => dp.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 1:M relationships
            entity.HasMany(u => u.Documents)
                .WithOne(ud => ud.User)
                .HasForeignKey(ud => ud.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(u => u.PassengerBookings)
                .WithOne(b => b.Passenger)
                .HasForeignKey(b => b.PassengerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(u => u.DriverRides)
                .WithOne(r => r.Driver)
                .HasForeignKey(r => r.DriverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(u => u.PassengerRideRequests)
                .WithOne(rr => rr.Passenger)
                .HasForeignKey(rr => rr.PassengerId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(u => u.PassengerComplaints)
                .WithOne(c => c.Passenger)
                .HasForeignKey(c => c.PassengerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // PassengerProfile configuration
        modelBuilder.Entity<PassengerProfile>(entity =>
        {
            entity.HasKey(pp => pp.Id);
            entity.HasIndex(pp => pp.UserId).IsUnique();
            entity.Property(pp => pp.ProgramAndSemester).HasColumnName("Program");
        });

        // DriverProfile configuration
        modelBuilder.Entity<DriverProfile>(entity =>
        {
            entity.HasKey(dp => dp.Id);
            entity.HasIndex(dp => dp.UserId).IsUnique();
            entity.HasIndex(dp => dp.PlateNumber).IsUnique();
            entity.Property(dp => dp.IsOnline).HasDefaultValue(true);
            entity.Property(dp => dp.SeatCapacity).HasDefaultValue(1);
            entity.Property(dp => dp.LicenseNumber).HasColumnName("LicenceNumber");
            entity.Property(dp => dp.VehicleMakeModel).HasColumnName("VehicleModel");
            entity.Property(dp => dp.VehicleColor).HasColumnName("VehicleColour");
            entity.Property(dp => dp.VehicleModelYear).HasColumnName("VehicleYear");
        });

        // UserDocument configuration
        modelBuilder.Entity<UserDocument>(entity =>
        {
            entity.ToTable("VerificationDocuments");
            entity.HasKey(ud => ud.Id);
            entity.HasIndex(ud => new { ud.UserId, ud.DocumentType });
            entity.Property(ud => ud.DocumentType).HasConversion<string>().HasMaxLength(50);
            entity.Property(ud => ud.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(ud => ud.StoredFilePath).HasColumnName("FilePath");
            entity.Property(ud => ud.CreatedAt).HasColumnName("UploadedAt");
        });

        // Ride configuration
        modelBuilder.Entity<Ride>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.HasIndex(r => r.DriverId);
            entity.HasIndex(r => r.DepartureTime);
            entity.HasIndex(r => r.Status);
            entity.Property(r => r.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(r => r.RowVersion).IsConcurrencyToken();
            entity.Property(r => r.PricePerSeat).HasPrecision(10, 2);
            entity.Property(r => r.PickupArea).HasColumnName("Pickup");
            entity.Property(r => r.PricePerSeat).HasColumnName("FarePerSeat");
            entity.Property(r => r.SeatsOffered).HasColumnName("TotalSeats");
            entity.HasOne(r => r.SourceRideRequest)
                .WithOne(rr => rr.CreatedRide)
                .HasForeignKey<Ride>(r => r.SourceRideRequestId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Booking configuration
        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(b => b.Id);
            entity.HasIndex(b => new { b.RideId, b.PassengerId })
                .IsUnique()
                .HasFilter("[Status] IN ('Pending', 'Accepted', 'Active')");
            entity.HasIndex(b => b.PassengerId);
            entity.HasIndex(b => b.Status);
            entity.Property(b => b.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(b => b.SeatsRequested).HasColumnName("Seats");
            entity.Property(b => b.FareTotal).HasPrecision(10, 2);
        });

        // RideRequest configuration
        modelBuilder.Entity<RideRequest>(entity =>
        {
            entity.HasKey(rr => rr.Id);
            entity.HasIndex(rr => rr.PassengerId);
            entity.HasIndex(rr => rr.PickupTime);
            entity.HasIndex(rr => rr.Status);
            entity.Property(rr => rr.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(rr => rr.RowVersion).IsConcurrencyToken();
            entity.Property(rr => rr.PickupArea).HasColumnName("Pickup");
            entity.Property(rr => rr.PickupTime).HasColumnName("RequestedTime");
            entity.Property(rr => rr.SeatsNeeded).HasColumnName("Seats");
            entity.Property(rr => rr.AcceptedByDriverId).HasColumnName("AcceptedDriverId");
            entity.HasOne(rr => rr.AcceptedByDriver)
                .WithMany()
                .HasForeignKey(rr => rr.AcceptedByDriverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Complaint configuration
        modelBuilder.Entity<Complaint>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.HasIndex(c => c.PassengerId);
            entity.HasIndex(c => c.RideId);
            entity.HasIndex(c => c.Status);
            entity.Property(c => c.Status).HasConversion<string>().HasMaxLength(50);
            entity.Property(c => c.PassengerId).HasColumnName("ReporterId");
        });

        // Seed data (development only)
        SeedData(modelBuilder);
    }

    private static void SeedData(ModelBuilder modelBuilder)
    {
        // Define seeds using data annotations only
        // This will be supplemented by DbInitializer for more complex scenarios
    }
}
