using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Booking: a passenger's request to join a ride
/// </summary>
public class Booking : Entity
{
    [Required]
    public Guid RideId { get; set; }

    [Required]
    public Guid PassengerId { get; set; }

    [Required]
    public int SeatsRequested { get; set; }

    [Required]
    public decimal FareTotal { get; set; }

    [Required]
    public DateTime PickupTime { get; set; }

    [Required]
    public BookingStatus Status { get; set; } = BookingStatus.Pending;

    [Required]
    public DateTime TravelDate { get; set; }

    public DateTime UpdatedAt { get; set; }

    public int? Rating { get; set; } // 1-5 star rating

    [StringLength(500)]
    public string? Review { get; set; }

    public DateTime? RatedAt { get; set; }

    // Navigation
    [Required]
    public Ride Ride { get; set; } = null!;

    [Required]
    public User Passenger { get; set; } = null!;

}
