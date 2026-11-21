# SafeSeated Project Handover

## 1. Project overview

SafeSeated is a university Final Year Project with three applications:

- Flutter client for Passenger and Driver users
- React/Vite Admin Panel for document review
- ASP.NET Core Web API backed by SQL Server through Entity Framework Core

The Flutter app and React Admin Panel use the same ASP.NET Core API and SQL Server database.

Workspace:

- Flutter: `safeseated_app/`
- React Admin: `safeseated-admin/`
- ASP.NET Core: `Safe_Seated_App_Backend/SafeSeatedBackend/`

## 2. Architecture

### Flutter

- Flutter, Dart, Riverpod, GoRouter
- API client using `http`
- Secure JWT storage using `flutter_secure_storage`
- Existing repository interfaces preserved
- API implementations added for authentication, profile, documents, Passenger features, and Driver features
- Mock repositories remain only for demo-only or legacy UI areas

Base API configuration:

- Default: `http://localhost:5157/api`
- Override: `--dart-define=API_BASE_URL=http://<LAN_IP>:5157/api`

Main implementation areas:

- `lib/core/network/`
- `lib/core/providers/app_providers.dart`
- `lib/features/auth/data/api_auth_repository.dart`
- `lib/features/passenger/data/api_ride_repository.dart`
- `lib/features/passenger/data/api_booking_repository.dart`
- `lib/features/safety/data/api_safety_repository.dart`
- `lib/features/profile/data/document_service.dart`

### React Admin Panel

- React 18 and Vite
- Existing UI and purple theme preserved
- JWT stored in browser local storage
- Document-review API integration is in `src/api.js`
- Document review UI is in `src/pages/Verification.jsx`
- Unsupported tabs remain visibly marked as demo-only

Base API configuration:

- Default: `http://localhost:5157/api`
- Override in `.env.local`: `VITE_API_BASE_URL=http://<HOST_IP>:5157/api`

### ASP.NET Core backend

- ASP.NET Core controller-based Web API
- EF Core with SQL Server
- JWT bearer authentication
- BCrypt password hashing
- Swagger and static file support
- Soft-delete query filters
- Controller-level role and ownership checks

Primary files:

- `Program.cs`
- `Controllers/AuthController.cs`
- `Controllers/ProfileController.cs`
- `Controllers/DocumentsController.cs`
- `Controllers/RidesController.cs`
- `Controllers/BookingsController.cs`
- `Controllers/RideRequestsController.cs`
- `Controllers/ComplaintsController.cs`
- `Data/SafeSeatedDbContext.cs`

## 3. Implemented features

### Authentication

- Passenger registration
- Driver registration
- Login
- JWT generation and validation
- Session restoration
- Passenger/Driver/Admin role recognition
- Expired/invalid-token clearing

### Profile and documents

- `GET /api/me`
- `PATCH /api/me`
- Passenger and Driver profile mapping
- Document list, upload, and pending-document deletion
- Required Passenger types: `CnicFront`, `CnicBack`, `StudentCard`
- Required Driver types: `CnicFront`, `CnicBack`, `DrivingLicence`, `VehicleRegistration`, `VehiclePhoto`
- JPG, JPEG, PNG, and PDF; maximum 5 MB

### Passenger

- Ride search and details
- Seat booking
- Passenger booking list
- Pending booking cancellation
- Completed booking review
- Create/cancel/list ride requests
- Submit/list complaints

### Driver

- View created rides
- Create/update/cancel rides
- Online/offline availability
- View open Passenger ride requests
- Submit ride offers
- View Driver bookings
- Accept/reject pending bookings
- Move Accepted bookings to Active
- Move Active bookings to Completed

### React Admin

- Real Admin login
- JWT Bearer storage
- Pending, Approved, Rejected, or All document filtering
- Passenger/Driver document role filtering
- Document file links
- Approve/Reject document actions

Unsupported modules remain demo-only:

- Notifications
- Chat
- Live location/SOS delivery
- Payment processing
- Fee confirmation
- Settings persistence
- Activity-log persistence
- Account-wide suspension/resubmission workflows

## 4. API configuration

Default local API URL:

- `http://localhost:5157/api`
- Swagger: `http://localhost:5157/swagger`

Backend configuration keys:

- `ConnectionStrings:DefaultConnection`
- `Jwt:SecretKey`
- `Jwt:Issuer`
- `Jwt:Audience`
- `Jwt:AccessTokenExpiryMinutes`
- `Admin:Email`
- `Admin:Password`
- `Database:ApplyMigrationsOnStartup`

Store JWT signing keys and passwords in user-secrets or environment variables. Never commit actual values.

Local SQL Server is configured for SQL Server LocalDB by default. Do not enable startup migrations or create migrations unless explicitly required.

For another development computer:

- Set a valid SQL Server connection string
- Set a JWT secret of at least 32 bytes
- Set the Admin configuration separately
- Configure Flutter/React API URLs to use the backend host

## 5. Database configuration

Database provider:

- SQL Server
- EF Core
- Default database name: `SafeSeatedDb`

Development startup migrations are currently disabled.

Do not run `database update`, add a migration, or enable `Database:ApplyMigrationsOnStartup` during normal frontend testing unless a schema change is intentionally required and approved.

