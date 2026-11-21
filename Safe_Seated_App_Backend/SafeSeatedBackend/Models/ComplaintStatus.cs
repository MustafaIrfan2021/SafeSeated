namespace SafeSeatedBackend.Models;

/// <summary>
/// Complaint status
/// </summary>
public enum ComplaintStatus
{
    Open = 0,       // New complaint
    InReview = 1,   // Admin is investigating
    Resolved = 2,   // Issue resolved
    Dismissed = 3   // Complaint dismissed
}
