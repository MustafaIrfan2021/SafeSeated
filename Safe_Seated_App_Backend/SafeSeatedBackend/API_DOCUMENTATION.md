# SafeSeatedBackend REST API

Simple, single-project ASP.NET Core Web API for the SafeSeated mobile carpooling application.

The application code is in `SafeSeatedBackend.csproj`: controllers, models, the EF Core context, migrations, middleware, and a small shared helper. Automated tests are in `SafeSeatedBackend.Tests`.

## Overview

SafeSeated Backend Provides ride-sharing functionality including:
- **Ride Management**: Post, search, and manage rides
- **Booking System**: Request rides with seat availability tracking
- **Ride Requests**: Passengers can request rides, drivers can accept atomically
- **Driver Ratings**: Passenger review system for drivers
- **Concurrency Handling**: Safe concurrent operations with transaction support

## Technology Stack

- **Framework**: ASP.NET Core 10.0 Web API
- **Database**: SQL Server with Entity Framework Core 8.0
- **Authentication**: JWT Bearer Tokens
- **ORM**: Entity Framework Core with soft-delete support
- **API Documentation**: Swagger/OpenAPI

## Getting Started

### Prerequisites
- .NET SDK 10.0.400+
- SQL Server (LocalDB or Express)
- Visual Studio 2026 or VS Code

### Installation

1. Update `appsettings.json` with your SQL Server connection string.
2. Set the JWT signing key in the terminal before starting the API:
   ```powershell
   $env:Jwt__SecretKey = "<new random value with at least 32 bytes>"
   ```
3. Start the API:
   ```powershell
   dotnet run --project SafeSeatedBackend.csproj
   ```
4. Open Swagger UI at the address printed by `dotnet run`. Startup migrations and admin seeding are disabled by default; enable them only when you intend to update the database, and provide `Admin__Password` before doing so.

Run the automated tests from the `SafeSeatedBackend` folder:
```powershell
dotnet test SafeSeatedBackend.Tests\SafeSeatedBackend.Tests.csproj
```

## API Endpoints

### Authentication

#### Register passenger
```
POST /api/auth/register/passenger
Content-Type: application/json

{
  "name": "Ayesha Khan",
  "email": "ayesha@example.com",
  "phone": "03001234567",
  "cnic": "1234512345671",
  "password": "choose-a-password",
  "university": "Example University",
  "studentId": "STU-1",
  "program": "Computer Science",
  "semester": "4",
  "emergencyContactName": "Fatima Khan",
  "emergencyContactPhone": "03331234567"
}
```

#### Register driver
```
POST /api/auth/register/driver
Content-Type: application/json

{
  "name": "Sana Malik",
  "email": "sana@example.com",
  "phone": "03211234567",
  "cnic": "1234512345672",
  "password": "choose-a-password",
  "city": "Karachi",
  "licenceNumber": "DL-123",
  "vehicleMake": "Toyota",
  "vehicleModel": "Corolla",
  "vehicleColour": "Silver",
  "plateNumber": "ABC-123",
  "vehicleYear": 2022,
  "seatCapacity": 3
}
```

Email is stored lowercase, phone must be an 11-digit Pakistani mobile number, CNIC must contain 13 digits, and passwords must be 8–72 UTF-8 bytes. Registration creates a pending account; pending users may log in to upload verification documents.

#### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "ayesha@example.com",
  "password": "choose-a-password"
}
```

The response contains an `accessToken` and basic user details. Send it as `Authorization: Bearer {token}`. Refresh tokens are not used.

#### Current user profile
```
GET /api/me
PATCH /api/me
Authorization: Bearer {token}
```

The patch body accepts editable identity/contact fields and the fields for the user's existing passenger or driver profile. Role and verification status are controlled by the server. Changing CNIC or driver licence/vehicle details resets verification to `Pending`.

### Verification documents

Uploads are stored under `wwwroot/uploads`; only the relative path is saved in the database. Accepted extensions are `.jpg`, `.jpeg`, `.png`, and `.pdf`, with a maximum size of 5 MB. Passenger accounts may upload `CnicFront`, `CnicBack`, and `StudentCard`; driver accounts may upload `CnicFront`, `CnicBack`, `DrivingLicence`, `VehicleRegistration`, and `VehiclePhoto`.

#### Upload a document
```
POST /api/documents
Authorization: Bearer {token}
Content-Type: multipart/form-data

