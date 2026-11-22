import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_id_mapper.dart';
import '../../../core/utils/pakistan_time.dart';
import '../domain/models/ride.dart';
import '../domain/models/ride_request.dart';
import '../domain/repositories/ride_repository.dart';

class ApiRideRepository implements RideRepository {
  ApiRideRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Ride>> getAvailableRides({
    String? pickupQuery,
    String? destinationQuery,
    DateTime? departureDate,
    int seatsNeeded = 1,
  }) async {
    final query = <String>[
      if (pickupQuery?.trim().isNotEmpty ?? false)
        'pickup=${Uri.encodeQueryComponent(pickupQuery!.trim())}',
      if (destinationQuery?.trim().isNotEmpty ?? false)
        'destination=${Uri.encodeQueryComponent(destinationQuery!.trim())}',
      if (departureDate != null)
        'date=${Uri.encodeComponent(DateFormat('yyyy-MM-dd').format(departureDate))}',
      'seats=$seatsNeeded',
      'page=1',
      'pageSize=100',
    ].join('&');

    final response = await _api.getJson('/rides?$query', authenticated: false);
    final items = response['data'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(
          (item) => _rideFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<Ride?> getRideById(int id) async {
    final guid = ApiIdMapper.toGuid(id);
    if (guid == null) return null;
    final data = await _api.getJson('/rides/$guid');
    return _rideFromJson(data);
  }

  @override
  Future<List<PassengerRideRequest>> getPassengerRideRequests(
    String passengerEmail,
  ) async {
    final items = await _api.getJsonList('/ride-requests/me');
    return items
        .whereType<Map>()
        .map(
          (item) => _rideRequestFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<PassengerRideRequest> createPassengerRideRequest({
    required String passengerEmail,
    required String passengerName,
    required String pickup,
    required String destination,
    required String time,
    required int seats,
  }) async {
    final requestedTime = PakistanTime.parseInput(time);
    if (requestedTime == null) {
      throw ArgumentError(
        'Enter a valid pickup date and time, for example 2026-11-20 08:15.',
      );
    }
    final response = await _api.postJson('/ride-requests', {
      'pickup': pickup.trim(),
      'destination': destination.trim(),
      'requestedTime': requestedTime.toIso8601String(),
      'seats': seats,
    });
    return _rideRequestFromJson(response);
  }

  @override
  Future<void> cancelPassengerRideRequest(int requestId) async {
    final guid = ApiIdMapper.toGuid(requestId);
    if (guid == null) {
      throw StateError('Ride request $requestId was not found.');
    }
    await _api.postJson('/ride-requests/$guid/cancel', {});
  }

  Ride _rideFromJson(Map<String, dynamic> json) {
    final guid = json['id']?.toString();
    final id = guid == null ? 0 : ApiIdMapper.toInt(guid);
    if (guid != null) ApiIdMapper.remember(id, guid);

    final departure =
        PakistanTime.parseUtc(json['departureTime']?.toString()) ??
        DateTime.now().toUtc();
    final pakistanDeparture = PakistanTime.toPakistan(departure);
    final totalSeats = _intValue(json['totalSeats'] ?? json['seatsOffered'], 1);
    final seatsAvailable = _intValue(json['seatsAvailable'], totalSeats);
    final fare = _numValue(
      json['farePerSeat'] ?? json['pricePerSeat'],
      0,
    ).round();

    return Ride(
      id: id,
      driverEmail: '',
      driverName: json['driverName']?.toString() ?? 'Driver',
      from: json['pickup']?.toString() ?? json['pickupArea']?.toString() ?? '',
      to: json['destination']?.toString() ?? '',
      departureAt: departure,
      departureTime: DateFormat('h:mm a').format(pakistanDeparture),
      farePerSeat: fare,
      seatsTotal: totalSeats,
      seatsBooked: (totalSeats - seatsAvailable).clamp(0, totalSeats),
      notes: json['notes']?.toString() ?? '',
      isActive:
          (json['status']?.toString().toLowerCase() ?? 'active') == 'active',
      vehicleInfo: json['vehicleMakeModel']?.toString() ?? 'Verified vehicle',
      vehiclePlate: json['plateNumber']?.toString() ?? '',
      driverRating: _numValue(json['driverRating'], 0).toDouble(),
      driverReviewCount: _intValue(json['driverTotalReviews'], 0),
      isDriverVerified: true,
    );
  }

  PassengerRideRequest _rideRequestFromJson(Map<String, dynamic> json) {
    final guid = json['id']?.toString();
    final id = guid == null ? 0 : ApiIdMapper.toInt(guid);
    if (guid != null) ApiIdMapper.remember(id, guid);

    final statusText = json['status']?.toString().toLowerCase() ?? 'open';
    final status = statusText == 'accepted'
        ? PassengerRideRequestStatus.accepted
        : statusText == 'cancelled'
        ? PassengerRideRequestStatus.cancelled
        : PassengerRideRequestStatus.open;
    final time =
        PakistanTime.parseUtc(json['requestedTime']?.toString()) ??
        DateTime.now().toUtc();
    final pakistanTime = PakistanTime.toPakistan(time);

    return PassengerRideRequest(
      id: id,
      passengerEmail: '',
      passengerName: json['passengerName']?.toString() ?? '',
      pickup: json['pickup']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      time: DateFormat('h:mm a').format(pakistanTime),
      seats: _intValue(json['seats'], 1),
      status: status,
    );
  }

  static int _intValue(Object? value, int fallback) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;

  static num _numValue(Object? value, num fallback) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? fallback;

  static DateTime _combineDateAndTime(DateTime date, String departureTime) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(departureTime.trim());
    var hour = 8;
    var minute = 0;
    if (match != null) {
      hour = int.parse(match.group(1)!);
      minute = int.parse(match.group(2)!);
      final suffix = match.group(3)?.toUpperCase();
      if (suffix == 'PM' && hour < 12) hour += 12;
      if (suffix == 'AM' && hour == 12) hour = 0;
    }
    return PakistanTime.fromPakistanWallClock(
      DateTime.utc(date.year, date.month, date.day, hour, minute),
    );
  }

  @override
  Future<List<Ride>> getDriverRides(String driverEmail) async {
    final items = await _api.getJsonList('/drivers/me/rides');
    return items
        .whereType<Map>()
        .map(
          (item) => _rideFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<Ride> publishDriverRide({
    required String driverEmail,
    required String driverName,
    required String from,
    required String to,
    required DateTime departureAt,
    required String departureTime,
    required int farePerSeat,
    required int seatsTotal,
    required String vehicleInfo,
    required String vehiclePlate,
    String notes = '',
  }) async {
    final departure = _combineDateAndTime(departureAt, departureTime);
    final data = await _api.postJson('/rides', {
      'pickup': from.trim(),
      'destination': to.trim(),
      'departureTime': departure.toUtc().toIso8601String(),
      'farePerSeat': farePerSeat,
      'totalSeats': seatsTotal,
      'notes': notes.trim(),
    });
    return _rideFromJson(data);
  }

  @override
  Future<Ride> updateDriverRide({
    required int rideId,
    required String driverEmail,
    required String from,
    required String to,
    required DateTime departureAt,
    required String departureTime,
    required int farePerSeat,
    required int seatsTotal,
    required String notes,
  }) async {
    final guid = ApiIdMapper.toGuid(rideId);
    if (guid == null) throw StateError('Ride $rideId was not found.');
    final departure = _combineDateAndTime(departureAt, departureTime);
    final data = await _api.patchJson('/rides/$guid', {
      'pickup': from.trim(),
      'destination': to.trim(),
      'departureTime': departure.toUtc().toIso8601String(),
      'farePerSeat': farePerSeat,
      'totalSeats': seatsTotal,
      'notes': notes,
    });
    return _rideFromJson(data);
  }

  @override
  Future<void> cancelDriverRide(int rideId, String driverEmail) async {
    final guid = ApiIdMapper.toGuid(rideId);
    if (guid == null) throw StateError('Ride $rideId was not found.');
    await _api.delete('/rides/$guid');
  }

  @override
  Future<void> reserveRideSeats(int rideId, int seats) =>
      throw UnimplementedError();
  @override
  Future<void> releaseRideSeats(int rideId, int seats) =>
      throw UnimplementedError();
  @override
  Future<List<PassengerRideRequest>> getOpenPassengerRideRequests() async {
    final items = await _api.getJsonList('/ride-requests/open');
    return items
        .whereType<Map>()
        .map(
          (item) => _rideRequestFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<void> fulfillPassengerRideRequest(
    int requestId,
    String driverEmail,
    String driverName,
  ) => throw UnimplementedError();
  @override
  Future<bool> isDriverOnline(String driverEmail) async {
    final data = await _api.getJson('/me');
    final profile = data['driverProfile'];
    return profile is Map && profile['isOnline'] == true;
  }

  @override
  Future<void> setDriverOnline(String driverEmail, bool isOnline) async {
    await _api.patchJson('/drivers/me/availability', {'isOnline': isOnline});
  }
}
