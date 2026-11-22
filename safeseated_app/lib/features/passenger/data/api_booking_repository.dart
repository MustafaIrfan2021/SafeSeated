import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_id_mapper.dart';
import '../../../core/utils/pakistan_time.dart';
import '../domain/models/booking.dart';
import '../domain/models/chat_message.dart';
import '../domain/repositories/booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Booking>> getBookings(
    String passengerEmail, {
    BookingStatus? status,
  }) async {
    final statusQuery = status == null
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.code)}';
    final items = await _api.getJsonList('/bookings/me$statusQuery');
    return items
        .whereType<Map>()
        .map(
          (item) => _bookingFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    final guid = ApiIdMapper.toGuid(id);
    if (guid == null) return null;
    final data = await _api.getJson('/bookings/$guid');
    return _bookingFromJson(data);
  }

  @override
  Future<Booking> createBooking({
    required int rideId,
    required String passengerEmail,
    required String passengerName,
    required int seats,
    required String pickupTime,
    required int totalFare,
  }) async {
    final rideGuid = ApiIdMapper.toGuid(rideId);
    if (rideGuid == null) throw ArgumentError('Ride ID is invalid.');

    final pickup = PakistanTime.parseInput(pickupTime);
    final data = await _api.postJson('/bookings', {
      'rideId': rideGuid,
      'seats': seats,
      if (pickup != null) 'pickupTime': pickup.toIso8601String(),
    });
    return _bookingFromJson(data);
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    final guid = ApiIdMapper.toGuid(bookingId);
    if (guid == null) throw StateError('Booking $bookingId was not found.');
    await _api.patchJson('/bookings/$guid/status', {'status': 'Cancelled'});
  }

  @override
  Future<void> rateDriver({
    required int bookingId,
    required int rating,
    required String reviewText,
  }) async {
    final guid = ApiIdMapper.toGuid(bookingId);
    if (guid == null) throw StateError('Booking $bookingId was not found.');
    await _api.postJson('/bookings/$guid/review', {
      'rating': rating,
      'review': reviewText,
    });
  }

  Booking _bookingFromJson(Map<String, dynamic> json) {
    final bookingGuid = json['id']?.toString();
    final rideGuid = json['rideId']?.toString();
    final bookingId = bookingGuid == null ? 0 : ApiIdMapper.toInt(bookingGuid);
    if (bookingGuid != null) ApiIdMapper.remember(bookingId, bookingGuid);
    final rideId = rideGuid == null ? 0 : ApiIdMapper.toInt(rideGuid);
    if (rideGuid != null) ApiIdMapper.remember(rideId, rideGuid);

    final status = BookingStatus.fromCode(
      json['status']?.toString() ?? 'pending',
    );
    final departureTime = PakistanTime.parseUtc(
      json['departureTime']?.toString(),
    );
    final travelDate =
        json['travelDate']?.toString() ?? json['departureTime']?.toString();
    final date =
        departureTime == null
            ? PakistanTime.parseUtc(travelDate)
            : PakistanTime.toPakistan(departureTime);
    final pickupTime =
        PakistanTime.parseUtc(json['pickupTime']?.toString()) ??
        departureTime;

    return Booking(
      id: bookingId,
      rideId: rideId,
      passengerEmail: '',
      passengerName: json['passengerName']?.toString() ?? 'Passenger',
      status: status,
      date: date == null
          ? 'Trip date unavailable'
          : DateFormat('EEE, d MMM').format(date),
      seats: _intValue(json['seats'] ?? json['seatsRequested'], 1),
      pickupTime: pickupTime == null
          ? '--'
          : DateFormat('h:mm a').format(PakistanTime.toPakistan(pickupTime)),
      totalFare: _intValue(json['fareTotal'], 0),
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : null,
      reviewText: json['review']?.toString(),
    );
  }

  static int _intValue(Object? value, int fallback) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;

  @override
  Future<List<Booking>> getDriverBookings(
    String driverEmail, {
    BookingStatus? status,
  }) async {
    final statusQuery = status == null
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.code)}';
    final items = await _api.getJsonList('/drivers/me/bookings$statusQuery');
    return items
        .whereType<Map>()
        .map(
          (item) => _bookingFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  @override
  Future<Booking> offerRideForPassengerRequest({
    required int requestId,
    required String driverEmail,
    required String driverName,
    required int farePerSeat,
    required int seatsOffered,
    required int vehicleSeatCapacity,
    required String vehicleInfo,
    required String vehiclePlate,
  }) async {
    final requestGuid = ApiIdMapper.toGuid(requestId);
    if (requestGuid == null) {
      throw StateError('Ride request $requestId was not found.');
    }
    final data = await _api.postJson('/ride-requests/$requestGuid/offers', {
      'totalSeats': seatsOffered,
      'farePerSeat': farePerSeat,
    });
    final rideGuid = data['rideId']?.toString();
    final bookingGuid = data['bookingId']?.toString();
    if (rideGuid == null || bookingGuid == null) {
      throw const FormatException(
        'The ride offer response did not include ride and booking IDs.',
      );
    }
    final rideId = ApiIdMapper.toInt(rideGuid);
    final bookingId = ApiIdMapper.toInt(bookingGuid);
    ApiIdMapper.remember(rideId, rideGuid);
    ApiIdMapper.remember(bookingId, bookingGuid);
    return Booking(
      id: bookingId,
      rideId: rideId,
      passengerEmail: '',
      passengerName: 'Passenger',
      status: BookingStatus.accepted,
      date: 'Today',
      seats: 1,
      pickupTime: '--',
      totalFare: farePerSeat,
    );
  }

  @override
  Future<void> updateDriverBookingStatus({
    required int bookingId,
    required String driverEmail,
    required BookingStatus status,
  }) async {
    final guid = ApiIdMapper.toGuid(bookingId);
    if (guid == null) {
      throw StateError('Booking $bookingId was not found.');
    }
    await _api.patchJson('/bookings/$guid/status', {'status': status.code});
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int bookingId) =>
      throw UnimplementedError();
  @override
  Future<ChatMessage> sendChatMessage({
    required int bookingId,
    required String fromEmail,
    required String text,
  }) => throw UnimplementedError();
}
