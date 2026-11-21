using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// A passenger's public request for a ride (no specific ride yet)
/// </summary>
public class RideRequest : Entity
{
    [Required]
    public Guid PassengerId { get; set; }

    [Required]
    [StringLength(100)]
    public string PickupArea { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Destination { get; set; } = string.Empty;

    [Required]
    public DateTime PickupTime { get; set; }

    [Required]
    public int SeatsNeeded { get; set; }

    [Required]
    public RideRequestStatus Status { get; set; } = RideRequestStatus.Open;

    public Guid? AcceptedByDriverId { get; set; }

    /// <summary>
    /// The Ride created when a driver accepts this request
    /// </summary>
    public Guid? CreatedRideId { get; set; }

    /// <summary>
    /// Concurrency token
    /// </summary>
    public uint RowVersion { get; set; }

    // Navigation
    [Required]
    public User Passenger { get; set; } = null!;

    public User? AcceptedByDriver { get; set; }

    public Ride? CreatedRide { get; set; }
}
