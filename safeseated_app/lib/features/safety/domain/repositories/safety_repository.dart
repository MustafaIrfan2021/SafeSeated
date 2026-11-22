import '../models/sos_incident.dart';
import '../models/complaint.dart';

abstract class SafetyRepository {
  Future<SosIncident> triggerSos({
    required String clientRequestId,
    double? latitude,
    double? longitude,
    int? rideId,
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