documentType: CnicFront
file: <selected file>
```

#### List or delete your documents
```
GET /api/documents/me
DELETE /api/documents/{id}
Authorization: Bearer {token}
```

Users can delete only their own pending documents. The list and upload responses include `fileUrl` for displaying the uploaded file.

#### Admin review
```
GET /api/admin/documents?status=Pending
PATCH /api/admin/documents/{id}/status
Authorization: Bearer {admin token}
Content-Type: application/json

{ "status": "Approved" }
```

The status must be `Approved` or `Rejected`; only pending documents can be reviewed. Verification status is recalculated from the latest document of each required type. Static file serving is enabled for returned file URLs.

### Rides (`/api/rides`)

#### Create Ride (Driver)
```
POST /api/rides
Authorization: Bearer {token}
Content-Type: application/json

{
  "pickup": "NUML University",
  "destination": "DHA Phase 5",
  "departureTime": "2026-11-18T09:00:00Z",
  "farePerSeat": 250,
  "totalSeats": 3,
  "notes": "Meet at the main gate"
}
```

#### Search rides
```
GET /api/rides?pickup=NUML&destination=DHA&date=2026-11-18&seats=1
```

#### Get a ride and the current driver's rides
```
GET /api/rides/{id}
GET /api/drivers/me/rides
Authorization: Bearer {token}
```

#### Update, cancel, or change availability
```
PATCH /api/rides/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "farePerSeat": 300,
  "totalSeats": 4
}
```

A ride deletion request cancels the ride and its active bookings; it does not physically delete the ride.
```
DELETE /api/rides/{id}
Authorization: Bearer {token}
```

```
PATCH /api/drivers/me/availability
Authorization: Bearer {token}
Content-Type: application/json

{ "isOnline": true }
```

### Bookings (`/api/bookings`)

#### Create Booking (Passenger)
```
POST /api/bookings
Authorization: Bearer {token}
Content-Type: application/json

{
  "rideId": "550e8400-e29b-41d4-a716-446655440000",
  "seats": 2
}
```

Fare total is calculated by the server.

#### List bookings and get one booking
```
GET /api/bookings/{id}
GET /api/bookings/me?status=Accepted
GET /api/drivers/me/bookings?status=Pending
Authorization: Bearer {token}
```

#### Change status or review a booking
```
PATCH /api/bookings/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{ "status": "Accepted" }
```

The status must follow the booking flow: a passenger can cancel a pending booking; the ride's driver can accept or reject a pending booking, move an accepted booking to active, and complete an active booking. Completing directly from `Accepted` is not allowed. The driver must first mark the booking `Active`, then mark it `Completed`; neither transition is allowed before the ride's scheduled departure.

For example, after accepting a booking, the ride's driver starts it:
```
PATCH /api/bookings/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{ "status": "Active" }
```

After the scheduled departure, the ride's driver completes it:
```
PATCH /api/bookings/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{ "status": "Completed" }
```

Only the passenger can review their completed booking, once:
```
POST /api/bookings/{id}/review
Authorization: Bearer {token}
Content-Type: application/json

{
  "rating": 5,
  "review": "Great ride!"
}
```
### Ride Requests (`/api/ride-requests`)

#### Create Ride Request (Passenger)
```
POST /api/ride-requests
Authorization: Bearer {token}
Content-Type: application/json

{
  "pickup": "FAST University",
  "destination": "Karachi Airport",
  "requestedTime": "2026-11-18T12:00:00Z",
  "seats": 3
}
```

#### List requests or cancel one
```
GET /api/ride-requests/me
POST /api/ride-requests/{id}/cancel
Authorization: Bearer {token}
```

#### List open requests or offer a ride (Driver)
```
GET /api/ride-requests/open
Authorization: Bearer {token}
```

An offer creates the ride and its accepted booking in one transaction. Only one driver can fulfil an open request. Offered seats must cover the request and fit the driver's vehicle capacity; the fare must be from PKR 0.01 to 1,000,000 per seat.
```
POST /api/ride-requests/{id}/offers
Authorization: Bearer {token}
Content-Type: application/json

