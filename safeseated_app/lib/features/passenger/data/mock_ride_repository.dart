import '../domain/models/ride.dart';
import '../domain/models/ride_request.dart';
import '../domain/repositories/ride_repository.dart';

DateTime _departureDate(int daysFromNow) {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day + daysFromNow);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class MockRideRepository implements RideRepository {
  final Set<String> _offlineDrivers = {};
  final List<Ride> _rides = [
    Ride(
      id: 1,
      driverEmail: 'sana@safeseated.pk',
      driverName: 'Sana Malik',
      from: 'Gulshan-e-Iqbal',
      to: 'SMIU, Shahrah-e-Faisal',
      departureAt: _departureDate(1),
      departureTime: '8:00 AM',
      farePerSeat: 350,
      seatsTotal: 3,
      seatsBooked: 1,
      vehicleInfo: 'Suzuki Alto VXR · Silver',
      vehiclePlate: 'BCA-412',
      driverRating: 4.9,
      driverReviewCount: 14,
      isDriverVerified: true,
    ),
    Ride(
      id: 2,
      driverEmail: 'hina@safeseated.pk',
      driverName: 'Hina Raza',
      from: 'Clifton',
      to: 'SMIU, Shahrah-e-Faisal',
      departureAt: _departureDate(1),
      departureTime: '8:30 AM',
      farePerSeat: 400,
      seatsTotal: 2,
      seatsBooked: 1,
      vehicleInfo: 'Honda City 1.2 · White',
      vehiclePlate: 'KHI-789',
      driverRating: 4.8,
      driverReviewCount: 9,
      isDriverVerified: true,
    ),
    Ride(
      id: 3,
      driverEmail: 'sana@safeseated.pk',
      driverName: 'Sana Malik',
      from: 'DHA Phase 5',
      to: 'SMIU, Shahrah-e-Faisal',
      departureAt: _departureDate(2),
      departureTime: '9:00 AM',
      farePerSeat: 450,
      seatsTotal: 3,
      seatsBooked: 0,
      vehicleInfo: 'Suzuki Alto VXR · Silver',
      vehiclePlate: 'BCA-412',
      driverRating: 4.9,
      driverReviewCount: 14,
      isDriverVerified: true,
    ),
    Ride(
      id: 4,
      driverEmail: 'hina@safeseated.pk',
      driverName: 'Hina Raza',
      from: 'North Nazimabad',
      to: 'SMIU, Shahrah-e-Faisal',
      departureAt: _departureDate(1),
      departureTime: '7:45 AM',
      farePerSeat: 300,
      seatsTotal: 3,
      seatsBooked: 1,
      vehicleInfo: 'Honda City 1.2 · White',
      vehiclePlate: 'KHI-789',
      driverRating: 4.8,
      driverReviewCount: 9,
      isDriverVerified: true,
    ),
    Ride(
      id: 5,
      driverEmail: 'sana@safeseated.pk',
      driverName: 'Sana Malik',
      from: 'Gulistan-e-Jauhar',
      to: 'NED University / KU',
      departureAt: _departureDate(3),
      departureTime: '8:15 AM',
      farePerSeat: 280,
      seatsTotal: 3,
      seatsBooked: 0,
      vehicleInfo: 'Suzuki Alto VXR · Silver',
      vehiclePlate: 'BCA-412',
      driverRating: 4.9,
      driverReviewCount: 14,
      isDriverVerified: true,
    ),
  ];

  final List<PassengerRideRequest> _requests = [
    const PassengerRideRequest(
      id: 101,
      passengerEmail: 'ayesha@smiu.edu.pk',
      passengerName: 'Ayesha Khan',
      pickup: 'Gulistan-e-Jauhar Block 13',
      destination: 'SMIU, Shahrah-e-Faisal',
      time: '8:10 AM',
      seats: 1,
      status: PassengerRideRequestStatus.open,
    ),
  ];

  @override
  Future<List<Ride>> getAvailableRides({
    String? pickupQuery,
    String? destinationQuery,
    DateTime? departureDate,
    int seatsNeeded = 1,
  }) async {
    if (seatsNeeded < 1) {
      throw ArgumentError.value(
        seatsNeeded,
        'seatsNeeded',
        'Must be at least one',
      );
    }
    await Future.delayed(const Duration(milliseconds: 250));
    final p = pickupQuery?.trim().toLowerCase() ?? '';
    final d = destinationQuery?.trim().toLowerCase() ?? '';

    return _rides.where((ride) {
      final matchesPickup = p.isEmpty || ride.from.toLowerCase().contains(p);
      final matchesDest = d.isEmpty || ride.to.toLowerCase().contains(d);
      final matchesDate =
          departureDate == null ||
          (ride.departureAt.year == departureDate.year &&
              ride.departureAt.month == departureDate.month &&
              ride.departureAt.day == departureDate.day);
      return ride.isActive &&
          !_offlineDrivers.contains(ride.driverEmail.toLowerCase()) &&
          matchesPickup &&
          matchesDest &&
          matchesDate &&
          ride.seatsAvailable >= seatsNeeded;
    }).toList();
  }

  @override
  Future<Ride?> getRideById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _rides.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    return _rides[index];
  }

  @override
  Future<List<PassengerRideRequest>> getPassengerRideRequests(
    String passengerEmail,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests
        .where(
          (r) => r.passengerEmail.toLowerCase() == passengerEmail.toLowerCase(),
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
    if (pickup.trim().isEmpty ||
        destination.trim().isEmpty ||
        time.trim().isEmpty) {
      throw ArgumentError('Pickup, destination and time are required.');
    }
    if (seats < 1 || seats > 4) {
      throw ArgumentError.value(seats, 'seats', 'Must be between 1 and 4');
    }
    await Future.delayed(const Duration(milliseconds: 300));
    final newReq = PassengerRideRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      passengerEmail: passengerEmail,
      passengerName: passengerName,
      pickup: pickup.trim(),
      destination: destination.trim(),
      time: time.trim(),
      seats: seats,
      status: PassengerRideRequestStatus.open,
    );
    _requests.insert(0, newReq);
    return newReq;
  }

  @override
  Future<void> cancelPassengerRideRequest(int requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      throw StateError('Ride request $requestId was not found.');
    }
    if (!_requests[index].isOpen) {
      throw StateError('Only open ride requests can be cancelled.');
    }
    _requests[index] = _requests[index].copyWith(
      status: PassengerRideRequestStatus.cancelled,
    );
  }

  @override
  Future<List<Ride>> getDriverRides(String driverEmail) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _rides
        .where(
          (ride) => ride.driverEmail.toLowerCase() == driverEmail.toLowerCase(),
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
    _validateRide(
      from: from,
      to: to,
      departureAt: departureAt,
      departureTime: departureTime,
      farePerSeat: farePerSeat,
      seatsTotal: seatsTotal,
      vehiclePlate: vehiclePlate,
    );
    if (driverEmail.trim().isEmpty ||
        driverName.trim().isEmpty ||
        vehicleInfo.trim().isEmpty) {
      throw ArgumentError('Driver and vehicle details are required.');
    }
    if (!await isDriverOnline(driverEmail)) {
      throw StateError('Go online before publishing a ride.');
    }
    await Future.delayed(const Duration(milliseconds: 250));
    final ride = Ride(
      id: DateTime.now().microsecondsSinceEpoch,
      driverEmail: driverEmail.trim().toLowerCase(),
      driverName: driverName.trim(),
      from: from.trim(),
      to: to.trim(),
      departureAt: _dateOnly(departureAt),
      departureTime: departureTime.trim(),
      farePerSeat: farePerSeat,
      seatsTotal: seatsTotal,
      vehicleInfo: vehicleInfo.trim(),
      vehiclePlate: vehiclePlate.trim(),
      notes: notes.trim(),
    );
    _rides.insert(0, ride);
    return ride;
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
    final index = _rides.indexWhere((ride) => ride.id == rideId);
    if (index == -1) throw StateError('Ride $rideId was not found.');
    final ride = _rides[index];
    if (ride.driverEmail.toLowerCase() != driverEmail.toLowerCase()) {
      throw StateError('This ride belongs to another driver.');
    }
    if (!ride.isActive) throw StateError('Cancelled rides cannot be edited.');
    _validateRide(
      from: from,
      to: to,
      departureAt: departureAt,
      departureTime: departureTime,
      farePerSeat: farePerSeat,
      seatsTotal: seatsTotal,
      vehiclePlate: ride.vehiclePlate,
    );
    if (seatsTotal < ride.seatsBooked) {
      throw StateError(
        'Seat capacity cannot be less than already booked seats.',
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final updated = ride.copyWith(
      from: from.trim(),
      to: to.trim(),
      departureAt: _dateOnly(departureAt),
      departureTime: departureTime.trim(),
      farePerSeat: farePerSeat,
      seatsTotal: seatsTotal,
      notes: notes.trim(),
    );
    _rides[index] = updated;
    return updated;
  }

  @override
  Future<void> cancelDriverRide(int rideId, String driverEmail) async {
    final index = _rides.indexWhere((ride) => ride.id == rideId);
    if (index == -1) throw StateError('Ride $rideId was not found.');
    final ride = _rides[index];
    if (ride.driverEmail.toLowerCase() != driverEmail.toLowerCase()) {
      throw StateError('This ride belongs to another driver.');
    }
    if (!ride.isActive) {
      throw StateError('This ride has already been cancelled.');
    }
    if (ride.seatsBooked > 0) {
      throw StateError('Rides with confirmed passengers cannot be cancelled.');
    }
    _rides[index] = ride.copyWith(isActive: false);
  }

  @override
  Future<void> reserveRideSeats(int rideId, int seats) async {
    final index = _rides.indexWhere((ride) => ride.id == rideId);
    if (index == -1) throw StateError('Ride $rideId was not found.');
    final ride = _rides[index];
    if (!ride.isActive) throw StateError('This ride is no longer available.');
    if (_offlineDrivers.contains(ride.driverEmail.toLowerCase())) {
      throw StateError('This driver is offline.');
    }
    if (seats < 1 || seats > ride.seatsAvailable) {
      throw StateError('Not enough seats remain on this ride.');
    }
    _rides[index] = ride.copyWith(seatsBooked: ride.seatsBooked + seats);
  }

  @override
  Future<void> releaseRideSeats(int rideId, int seats) async {
    final index = _rides.indexWhere((ride) => ride.id == rideId);
    if (index == -1) throw StateError('Ride $rideId was not found.');
    final ride = _rides[index];
    if (seats < 1 || seats > ride.seatsBooked) {
      throw StateError('Cannot release more seats than are reserved.');
    }
    _rides[index] = ride.copyWith(seatsBooked: ride.seatsBooked - seats);
  }

  @override
  Future<List<PassengerRideRequest>> getOpenPassengerRideRequests() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((request) => request.isOpen).toList(growable: false);
  }

  @override
  Future<void> fulfillPassengerRideRequest(
    int requestId,
    String driverEmail,
    String driverName,
  ) async {
    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      throw StateError('Passenger request $requestId was not found.');
    }
    if (!_requests[index].isOpen) {
      throw StateError('This passenger request is no longer open.');
    }
    if (!await isDriverOnline(driverEmail)) {
      throw StateError('Go online before responding to passenger requests.');
    }
    _requests[index] = _requests[index].copyWith(
      status: PassengerRideRequestStatus.accepted,
      driverEmail: driverEmail,
      driverName: driverName,
    );
  }

  @override
  Future<bool> isDriverOnline(String driverEmail) async {
    return !_offlineDrivers.contains(driverEmail.toLowerCase());
  }

  @override
  Future<void> setDriverOnline(String driverEmail, bool isOnline) async {
    if (driverEmail.trim().isEmpty) {
      throw ArgumentError.value(
        driverEmail,
        'driverEmail',
        'Must not be empty.',
      );
    }
    final email = driverEmail.toLowerCase();
    if (isOnline) {
      _offlineDrivers.remove(email);
    } else {
      _offlineDrivers.add(email);
    }
  }

  void _validateRide({
    required String from,
    required String to,
    required DateTime departureAt,
    required String departureTime,
    required int farePerSeat,
    required int seatsTotal,
    required String vehiclePlate,
  }) {
    if (from.trim().isEmpty ||
        to.trim().isEmpty ||
        departureTime.trim().isEmpty ||
        vehiclePlate.trim().isEmpty) {
      throw ArgumentError(
        'Route, departure time and vehicle plate are required.',
      );
    }
    if (from.trim().toLowerCase() == to.trim().toLowerCase()) {
      throw ArgumentError('Pickup and destination must be different.');
    }
    if (_dateOnly(departureAt).isBefore(_dateOnly(DateTime.now()))) {
      throw ArgumentError.value(
        departureAt,
        'departureAt',
        'Cannot be in the past.',
      );
    }
    if (farePerSeat < 1) {
      throw ArgumentError.value(
        farePerSeat,
        'farePerSeat',
        'Must be positive.',
      );
    }
    if (seatsTotal < 1 || seatsTotal > 4) {
      throw ArgumentError.value(
        seatsTotal,
        'seatsTotal',
        'Must be between 1 and 4.',
      );
    }
  }
}
