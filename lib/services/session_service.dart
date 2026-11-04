import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/auth_identity.dart';

class SessionUnauthorized implements Exception {
  const SessionUnauthorized();
}

class SessionUnavailable implements Exception {
  const SessionUnavailable();
}

class SessionService {
  const SessionService(
    this.baseUri, {
    this.timeout = const Duration(seconds: 5),
  });

  final Uri baseUri;
  final Duration timeout;

  Future<AuthIdentity> getMe(String token) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await _getMe(client, token).timeout(timeout);
    } on SessionUnauthorized {
      rethrow;
    } on SessionUnavailable {
      rethrow;
    } catch (_) {
      throw const SessionUnavailable();
    } finally {
      client.close(force: true);
    }
  }

  Future<AuthIdentity> _getMe(HttpClient client, String token) async {
    final request = await client.getUrl(baseUri.resolve('auth/me'));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden) {
      throw const SessionUnauthorized();
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const SessionUnavailable();
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 16384) {
        throw const SessionUnavailable();
      }
      bytes.addAll(chunk);
    }
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid response');
      }
      return AuthIdentity.fromJson(json);
    } catch (_) {
      throw const SessionUnavailable();
    }
  }
}
