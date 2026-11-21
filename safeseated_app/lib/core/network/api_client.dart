import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    String baseUrl = ApiConfig.baseUrl,
    http.Client? httpClient,
  }) : _tokenStorage = tokenStorage,
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final TokenStorage _tokenStorage;
  final String _baseUrl;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool authenticated = true,
  }) => _send('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<List<dynamic>> getJsonList(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _sendRaw('GET', path, authenticated: authenticated);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is List) {
      return decoded;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'The API returned an unexpected response.',
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Your session has expired. Please log in again.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['Accept'] = 'application/json'
          ..fields.addAll(fields)
          ..files.add(
            http.MultipartFile.fromBytes(
              fileField,
              fileBytes,
              filename: fileName,
            ),
          );

    late final http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request);
    } on http.ClientException {
      throw const ApiException(
        message:
            'Could not connect to the SafeSeated API. Check that the backend is running.',
      );
    }
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
      }
      throw _errorFromResponse(response.statusCode, decoded);
    }
    return decoded;
  }

  Future<void> delete(String path, {bool authenticated = true}) async {
    await _send('DELETE', path, authenticated: authenticated);
  }

  Future<void> clearToken() => _tokenStorage.clearToken();

  Future<http.Response> _sendRaw(
    String method,
    String path, {
    required bool authenticated,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Your session has expired. Please log in again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(
      method,
      Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}'),
    )..headers.addAll(headers);

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'Could not connect to the SafeSeated API. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (authenticated && response.statusCode == 401) {
        await _tokenStorage.clearToken();
      }
      throw _errorFromResponse(response.statusCode, _decodeResponse(response));
    }
    return response;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Your session has expired. Please log in again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(
      method,
      Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}'),
    )..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'Could not connect to the SafeSeated API. Check that the backend is running.',
      );
    }

    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (authenticated && response.statusCode == 401) {
        await _tokenStorage.clearToken();
      }
      throw _errorFromResponse(response.statusCode, decoded);
    }
    return decoded;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {'title': 'Request failed (${response.statusCode}).'};
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'The API returned an unexpected response.',
    );
  }

  ApiException _errorFromResponse(
    int statusCode,
    Map<String, dynamic> response,
  ) {
    final fieldErrors = <String, List<String>>{};
    final errors = response['errors'];
    if (errors is Map<String, dynamic>) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          fieldErrors[entry.key] = value
              .map((item) => item.toString())
              .toList();
        }
      }
    }

    final message = [
      response['title'],
      response['detail'],
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

    return ApiException(
      statusCode: statusCode,
      message: message.isEmpty
          ? 'The request failed with status $statusCode.'
          : message,
      fieldErrors: fieldErrors,
    );
  }
}
