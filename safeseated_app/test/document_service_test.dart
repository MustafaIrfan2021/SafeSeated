import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safeseated_app/core/network/api_client.dart';
import 'package:safeseated_app/core/network/token_storage.dart';
import 'package:safeseated_app/features/profile/data/document_service.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'test-token';

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }
}

void main() {
  test('lists and deletes pending documents using backend routes', () async {
    final storage = _MemoryTokenStorage();
    final client = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/documents/me')) {
          return http.Response(
            jsonEncode([
              {
                'id': '11111111-1111-1111-1111-111111111111',
                'documentType': 'CnicFront',
                'status': 'Pending',
                'uploadedAt': '2026-11-19T10:00:00Z',
                'originalFileName': 'cnic-front.jpg',
                'fileUrl': 'http://test/uploads/cnic-front.jpg',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      }),
    );
    final service = DocumentService(client);

    final documents = await service.getMyDocuments();
    expect(documents, hasLength(1));
    expect(documents.single.documentType, 'CnicFront');
    expect(documents.single.isPending, isTrue);

    await service.delete(documents.single.id);
  });

  test('multipart upload sends documentType and file fields', () async {
    final storage = _MemoryTokenStorage();
    final client = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': '22222222-2222-2222-2222-222222222222',
            'documentType': 'StudentCard',
            'status': 'Pending',
            'uploadedAt': '2026-11-19T10:00:00Z',
            'fileUrl': 'http://test/uploads/student-card.png',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final service = DocumentService(client);

    final document = await service.upload(
      documentType: 'StudentCard',
      fileName: 'student-card.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(document.status, 'Pending');
  });
}
