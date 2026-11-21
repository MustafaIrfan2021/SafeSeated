namespace SafeSeatedBackend.Models;

/// <summary>
/// Types of documents that users can upload
/// </summary>
public enum DocumentType
{
    CnicFront = 0,
    CnicBack = 1,
    StudentCard = 2,
    DrivingLicence = 3,
    VehicleRegistration = 4,
    VehiclePhoto = 5
}
