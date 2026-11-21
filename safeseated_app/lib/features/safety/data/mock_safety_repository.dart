import '../domain/models/sos_incident.dart';
import '../domain/models/complaint.dart';
import '../domain/repositories/safety_repository.dart';

class MockSafetyRepository implements SafetyRepository {
  final List<SosIncident> _sosIncidents = [];
  final List<Complaint> _complaints = [
    Complaint(
      id: 'CMP-101',
      reporterEmail: 'ayesha@smiu.edu.pk',
      reporterName: 'Ayesha Khan',
      rideId: 1,
      rideRoute: 'Gulshan-e-Iqbal → SMIU',
      driverEmail: 'sana@safeseated.pk',
      description:
          'Driver arrived 15 minutes late at the pickup point without advance notice.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'in review',
    ),
  ];

  @override
  Future<SosIncident> triggerSos({
    required String reporterEmail,
    required String reporterName,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final incident = SosIncident(
      id: 'SOS-${DateTime.now().millisecondsSinceEpoch}',
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      timestamp: DateTime.now(),
      status: 'active',
      location:
          location ?? 'Karachi (Simulated location near Shahrah-e-Faisal)',
    );
    _sosIncidents.insert(0, incident);
    return incident;
  }

  @override
  Future<List<SosIncident>> getSosIncidents() async {
    return _sosIncidents;
  }

  @override
  Future<Complaint> submitComplaint({
    required String reporterEmail,
    required String reporterName,
    required int rideId,
    required String rideRoute,
    required String driverEmail,
    required String description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final complaint = Complaint(
      id: 'CMP-${DateTime.now().millisecondsSinceEpoch}',
      reporterEmail: reporterEmail,
      reporterName: reporterName,
      rideId: rideId,
      rideRoute: rideRoute,
      driverEmail: driverEmail,
      description: description.trim(),
      createdAt: DateTime.now(),
      status: 'open',
    );
    _complaints.insert(0, complaint);
    return complaint;
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    return _complaints;
  }
}
