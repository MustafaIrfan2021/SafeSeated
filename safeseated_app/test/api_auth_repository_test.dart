import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safeseated_app/core/network/api_client.dart';
import 'package:safeseated_app/core/network/token_storage.dart';
import 'package:safeseated_app/features/auth/data/api_auth_repository.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token;

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

String _token() {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'eyJhbGciOiJub25lIn0.$payload.signature';
}

void main() {
  test('login stores token and loads a verified passenger profile', () async {
    final storage = _MemoryTokenStorage();
    final client = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://test/api',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({'accessToken': _token()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            jsonEncode({
              'id': '11111111-1111-1111-1111-111111111111',
              'name': 'Ayesha Khan',
              'email': 'ayesha@example.com',
              'phone': '03001234567',
              'cnic': '1234512345671',
              'role': 'Passenger',
              'verificationStatus': 'Verified',
              'passengerProfile': {
                'cnic': '1234512345671',
                'university': 'SMIU',
                'studentId': 'CSC-1',
                'program': 'BSCS',
                'semester': '4',
                'emergencyContactName': 'Mother',
                'emergencyContactPhone': '03331234567',
              },
              'driverProfile': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final repository = ApiAuthRepository(
      apiClient: client,
      tokenStorage: storage,
    );

    final user = await repository.login(
      email: ' ayesha@example.com ',
      password: 'password123',
      role: UserRole.passenger,
    );

    expect(storage.token, isNotEmpty);
    expect(user.role, UserRole.passenger);
    expect(user.status, VerificationStatus.approved);
    expect(user.name, 'Ayesha Khan');
  });

  test('401 login response does not retain a token', () async {
    final storage = _MemoryTokenStorage();
    final client = ApiClient(
      tokenStorage: storage,
      baseUrl: 'http://test/api',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'status': 401, 'title': 'Invalid email or password.'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final repository = ApiAuthRepository(
      apiClient: client,
      tokenStorage: storage,
    );

    await expectLater(
      repository.login(
        email: 'wrong@example.com',
        password: 'password123',
        role: UserRole.passenger,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          'Invalid email or password.',
        ),
      ),
    );
    expect(storage.token, isNull);
  });
}
