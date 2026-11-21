using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Represents a user in the SafeSeated platform
/// </summary>
public class User : Entity
{
    [Required]
    public UserRole Role { get; set; }

    [Required]
    [StringLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [StringLength(11)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    [StringLength(13)]
    public string Cnic { get; set; } = string.Empty;

    [Required]
    public UserStatus Status { get; set; } = UserStatus.Pending;

    public DateTime? LastLoginAt { get; set; }

    // Navigation properties
    public PassengerProfile? PassengerProfile { get; set; }
    public DriverProfile? DriverProfile { get; set; }
    public ICollection<UserDocument> Documents { get; set; } = new List<UserDocument>();
    public ICollection<Booking> PassengerBookings { get; set; } = new List<Booking>();
    public ICollection<Ride> DriverRides { get; set; } = new List<Ride>();
    public ICollection<RideRequest> PassengerRideRequests { get; set; } = new List<RideRequest>();
    public ICollection<Complaint> PassengerComplaints { get; set; } = new List<Complaint>();
}
