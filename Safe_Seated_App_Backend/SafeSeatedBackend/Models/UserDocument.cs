using SafeSeatedBackend.Models;
using System.ComponentModel.DataAnnotations;

namespace SafeSeatedBackend.Models;

/// <summary>
/// Document upload for user verification
/// </summary>
public class UserDocument : Entity
{
    [Required]
    public Guid UserId { get; set; }

    [Required]
    public DocumentType DocumentType { get; set; }

    [Required]
    [StringLength(500)]
    public string StoredFilePath { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string ContentType { get; set; } = string.Empty; // e.g., "image/jpeg"

    [Required]
    [StringLength(255)]
    public string OriginalFileName { get; set; } = string.Empty;

    [Required]
    public DocumentStatus Status { get; set; } = DocumentStatus.Pending;

    public Guid? ReviewedByAdminId { get; set; }

    public DateTime? ReviewedAt { get; set; }

    [StringLength(500)]
    public string? RejectionReason { get; set; }

    // Navigation
    public User User { get; set; } = null!;
    public User? ReviewedByAdmin { get; set; }
}