## 6. Test results

### Flutter

- Automated tests: 43 passed
- `flutter analyze`: 43 info-level notices from existing `package:flutter/material.dart` deprecation warnings; no errors reported by the final code pass
- Flutter Web build: successful
- Android release build:
  - Initially blocked by Gradle 8.14 vs Flutter minimum 9.3.1
  - Wrapper upgraded to Gradle 9.3.1
  - Subsequent build attempts were blocked by Gradle cache lock/download timeout
  - Final APK was not produced

The Android cleartext HTTP setting was enabled for local HTTP development. Production should use HTTPS.

### React Admin

- Production build: successful
- Vite transformed 42 modules
- Document-review source contains no obsolete account suspension/resubmission actions

### ASP.NET Core

- Build: successful
- 0 warnings
- 0 errors
- Automated tests: 23 passed

### Live API checks

- Backend health: `200 OK`
- Public ride search: `200 OK`, with an empty result at the time of testing
- Protected `/api/me`: `401 Unauthorized` without a token
- Protected `/api/admin/documents`: `401 Unauthorized` without a token
- Live Admin login was not confirmed because user-secrets were unavailable to the test shell
- No live Passenger/Driver workflow was claimed as fully verified
- Live React or Flutter form submissions were not run automatically

## 7. Known remaining issues

1. Android release build is pending successful download/extraction of Gradle 9.3.1.
   - The wrapper cache contains the archive and an active lock file.
   - Before retrying, wait for all Gradle/Java build processes to finish.
   - Then run `flutter build apk --release` again.
2. Flutter Android default API URL is `localhost`, which refers to the phone itself. Physical devices require `--dart-define=API_BASE_URL=http://<PC_LAN_IP>:5157/api`.
3. React default API URL is `localhost`, which is browser-local. LAN/browser testing may require `VITE_API_BASE_URL`.
4. Admin login session restoration only checks stored data and does not decode JWT expiry during startup.
5. The backend currently serves uploaded document files through static URLs; private expiring links are not implemented.
6. The Flutter password-change screen has no matching backend password endpoint.
7. Notifications and chat remain demo-only.
8. SOS and live trip sharing remain demo-only.
9. Wallet/payment submissions remain demo-only.
10. Dashboard, Rides, Payments, Safety, Settings, and Activity Log in React remain demo-only.
11. Flutter mock repository classes remain in source for tests and unsupported demo features.

## 8. Commands

### ASP.NET Core

```powershell
cd Safe_Seated_App_Backend/SafeSeatedBackend
dotnet restore
dotnet build
dotnet test
dotnet run --launch-profile http
```

Swagger:

- `http://localhost:5157/swagger`

Health:

- `http://localhost:5157/health`

### Flutter

```powershell
cd safeseated_app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build web
flutter build apk --release
```

Physical Android device:

```powershell
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:5157/api
```

Ensure the PC firewall allows port 5157 and the phone can reach the PC over the same LAN.

### React Admin

```powershell
cd safeseated-admin
npm install
npm run dev
npm run build
npm run preview
```

Optional local environment:

```text
VITE_API_BASE_URL=http://localhost:5157/api
```

## 9. Manual Flutter testing

Passenger:

1. Register a new Passenger.
2. Log in.
3. Upload CnicFront, CnicBack, and StudentCard.
4. Verify Pending/Approved/Rejected status.
5. Search rides.
6. Open ride details and submit a booking.
7. View Pending/Accepted booking states.
8. Cancel a Pending booking.
9. Submit a review only after the backend marks the booking Completed.
10. Create, view, and cancel ride requests.
11. Submit and view complaints.

Driver:

1. Register a Driver.
2. Upload all five required documents.
3. Go online only after verification.
4. Create, edit, and cancel rides.
5. View open ride requests.
6. Submit an offer.
7. Accept/reject Passenger bookings.
8. Start an Accepted booking only after scheduled departure.
9. Complete an Active booking only after scheduled departure.

## 10. Manual React Admin testing

1. Start the ASP.NET Core API.
2. Start the React app.
3. Log in with the existing Admin account.
4. Open Driver or Passenger verification.
5. Filter for Pending documents.
6. Open a document file URL.
7. Approve or reject the document.
8. Confirm the overall verification status changes automatically according to backend rules.
9. Confirm expired/invalid JWT sessions return to login.

Do not test account suspension, resubmission, payments, or dashboard totals as live features; they are demo-only.

## 11. Deployment checklist

Before production deployment:

- Use HTTPS for the API and frontend
- Configure a non-local SQL Server database
- Set secrets outside source control
- Replace `localhost` API URLs
- Add Android network-security restrictions only for HTTPS
- Remove or clearly separate demo-only React sections
- Replace static document URLs with private expiring URLs
- Add password-change and notification endpoints if desired
- Add payment endpoints if payment workflows are required
- Do not enable startup migrations automatically in production
- Create and apply migrations only after reviewing the EF model diff

## 12. Handover status

Phases 1–6 are implemented. Phase 7 source/build validation is complete except for the Android Gradle cache/download and live end-to-end manual testing.

No database schema or migrations were changed during this handover.
