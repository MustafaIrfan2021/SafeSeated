import 'dart:typed_data';

import '../../../core/network/api_client.dart';

class VerificationDocument {
  const VerificationDocument({
    required this.id,
    required this.documentType,
    required this.status,
    required this.uploadedAt,
    required this.originalFileName,
    required this.fileUrl,
    this.rejectionReason,
  });

  final String id;
  final String documentType;
  final String status;
  final DateTime? uploadedAt;
  final String originalFileName;
  final String fileUrl;
  final String? rejectionReason;

  bool get isPending => status.toLowerCase() == 'pending';

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    final uploadedAt = json['uploadedAt']?.toString();
    return VerificationDocument(
      id: json['id']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      uploadedAt: uploadedAt == null ? null : DateTime.tryParse(uploadedAt),
      originalFileName:
          json['originalFileName']?.toString() ?? 'Uploaded document',
      fileUrl: json['fileUrl']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class DocumentService {
  const DocumentService(this._api);

  final ApiClient _api;

  Future<List<VerificationDocument>> getMyDocuments() async {
    final items = await _api.getJsonList('/documents/me');
    return items
        .whereType<Map>()
        .map(
          (item) => VerificationDocument.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<VerificationDocument> upload({
    required String documentType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const FormatException('Select a file to upload.');
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('File size must not exceed 5 MB.');
    }

    final response = await _api.postMultipart(
      '/documents',
      fields: {'documentType': documentType},
      fileField: 'file',
      fileName: fileName,
      fileBytes: bytes,
    );
    return VerificationDocument(
      id: response['id']?.toString() ?? '',
      documentType: response['documentType']?.toString() ?? documentType,
      status: response['status']?.toString() ?? 'Pending',
      uploadedAt: DateTime.tryParse(response['uploadedAt']?.toString() ?? ''),
      originalFileName: fileName,
      fileUrl: response['fileUrl']?.toString() ?? '',
    );
  }

  Future<void> delete(String id) => _api.delete('/documents/$id');
}
