namespace SafeSeatedBackend.Models;

/// <summary>
/// Booking status lifecycle
/// </summary>
public enum BookingStatus
{
    Pending = 0,    // Driver hasn't responded
    Accepted = 1,   // Driver accepted
    Rejected = 2,   // Driver rejected
    Completed = 3,  // Trip completed
    Cancelled = 4,  // Passenger cancelled or automatic
    Active = 5      // Trip is in progress
}
