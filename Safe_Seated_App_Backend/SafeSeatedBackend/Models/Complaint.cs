using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Complaint filed by a passenger about a ride or driver
/// </summary>
public class Complaint : Entity
{
    [Required]
    public Guid PassengerId { get; set; }

    public Guid? RideId { get; set; }

    [Required]
    [StringLength(1000)]
    public string Description { get; set; } = string.Empty;

    [Required]
    public ComplaintStatus Status { get; set; } = ComplaintStatus.Open;

    // Navigation
    [Required]
    public User Passenger { get; set; } = null!;

    public Ride? Ride { get; set; }
}
