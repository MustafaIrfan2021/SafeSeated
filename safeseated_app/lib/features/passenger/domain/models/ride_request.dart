enum PassengerRideRequestStatus {
  open('open', 'Waiting for driver'),
  accepted('accepted', 'Accepted'),
  cancelled('cancelled', 'Cancelled');

  final String code;
  final String label;

  const PassengerRideRequestStatus(this.code, this.label);
}

class PassengerRideRequest {
  final int id;
  final String passengerEmail;
  final String passengerName;
  final String pickup;
  final String destination;
  final String time;
  final int seats;
  final PassengerRideRequestStatus status;
  final String? driverEmail;
  final String? driverName;

  const PassengerRideRequest({
    required this.id,
    required this.passengerEmail,
    required this.passengerName,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.seats,
    this.status = PassengerRideRequestStatus.open,
    this.driverEmail,
    this.driverName,
  });

  bool get isOpen => status == PassengerRideRequestStatus.open;

  PassengerRideRequest copyWith({
    int? id,
    String? passengerEmail,
    String? passengerName,
    String? pickup,
    String? destination,
    String? time,
    int? seats,
    PassengerRideRequestStatus? status,
    String? driverEmail,
    String? driverName,
  }) {
    return PassengerRideRequest(
      id: id ?? this.id,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      passengerName: passengerName ?? this.passengerName,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      time: time ?? this.time,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      driverEmail: driverEmail ?? this.driverEmail,
      driverName: driverName ?? this.driverName,
    );
  }
}
