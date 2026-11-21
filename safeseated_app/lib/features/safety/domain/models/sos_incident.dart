class SosIncident {
  final String id;
  final String reporterEmail;
  final String reporterName;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime timestamp;
  final String status;
  final String? location;

  const SosIncident({
    required this.id,
    required this.reporterEmail,
    required this.reporterName,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.timestamp,
    this.status = 'active',
    this.location,
  });
}
