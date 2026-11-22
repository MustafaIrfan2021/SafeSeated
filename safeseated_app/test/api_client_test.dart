import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safeseated_app/core/network/api_client.dart';
import 'package:safeseated_app/core/network/api_exception.dart';
import 'package:safeseated_app/core/network/token_storage.dart';

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'test-token';

  @override
  Future<void> writeToken(String value) async {}
}

void main() {
  test('connection errors include the underlying client exception', () async {
    final client = ApiClient(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://192.168.1.38:5157/api',
      httpClient: MockClient((_) {
        throw http.ClientException('Connection refused');
      }),
    );

    await expectLater(
      client.getJson('/rides'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Details: Connection refused'),
        ),
      ),
    );
  });
}
