# SafeSeated Flutter App

The Flutter app contains Passenger, Driver, authentication, profile/document, ride, booking, ride-request, complaint, and mock-only UI features.

## Run locally

```powershell
cd safeseated_app
flutter pub get
flutter run -d chrome
```

For Android testing on a physical phone, use the computer LAN address instead of `localhost`:

```powershell
flutter run --dart-define=API_BASE_URL=http://<LAN_IP>:5157/api
```

The Android manifest permits local HTTP development traffic.

## Real API areas

- Authentication and `/api/me`
- Passenger/Driver profile updates
- Document upload/list/delete
- Ride search/details
- Bookings and reviews
- Ride requests and cancellation
- Complaints
- Driver rides, availability, open requests, and booking transitions

## Demo-only areas

Notifications, chat, live trip sharing, SOS alerts, wallet/payment submission, and some map illustrations are not backed by existing API endpoints.

## Validate

```powershell
flutter analyze
flutter test
flutter build apk --release
flutter build web
```
