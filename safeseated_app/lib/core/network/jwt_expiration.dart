import 'dart:convert';

class JwtExpiration {
  const JwtExpiration._();

  static DateTime read(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('The saved access token is malformed.');
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic> || payload['exp'] is! num) {
      throw const FormatException('The saved access token has no expiry.');
    }

    return DateTime.fromMillisecondsSinceEpoch(
      (payload['exp'] as num).toInt() * 1000,
      isUtc: true,
    );
  }
}
