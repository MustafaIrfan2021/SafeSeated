class Complaint {
  final String id;
  final String reporterEmail;
  final String reporterName;
  final int rideId;
  final String rideRoute;
  final String driverEmail;
  final String description;
  final DateTime createdAt;
  final String status; // 'open', 'in review', 'resolved'

  const Complaint({
    required this.id,
    required this.reporterEmail,
    required this.reporterName,
    required this.rideId,
    required this.rideRoute,
    required this.driverEmail,
    required this.description,
    required this.createdAt,
    this.status = 'open',
  });
}