{
  "totalSeats": 4,
  "farePerSeat": 300
}
```
### Complaints

Submit a complaint with an optional ride ID. The reporter ID, status, and creation time are set by the server.
```
POST /api/complaints
Authorization: Bearer {token}
Content-Type: application/json

{
  "rideId": "550e8400-e29b-41d4-a716-446655440000",
  "description": "The pickup location was different from the agreed location."
}
```

List only your own complaints:
```
GET /api/complaints/me
Authorization: Bearer {token}
```

## Response Format

### Success Response
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "driverName": "Ahmed Khan",
  "pickup": "NUML University",
  "destination": "DHA Phase 5",
  "totalSeats": 3,
  "seatsAvailable": 1,
  "farePerSeat": 250,
  "status": "Active"
}
```

### Error Response
```json
{
  "type": "about:blank",
  "title": "Only active rides can be updated",
  "status": 409
}
```

Validation errors use `ValidationProblemDetails` with field-specific errors.

### Paginated Response
```json
{
  "data": [...],
  "pagination": {
	"page": 1,
	"pageSize": 10,
	"totalCount": 45,
	"totalPages": 5
  }
}
```

## Booking Status Flow

1. **Pending** - Awaiting driver acceptance
2. **Accepted** - Driver accepted the booking
3. **Rejected** - Driver rejected the booking
4. **Cancelled** - Passenger or ride cancellation
5. **Completed** - Trip finished, ready for rating

## Ride Status

- **Active** - Available for bookings
- **Cancelled** - Driver cancelled the ride

## Ride Request Status

- **Open** - Awaiting driver responses
- **Accepted** - Driver accepted
- **Cancelled** - Passenger cancelled

## Business Rules

### Ride Creation
- Driver must have verified status
- Departure time must be future
- Seats offered cannot exceed vehicle capacity

### Booking Creation
- Passenger must have verified status
- Ride must be active and in future
- Passenger cannot have duplicate active bookings
- Seat availability checked

### Ride Request -> Ride Acceptance
- Atomic transaction creates:
  - New Ride with driver details
  - Accepted Booking for passenger
  - Updates RideRequest status
- Protects against concurrent race conditions

### Ratings
- Only completed bookings can be rated
- Ratings are 1-5 stars
- Driver average rating updated automatically
- One rating per booking maximum

## Error Handling

The API returns appropriate HTTP status codes:
- `200 OK` - Successful GET/PUT/POST
- `201 Created` - Resource created
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid input data
- `401 Unauthorized` - Missing/Invalid token
- `403 Forbidden` - Access denied (not owner)
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

## Security Features

- JWT Bearer token authentication
- Authorization checks on ownership (drivers/passengers)
- SQL injection protection via EF Core
- Concurrent operation safety with transactions
- Soft-delete for data retention
- UTC datetime handling

## Development Notes

### Database Migrations
```powershell
# Add migration
dotnet ef migrations add MigrationName --project SafeSeatedBackend.csproj

# Apply migrations only when you are ready to update the database
dotnet ef database update --project SafeSeatedBackend.csproj

# Remove last migration
dotnet ef migrations remove --project SafeSeatedBackend.csproj
```

### Logging
All endpoints log:
- User actions with IDs
- Validation failures
- Authorization denials
- Errors with stack traces

### Configuration
Keep secrets out of configuration files. Set `Jwt__SecretKey` in user secrets or the environment; the API requires at least 32 bytes. Non-secret settings in `appsettings.json` include:
```json
{
  "ConnectionStrings": {
	"DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=SafeSeatedDb;Trusted_Connection=true;"
  },
  "Jwt": {
	"SecretKey": "",
	"Issuer": "SafeSeated",
	"Audience": "SafeSeatedApp",
	"AccessTokenExpiryMinutes": 15
  }
}
```

## Support

For issues, questions, or contributions, please refer to the project repository.