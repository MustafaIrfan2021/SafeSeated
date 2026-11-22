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
    required String clientRequestId,
    double? latitude,
    double? longitude,
    int? rideId,
  }) async {
    final rideGuid = rideId == null ? null : ApiIdMapper.toGuid(rideId);
    if (rideId != null && rideGuid == null) {
      throw StateError('The selected ride is missing its backend ID.');
    }
    final data = await _api.postJson('/emergency-alerts', {
      'clientRequestId': clientRequestId,
      'latitude': latitude,
      'longitude': longitude,
      'rideId': ?rideGuid,
    });
    return _sosIncidentFromJson(data);
  }

  @override
  Future<List<SosIncident>> getSosIncidents() async {
    final items = await _api.getJsonList('/emergency-alerts/me');
    return items.map((item) {
      if (item is! Map) {
        throw const FormatException('The API returned an invalid SOS alert.');
      }
      return _sosIncidentFromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  SosIncident _sosIncidentFromJson(Map<String, dynamic> json) {
    final rideGuid = json['rideId']?.toString();
    if (rideGuid != null) {
      ApiIdMapper.remember(ApiIdMapper.toInt(rideGuid), rideGuid);
    }
    final id = json['id']?.toString();
    final role = json['role']?.toString();
    final status = json['status']?.toString();
    final timestamp = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (id == null || role == null || status == null || timestamp == null) {
      throw const FormatException('The API returned an invalid SOS alert.');
    }
    return SosIncident(
      id: id,
      role: role,
      timestamp: timestamp,
      status: status,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rideId: rideGuid == null ? null : ApiIdMapper.toInt(rideGuid),
    );
  }
}
