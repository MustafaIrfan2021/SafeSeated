namespace SafeSeatedBackend.Models;

/// <summary>
/// User account status
/// </summary>
public enum UserStatus
{
    Pending = 0,      // Waiting for admin verification
    Verified = 1,
    Rejected = 2      // Verification failed
}
