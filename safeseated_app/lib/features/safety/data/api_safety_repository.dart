import '../../../core/network/api_client.dart';
import '../../../core/network/api_id_mapper.dart';
import '../domain/models/complaint.dart';
import '../domain/models/sos_incident.dart';
import '../domain/repositories/safety_repository.dart';

class ApiSafetyRepository implements SafetyRepository {
  ApiSafetyRepository(this._api);

  final ApiClient _api;

  @override
  Future<Complaint> submitComplaint({
    required String reporterEmail,
    required String reporterName,
    required int rideId,
    required String rideRoute,
    required String driverEmail,
    required String description,
  }) async {
    final rideGuid = ApiIdMapper.toGuid(rideId);
    final data = await _api.postJson('/complaints', {
      'rideId': ?rideGuid,
      'description': description.trim(),
    });
    return _complaintFromJson(data, reporterEmail);
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    final items = await _api.getJsonList('/complaints/me');
    return items
        .whereType<Map>()
        .map(
          (item) => _complaintFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
            '',
          ),
        )
        .toList();
  }

  Complaint _complaintFromJson(
    Map<String, dynamic> json,
    String reporterEmail,
  ) {
    final rideGuid = json['rideId']?.toString();
    final rideId = rideGuid == null ? 0 : ApiIdMapper.toInt(rideGuid);
    if (rideGuid != null) ApiIdMapper.remember(rideId, rideGuid);
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    return Complaint(
      id: json['id']?.toString() ?? '',
      reporterEmail: reporterEmail,
      reporterName: '',
      rideId: rideId,
      rideRoute: '',
      driverEmail: '',
      description: json['description']?.toString() ?? '',
      createdAt: created ?? DateTime.now(),
      status: json['status']?.toString().toLowerCase() ?? 'open',
    );
  }

  @override
  Future<SosIncident> triggerSos({
    required String reporterEmail,
    required String reporterName,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? location,
  }) => throw UnimplementedError();
  @override
  Future<List<SosIncident>> getSosIncidents() => throw UnimplementedError();
}
