namespace SafeSeatedBackend.Models;

/// <summary>
/// Ride status lifecycle
/// </summary>
public enum RideStatus
{
    Active = 0,      // Accepting bookings
    Cancelled = 1,   // Driver or admin cancelled
    Completed = 2,   // Trip finished
    Removed = 3      // Admin removed the ride
}
