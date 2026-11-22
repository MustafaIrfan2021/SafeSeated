import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safeseated_app/core/network/api_client.dart';
import 'package:safeseated_app/core/network/token_storage.dart';
import 'package:safeseated_app/features/passenger/data/api_ride_repository.dart';
import 'package:safeseated_app/features/passenger/domain/models/booking.dart';
import 'package:safeseated_app/features/safety/data/api_safety_repository.dart';
import 'package:safeseated_app/core/network/api_id_mapper.dart';
import 'package:safeseated_app/features/passenger/data/api_booking_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'test-token';

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }
}

void main() {
  test('ride details include the stored bearer token', () async {
    final storage = _MemoryTokenStorage();
    final rideGuid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    ApiIdMapper.remember(901, rideGuid);
    final client = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/rides/$rideGuid');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({
            'id': rideGuid,
            'driverName': 'Sana Malik',
            'pickup': 'Clifton',
            'destination': 'SMIU',
            'departureTime': '2026-11-20T08:00:00Z',
            'farePerSeat': 350,
            'totalSeats': 3,
            'seatsAvailable': 2,
            'status': 'Active',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final ride = await ApiRideRepository(client).getRideById(901);

    expect(ride, isNotNull);
    expect(ride!.from, 'Clifton');
  });

  test(
    'SOS create uses the authenticated API and maps server identity fields',
    () async {
      final storage = _MemoryTokenStorage();
      final client = ApiClient(
        tokenStorage: storage,
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/emergency-alerts');
          expect(request.headers['Authorization'], 'Bearer test-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            body['clientRequestId'],
            'ffffffff-ffff-4fff-8fff-ffffffffffff',
          );
          expect(body['latitude'], 24.86);
          expect(body['longitude'], 67.0);
          expect(body.containsKey('rideId'), isFalse);
          return http.Response(
            jsonEncode({
              'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
              'role': 'Passenger',
              'latitude': 24.86,
              'longitude': 67.0,
              'rideId': null,
              'createdAt': '2026-11-21T22:00:00Z',
              'status': 'Open',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final alert = await ApiSafetyRepository(client).triggerSos(
        clientRequestId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        latitude: 24.86,
        longitude: 67,
      );

      expect(alert.role, 'Passenger');
      expect(alert.latitude, 24.86);
      expect(alert.longitude, 67);
      expect(alert.timestamp, DateTime.parse('2026-11-21T22:00:00Z'));
      expect(alert.status, 'Open');
    },
  );

  test('SOS history uses the authenticated current-user endpoint', () async {
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/emergency-alerts/me');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode([
            {
              'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              'role': 'Driver',
              'latitude': null,
              'longitude': null,
              'rideId': null,
              'createdAt': '2026-11-21T22:00:00Z',
              'status': 'Open',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final alerts = await ApiSafetyRepository(client).getSosIncidents();

    expect(alerts, hasLength(1));
    expect(alerts.single.role, 'Driver');
    expect(alerts.single.latitude, isNull);
    expect(alerts.single.longitude, isNull);
  });

  test('SOS request includes the backend ride ID when available', () async {
    const rideGuid = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    ApiIdMapper.remember(77, rideGuid);
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['rideId'], rideGuid);
        return http.Response(
          jsonEncode({
            'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
            'role': 'Passenger',
            'latitude': null,
            'longitude': null,
            'rideId': rideGuid,
            'createdAt': '2026-11-21T22:00:00Z',
            'status': 'Open',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final alert = await ApiSafetyRepository(client).triggerSos(
      clientRequestId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      rideId: 77,
    );

    expect(alert.rideId, 77);
  });

  test('ride search maps paginated response to Ride models', () async {
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['pickup'], 'Clifton');
        expect(request.url.queryParameters['seats'], '1');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': '11111111-1111-1111-1111-111111111111',
                'driverName': 'Sana Malik',
                'pickup': 'Clifton',
                'destination': 'SMIU',
                'departureTime': '2026-11-20T08:00:00Z',
                'farePerSeat': 350,
                'totalSeats': 3,
                'seatsAvailable': 2,
                'vehicleMakeModel': 'Suzuki Alto',
                'plateNumber': 'BCA-412',
                'driverRating': 4.8,
                'status': 'Active',
              },
            ],
            'pagination': {
              'page': 1,
              'pageSize': 100,
              'totalCount': 1,
              'totalPages': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final rides = await ApiRideRepository(
      client,
    ).getAvailableRides(pickupQuery: 'Clifton', seatsNeeded: 1);

    expect(rides, hasLength(1));
    expect(rides.single.from, 'Clifton');
    expect(rides.single.seatsAvailable, 2);
  });

  test('ride search returns no rides for an empty paginated response', () async {
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['pickup'], 'Gulshan-e-Iqbal');
        expect(request.url.queryParameters['seats'], '1');
        return http.Response(
          jsonEncode({
            'data': <Object>[],
            'pagination': {
              'page': 1,
              'pageSize': 100,
              'totalCount': 0,
              'totalPages': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final rides = await ApiRideRepository(
      client,
    ).getAvailableRides(pickupQuery: 'Gulshan-e-Iqbal', seatsNeeded: 1);

    expect(rides, isEmpty);
  });

  test(
    'passenger bookings map backend status and create uses GUID ride id',
    () async {
      final storage = _MemoryTokenStorage();
      final client = ApiClient(
        tokenStorage: storage,
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'id': '22222222-2222-2222-2222-222222222222',
                  'rideId': '11111111-1111-1111-1111-111111111111',
                  'passengerName': 'Ayesha',
                  'seats': 2,
                  'fareTotal': 700,
                  'pickupTime': '2026-11-20T08:00:00Z',
                  'travelDate': '2026-11-20',
                  'status': 'Accepted',
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'id': '22222222-2222-2222-2222-222222222222',
              'rideId': '11111111-1111-1111-1111-111111111111',
              'passengerName': 'Ayesha',
              'seats': 2,
              'fareTotal': 700,
              'pickupTime': '2026-11-20T08:00:00Z',
              'travelDate': '2026-11-20',
              'status': 'Pending',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = ApiBookingRepository(client);
      final bookings = await repository.getBookings(
        'ayesha@example.com',
        status: BookingStatus.accepted,
      );
      expect(bookings, hasLength(1));
      expect(bookings.single.status, BookingStatus.accepted);
    },
  );

  test('driver bookings use the authenticated driver endpoint', () async {
    const bookingGuid = '22222222-2222-2222-2222-222222222222';
    const rideGuid = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/drivers/me/bookings');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode([
            {
              'id': bookingGuid,
              'rideId': rideGuid,
              'passengerName': 'Passenger',
              'seats': 1,
              'fareTotal': 350,
              'pickupTime': '2026-11-22T08:00:00Z',
              'departureTime': '2026-11-22T08:00:00Z',
              'status': 'Pending',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final bookings = await ApiBookingRepository(
      client,
    ).getDriverBookings('driver@example.com');

    expect(bookings, hasLength(1));
    expect(bookings.single.status, BookingStatus.pending);
    expect(bookings.single.id, ApiIdMapper.toInt(bookingGuid));
  });

  test(
    'ride requests and bookings interpret timezone-free times as Pakistan time',
    () async {
      final rideGuid = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
      ApiIdMapper.remember(903, rideGuid);
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (request.url.path.endsWith('/ride-requests')) {
            expect(body['requestedTime'], '2026-11-21T22:15:00.000Z');
            return http.Response(
              jsonEncode({
                'id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
                'pickup': 'Gulshan',
                'destination': 'SMIU',
                'requestedTime': '2026-11-21T22:15:00Z',
                'seats': 1,
                'status': 'Open',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/bookings')) {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/bookings');
            expect(request.headers['Authorization'], 'Bearer test-token');
            expect(body['rideId'], rideGuid);
            expect(body['seats'], 1);
            expect(body['pickupTime'], '2026-11-21T22:15:00.000Z');
            return http.Response(
              jsonEncode({
                'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
                'rideId': rideGuid,
                'seats': 1,
                'fareTotal': 350,
                'pickupTime': '2026-11-21T22:15:00Z',
                'departureTime': '2026-11-21T22:00:00Z',
                'status': 'Pending',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );

      await ApiRideRepository(client).createPassengerRideRequest(
        passengerEmail: 'passenger@example.com',
        passengerName: 'Passenger',
        pickup: 'Gulshan',
        destination: 'SMIU',
        time: '2026-11-22 03:15',
        seats: 1,
      );
      final booking = await ApiBookingRepository(client).createBooking(
        rideId: 903,
        passengerEmail: 'passenger@example.com',
        passengerName: 'Passenger',
        seats: 1,
        pickupTime: '2026-11-22 03:15',
        totalFare: 350,
      );
      expect(booking.status, BookingStatus.pending);
    },
  );

  test(
    'ride request cancellation and complaint creation use backend routes',
    () async {
      var sawCancel = false;
      var sawComplaint = false;
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/cancel')) {
            sawCancel = true;
            return http.Response(
              jsonEncode({
                'id': '33333333-3333-3333-3333-333333333333',
                'status': 'Cancelled',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/complaints')) {
            sawComplaint = true;
            return http.Response(
              jsonEncode({
                'id': '44444444-4444-4444-4444-444444444444',
                'rideId': null,
                'description': 'Unsafe pickup',
                'status': 'Open',
                'createdAt': '2026-11-20T08:00:00Z',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );

      ApiIdMapper.remember(123, '33333333-3333-3333-3333-333333333333');
      await ApiRideRepository(client).cancelPassengerRideRequest(123);

      final complaint = await ApiSafetyRepository(client).submitComplaint(
        reporterEmail: 'passenger@example.com',
        reporterName: 'Passenger',
        rideId: 0,
        rideRoute: '',
        driverEmail: '',
        description: 'Unsafe pickup',
      );

      expect(sawCancel, isTrue);
      expect(sawComplaint, isTrue);
      expect(complaint.description, 'Unsafe pickup');
    },
  );

  test('driver ride create and availability use backend routes', () async {
    var sawRideCreate = false;
    var sawAvailability = false;
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/rides')) {
          sawRideCreate = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['pickup'], 'Gulshan');
          expect(body['destination'], 'SMIU');
          expect(body['totalSeats'], 3);
          expect(body['departureTime'], '2026-11-20T03:00:00.000Z');
          return http.Response(
            jsonEncode({
              'id': '55555555-5555-5555-5555-555555555555',
              'driverName': 'Sana Malik',
              'pickup': 'Gulshan',
              'destination': 'SMIU',
              'departureTime': '2026-11-20T08:00:00Z',
              'farePerSeat': 350,
              'totalSeats': 3,
              'seatsAvailable': 3,
              'status': 'Active',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PATCH' &&
            request.url.path.endsWith('/drivers/me/availability')) {
          sawAvailability = true;
          expect(jsonDecode(request.body), {'isOnline': true});
          return http.Response(
            jsonEncode({'isOnline': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );

    final repository = ApiRideRepository(client);
    final ride = await repository.publishDriverRide(
      driverEmail: 'sana@example.com',
      driverName: 'Sana Malik',
      from: 'Gulshan',
      to: 'SMIU',
      departureAt: DateTime(2026, 11, 20),
      departureTime: '8:00 AM',
      farePerSeat: 350,
      seatsTotal: 3,
      vehicleInfo: 'Suzuki',
      vehiclePlate: 'BCA-412',
    );
    await repository.setDriverOnline('sana@example.com', true);

    expect(ride.from, 'Gulshan');
    expect(sawRideCreate, isTrue);
    expect(sawAvailability, isTrue);
  });

  test('ride create and update serialize Pakistan time as UTC', () async {
    final rideGuid = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    ApiIdMapper.remember(902, rideGuid);

    for (final date in [DateTime(2026, 11, 22), DateTime.utc(2026, 11, 22)]) {
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['departureTime'], '2026-11-21T22:00:00.000Z');
          return http.Response(
            jsonEncode({
              'id': rideGuid,
              'pickup': 'Gulshan',
              'destination': 'SMIU',
              'departureTime': '2026-11-21T22:00:00Z',
              'farePerSeat': 350,
              'totalSeats': 3,
              'seatsAvailable': 3,
              'status': 'Active',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = ApiRideRepository(client);

      await repository.publishDriverRide(
        driverEmail: 'sana@example.com',
        driverName: 'Sana Malik',
        from: 'Gulshan',
        to: 'SMIU',
        departureAt: date,
        departureTime: '3:00 AM',
        farePerSeat: 350,
        seatsTotal: 3,
        vehicleInfo: 'Suzuki',
        vehiclePlate: 'BCA-412',
      );
      await repository.updateDriverRide(
        rideId: 902,
        driverEmail: 'sana@example.com',
        from: 'Gulshan',
        to: 'SMIU',
        departureAt: date,
        departureTime: '3:00 AM',
        farePerSeat: 350,
        seatsTotal: 3,
        notes: '',
      );
    }
  });

  test(
    'driver booking transition and ride offer send backend payloads',
    () async {
      BookingStatus? transitionStatus;
      Map<String, dynamic>? offerPayload;
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          if (request.method == 'PATCH' &&
              request.url.path.contains('/bookings/') &&
              request.url.path.endsWith('/status')) {
            transitionStatus = BookingStatus.fromCode(
              jsonDecode(request.body)['status'],
            );
            return http.Response(
              jsonEncode({
                'bookingId': '66666666-6666-6666-6666-666666666666',
                'status': 'Active',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/offers')) {
            offerPayload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'rideId': '77777777-7777-7777-7777-777777777777',
                'bookingId': '88888888-8888-8888-8888-888888888888',
                'status': 'Accepted',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );

      ApiIdMapper.remember(501, '66666666-6666-6666-6666-666666666666');
      ApiIdMapper.remember(601, '99999999-9999-9999-9999-999999999999');
      final repository = ApiBookingRepository(client);
      await repository.updateDriverBookingStatus(
        bookingId: 501,
        driverEmail: 'sana@example.com',
        status: BookingStatus.active,
      );
      await repository.offerRideForPassengerRequest(
        requestId: 601,
        driverEmail: 'sana@example.com',
        driverName: 'Sana Malik',
        farePerSeat: 350,
        seatsOffered: 3,
        vehicleSeatCapacity: 3,
        vehicleInfo: 'Suzuki',
        vehiclePlate: 'BCA-412',
      );

      expect(transitionStatus, BookingStatus.active);
      expect(offerPayload?['totalSeats'], 3);
      expect(offerPayload?['farePerSeat'], 350);
    },
  );
}
