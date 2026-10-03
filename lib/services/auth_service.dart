import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_config.dart';
import '../models/auth_session.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService(AppConfig config, {this.timeout = const Duration(seconds: 5)})
    : baseUri =
          config.apiBaseUri ?? (throw StateError('API is not configured.'));

  final Uri baseUri;
  final Duration timeout;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Check your email and password.');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await _login(client, email.trim(), password).timeout(timeout);
    } on TimeoutException {
      throw const AuthException('The request timed out. Please try again.');
    } on IOException {
      throw const AuthException(
        'Unable to reach the server. Please try again.',
      );
    } on FormatException {
      throw const AuthException('Invalid response from the server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<AuthSession> _login(
    HttpClient client,
    String email,
    String password,
  ) async {
    final request = await client.postUrl(baseUri.resolve('auth/login'));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode({'email': email, 'password': password}));
    final response = await request.close();
    if (response.statusCode != 200 && response.statusCode != 401) {
      throw AuthException(switch (response.statusCode) {
        400 => 'Check your email and password.',
        429 => 'Too many attempts. Please try again later.',
        _ => 'Unable to sign in. Please try again.',
      });
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 1048576) {
        throw const FormatException('Login response is too large.');
      }
      bytes.addAll(chunk);
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (response.statusCode == 401) {
      throw AuthException(
        data is Map && data['error'] == 'Account not activated'
            ? 'Account not activated'
            : 'Invalid email or password',
      );
    }
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response.');
    }
    return AuthSession.fromJson(data);
  }
}
