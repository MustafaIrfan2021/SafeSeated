using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Driver-specific profile and vehicle information
/// </summary>
public class DriverProfile : Entity
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    [StringLength(13)]
    public string Cnic { get; set; } = string.Empty;

    [Required]
    [StringLength(50)]
    public string City { get; set; } = string.Empty;

    [Required]
    [StringLength(50)]
    public string LicenseNumber { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string VehicleMakeModel { get; set; } = string.Empty; // e.g., "Toyota Corolla"

    [Required]
    [StringLength(50)]
    public string VehicleMake { get; set; } = string.Empty;

    [Required]
    [StringLength(30)]
    public string VehicleColor { get; set; } = string.Empty;

    [Required]
    [StringLength(15)]
    public string PlateNumber { get; set; } = string.Empty; // Unique

    [Required]
    public int VehicleModelYear { get; set; }

    [Required]
    public int SeatsForPassengers { get; set; }

    [Required]
    public int SeatCapacity { get; set; }

    [Required]
    [StringLength(50)]
    public string VehicleRegistrationNumber { get; set; } = string.Empty;

    [Required]
    public bool IsOnline { get; set; } = true;

    public double? AverageRating { get; set; }

    [StringLength(100)]
    public string? EmergencyContactName { get; set; }

    [StringLength(11)]
    public string? EmergencyContactPhone { get; set; }

    // Navigation
    public User User { get; set; } = null!;
}
