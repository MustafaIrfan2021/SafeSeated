class Ride {
  final int id;
  final String driverEmail;
  final String driverName;
  final String from;
  final String to;
  final DateTime departureAt;
  final String departureTime;
  final int farePerSeat;
  final int seatsTotal;
  final int seatsBooked;
  final String notes;
  final bool isActive;
  final String vehicleInfo;
  final String vehiclePlate;
  final double driverRating;
  final int driverReviewCount;
  final bool isDriverVerified;

  const Ride({
    required this.id,
    required this.driverEmail,
    required this.driverName,
    required this.from,
    required this.to,
    required this.departureAt,
    required this.departureTime,
    required this.farePerSeat,
    required this.seatsTotal,
    this.seatsBooked = 0,
    this.notes = '',
    this.isActive = true,
    required this.vehicleInfo,
    required this.vehiclePlate,
    this.driverRating = 5.0,
    this.driverReviewCount = 0,
    this.isDriverVerified = true,
  });

  int get seatsAvailable => (seatsTotal - seatsBooked).clamp(0, seatsTotal);
  bool get isFull => seatsAvailable <= 0;

  Ride copyWith({
    int? id,
    String? driverEmail,
    String? driverName,
    String? from,
    String? to,
    DateTime? departureAt,
    String? departureTime,
    int? farePerSeat,
    int? seatsTotal,
    int? seatsBooked,
    String? notes,
    bool? isActive,
    String? vehicleInfo,
    String? vehiclePlate,
    double? driverRating,
    int? driverReviewCount,
    bool? isDriverVerified,
  }) {
    return Ride(
      id: id ?? this.id,
      driverEmail: driverEmail ?? this.driverEmail,
      driverName: driverName ?? this.driverName,
      from: from ?? this.from,
      to: to ?? this.to,
      departureAt: departureAt ?? this.departureAt,
      departureTime: departureTime ?? this.departureTime,
      farePerSeat: farePerSeat ?? this.farePerSeat,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverRating: driverRating ?? this.driverRating,
      driverReviewCount: driverReviewCount ?? this.driverReviewCount,
      isDriverVerified: isDriverVerified ?? this.isDriverVerified,
    );
  }
}
