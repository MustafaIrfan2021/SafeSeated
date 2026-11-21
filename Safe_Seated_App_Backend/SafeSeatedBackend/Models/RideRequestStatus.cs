namespace SafeSeatedBackend.Models;

/// <summary>
/// Ride request status
/// </summary>
public enum RideRequestStatus
{
    Open = 0,       // Awaiting driver acceptance
    Accepted = 1,   // Driver created a ride and booked the passenger
    Cancelled = 2   // Passenger or system cancelled
}
