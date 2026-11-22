class SosIncident {
  final String id;
  final String role;
  final DateTime timestamp;
  final String status;
  final double? latitude;
  final double? longitude;
  final int? rideId;

  const SosIncident({
    required this.id,
    required this.role,
    required this.timestamp,
    required this.status,
    this.latitude,
    this.longitude,
    this.rideId,
  });
}
