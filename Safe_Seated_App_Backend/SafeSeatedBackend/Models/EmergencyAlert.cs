using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

public class EmergencyAlert : Entity
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    public UserRole ReporterRole { get; set; }

    [Required]
    [StringLength(64)]
    public string ClientRequestId { get; set; } = string.Empty;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public Guid? RideId { get; set; }

    [Required]
    [StringLength(20)]
    public string Status { get; set; } = "Open";

    public User User { get; set; } = null!;

    public Ride? Ride { get; set; }
}
