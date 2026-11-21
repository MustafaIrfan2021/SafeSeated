namespace SafeSeatedBackend.Models;

/// <summary>
/// Document verification status
/// </summary>
public enum DocumentStatus
{
    Pending = 0,   // Awaiting admin review
    Approved = 1,  // Document verified
    Rejected = 2   // Document rejected; user should re-upload
}
