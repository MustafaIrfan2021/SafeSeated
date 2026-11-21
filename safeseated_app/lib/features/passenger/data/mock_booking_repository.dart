import '../domain/models/booking.dart';
import '../domain/models/chat_message.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/repositories/ride_repository.dart';

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this._rideRepository);

  final RideRepository _rideRepository;
  final List<Booking> _bookings = [
    const Booking(
      id: 1,
      rideId: 4,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      status: BookingStatus.pending,
      date: 'Today',
      seats: 1,
      pickupTime: '7:45 AM',
      totalFare: 300,
    ),
    const Booking(
      id: 2,
      rideId: 2,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      status: BookingStatus.accepted,
      date: 'Tomorrow',
      seats: 1,
      pickupTime: '8:20 AM',
      totalFare: 400,
    ),
    const Booking(
      id: 3,
      rideId: 3,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      status: BookingStatus.rejected,
      date: 'Monday',
      seats: 1,
      pickupTime: '9:00 AM',
      totalFare: 450,
    ),
    const Booking(
      id: 4,
      rideId: 1,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      status: BookingStatus.completed,
      date: 'Yesterday',
      seats: 1,
      pickupTime: '8:00 AM',
      totalFare: 350,
      rating: null,
      reviewText: null,
    ),
    const Booking(
      id: 5,
      rideId: 3,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      status: BookingStatus.completed,
      date: 'Last Friday',
      seats: 1,
      pickupTime: '9:00 AM',
      totalFare: 450,
      rating: 5,
      reviewText: 'Very safe, clean vehicle and very punctual driving.',
    ),
  ];

  final List<ChatMessage> _messages = [
    const ChatMessage(
      bookingId: 2,
      fromEmail: 'hina@safeseated.pk',
      text:
          'Assalam o Alaikum Ayesha! I will reach your Clifton pickup point at 8:20 AM.',
      time: '8:05 AM',
    ),
    const ChatMessage(
      bookingId: 2,
      fromEmail: 'ayesha@smiu.edu.pk',
      text:
          'Walaikum Assalam Hina. Perfect, I will be waiting near the main gate.',
      time: '8:07 AM',
    ),
  ];

  @override
  Future<List<Booking>> getBookings(
    String passengerEmail, {
    BookingStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings.where((b) {
      final matchesUser =
          b.passengerEmail.toLowerCase() == passengerEmail.toLowerCase();
      final matchesStatus = status == null || b.status == status;
      return matchesUser && matchesStatus;
    }).toList();
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) return null;
    return _bookings[index];
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
    if (seats < 1) {
      throw ArgumentError.value(seats, 'seats', 'Must be at least one');
    }
    if (pickupTime.trim().isEmpty || totalFare < 1) {
      throw ArgumentError('Pickup time and a positive fare are required.');
    }
    final ride = await _rideRepository.getRideById(rideId);
    if (ride == null || !ride.isActive) {
      throw StateError('This ride is no longer available.');
    }
    if (seats > ride.seatsAvailable) {
      throw StateError('Not enough seats remain on this ride.');
    }
    if (passengerEmail.trim().isEmpty || passengerName.trim().isEmpty) {
      throw ArgumentError('Passenger identity is required.');
    }
    if (totalFare != ride.farePerSeat * seats) {
      throw ArgumentError.value(
        totalFare,
        'totalFare',
        'Must match the current ride fare and seat count.',
      );
    }
    final hasActiveRequest = _bookings.any(
      (booking) =>
          booking.rideId == rideId &&
          booking.passengerEmail.toLowerCase() ==
              passengerEmail.toLowerCase() &&
          (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.accepted ||
              booking.status == BookingStatus.active),
    );
    if (hasActiveRequest) {
      throw StateError('You already have an active request for this ride.');
    }
    await Future.delayed(const Duration(milliseconds: 300));
    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch,
      rideId: rideId,
      passengerEmail: passengerEmail,
      passengerName: passengerName,
      status: BookingStatus.pending,
      date: 'Today',
      seats: seats,
      pickupTime: pickupTime,
      totalFare: totalFare,
    );
    _bookings.insert(0, newBooking);
    return newBooking;
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
    final requests = (await _rideRepository.getOpenPassengerRideRequests())
        .where((item) => item.id == requestId)
        .toList();
    if (requests.isEmpty) {
      throw StateError('This passenger request is no longer open.');
    }
    final request = requests.first;
    if (farePerSeat < 1) {
      throw ArgumentError.value(
        farePerSeat,
        'farePerSeat',
        'Must be positive.',
      );
    }
    if (seatsOffered < request.seats) {
      throw ArgumentError.value(
        seatsOffered,
        'seatsOffered',
        'Offer at least ${request.seats} seat(s).',
      );
    }
    if (vehicleSeatCapacity < 1 ||
        vehicleSeatCapacity > 4 ||
        seatsOffered > vehicleSeatCapacity) {
      throw ArgumentError.value(
        seatsOffered,
        'seatsOffered',
        'Offer no more than your registered vehicle capacity.',
      );
    }
    if (driverEmail.trim().isEmpty ||
        driverName.trim().isEmpty ||
        vehicleInfo.trim().isEmpty ||
        vehiclePlate.trim().isEmpty) {
      throw ArgumentError('Driver and vehicle details are required.');
    }
    if (!await _rideRepository.isDriverOnline(driverEmail)) {
      throw StateError('Go online before responding to passenger requests.');
    }

    final ride = await _rideRepository.publishDriverRide(
      driverEmail: driverEmail,
      driverName: driverName,
      from: request.pickup,
      to: request.destination,
      departureAt: DateTime.now(),
      departureTime: request.time,
      farePerSeat: farePerSeat,
      seatsTotal: seatsOffered,
      vehicleInfo: vehicleInfo,
      vehiclePlate: vehiclePlate,
    );
    var seatsReserved = false;
    try {
      await _rideRepository.reserveRideSeats(ride.id, request.seats);
      seatsReserved = true;
      await _rideRepository.fulfillPassengerRideRequest(
        requestId,
        driverEmail,
        driverName,
      );
    } catch (error) {
      if (seatsReserved) {
        await _rideRepository.releaseRideSeats(ride.id, request.seats);
      }
      await _rideRepository.cancelDriverRide(ride.id, driverEmail);
      rethrow;
    }

    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch,
      rideId: ride.id,
      passengerEmail: request.passengerEmail,
      passengerName: request.passengerName,
      status: BookingStatus.accepted,
      date: 'Today',
      seats: request.seats,
      pickupTime: request.time,
      totalFare: farePerSeat * request.seats,
    );
    _bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<List<Booking>> getDriverBookings(
    String driverEmail, {
    BookingStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final results = <Booking>[];
    for (final booking in _bookings) {
      if (status != null && booking.status != status) continue;
      final ride = await _rideRepository.getRideById(booking.rideId);
      if (ride?.driverEmail.toLowerCase() == driverEmail.toLowerCase()) {
        results.add(booking);
      }
    }
    return results;
  }

  @override
  Future<void> updateDriverBookingStatus({
    required int bookingId,
    required String driverEmail,
    required BookingStatus status,
  }) async {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) throw StateError('Booking $bookingId was not found.');
    final booking = _bookings[index];
    final ride = await _rideRepository.getRideById(booking.rideId);
    if (ride == null ||
        ride.driverEmail.toLowerCase() != driverEmail.toLowerCase()) {
      throw StateError('This booking does not belong to this driver.');
    }
    switch ((booking.status, status)) {
      case (BookingStatus.pending, BookingStatus.accepted):
        await _rideRepository.reserveRideSeats(booking.rideId, booking.seats);
      case (BookingStatus.pending, BookingStatus.rejected):
        break;
      case (BookingStatus.accepted, BookingStatus.active):
        break;
      case (BookingStatus.active, BookingStatus.completed):
        break;
      default:
        throw StateError(
          'Cannot change booking from ${booking.status.code} to ${status.code}.',
        );
    }
    _bookings[index] = booking.copyWith(status: status);
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) {
      throw StateError('Booking $bookingId was not found.');
    }
    if (_bookings[idx].status != BookingStatus.pending) {
      throw StateError('Only pending booking requests can be cancelled.');
    }
    _bookings[idx] = _bookings[idx].copyWith(status: BookingStatus.cancelled);
  }

  @override
  Future<void> rateDriver({
    required int bookingId,
    required int rating,
    required String reviewText,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) {
      throw StateError('Booking $bookingId was not found.');
    }
    if (_bookings[idx].status != BookingStatus.completed) {
      throw StateError('Only completed trips can be rated.');
    }
    if (_bookings[idx].rating != null) {
      throw StateError('This trip has already been rated.');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
    _bookings[idx] = _bookings[idx].copyWith(
      rating: rating,
      reviewText: reviewText.trim(),
    );
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _messages.where((m) => m.bookingId == bookingId).toList();
  }

  @override
  Future<ChatMessage> sendChatMessage({
    required int bookingId,
    required String fromEmail,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final msg = ChatMessage(
      bookingId: bookingId,
      fromEmail: fromEmail,
      text: text.trim(),
      time: 'Just now',
    );
    _messages.add(msg);
    return msg;
  }
}
