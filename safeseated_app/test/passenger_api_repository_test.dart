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
