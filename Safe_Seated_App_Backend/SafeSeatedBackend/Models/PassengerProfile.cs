using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Passenger-specific profile information
/// </summary>
public class PassengerProfile : Entity
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    [StringLength(100)]
    public string University { get; set; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string StudentId { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string ProgramAndSemester { get; set; } = string.Empty;

    [Required]
    [StringLength(13)]
    public string Cnic { get; set; } = string.Empty;

    [Required]
    [StringLength(30)]
    public string Semester { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string EmergencyContactName { get; set; } = string.Empty;

    [Required]
    [StringLength(20)]
    public string EmergencyContactPhone { get; set; } = string.Empty;

    // Navigation
    public User User { get; set; } = null!;
}
