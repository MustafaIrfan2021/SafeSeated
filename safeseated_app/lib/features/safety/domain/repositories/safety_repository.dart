import '../models/sos_incident.dart';
import '../models/complaint.dart';

abstract class SafetyRepository {
  Future<SosIncident> triggerSos({
    required String reporterEmail,
    required String reporterName,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? location,
  });
  Future<List<SosIncident>> getSosIncidents();
  Future<Complaint> submitComplaint({
    required String reporterEmail,
    required String reporterName,
    required int rideId,
    required String rideRoute,
    required String driverEmail,
    required String description,
  });
  Future<List<Complaint>> getComplaints();
}
