using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Ride posted by a driver
/// </summary>
public class Ride : Entity
{
    [Required]
    public Guid DriverId { get; set; }

    [Required]
    [StringLength(100)]
    public string PickupArea { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Destination { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Notes { get; set; }

    [Required]
    public DateTime DepartureTime { get; set; }

    [Required]
    public decimal PricePerSeat { get; set; }

    [Required]
    public int SeatsOffered { get; set; }

    [Required]
    public RideStatus Status { get; set; } = RideStatus.Active;

    /// <summary>
    /// If this ride was auto-created from a RideRequest, this links to that request
    /// </summary>
    public Guid? SourceRideRequestId { get; set; }

    /// <summary>
    /// Concurrency token to prevent seat overbooking
    /// </summary>
    public uint RowVersion { get; set; }

    // Navigation
    [Required]
    public User Driver { get; set; } = null!;

    public RideRequest? SourceRideRequest { get; set; }

    public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
}
