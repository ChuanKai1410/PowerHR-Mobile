import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'token_store.dart';

class CompanyAdminException implements Exception {
  const CompanyAdminException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CompanyAdminService {
  const CompanyAdminService(
    this.baseUri,
    this.tokens, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final TokenStore tokens;
  final Duration timeout;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      throw const CompanyAdminException('Session expired. Sign in again.');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.openUrl(method, baseUri.resolve(path));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (data != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(data));
        }
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 262144) {
            throw const FormatException('Response too large');
          }
          bytes.addAll(chunk);
        }
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid response');
        }
        if (response.statusCode == 401) {
          throw const CompanyAdminException('Session expired. Sign in again.');
        }
        if (response.statusCode == 403) {
          throw const CompanyAdminException(
            'Company Admin permission required.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw CompanyAdminException(
            decoded['error'] is String
                ? decoded['error'] as String
                : 'Company administration request failed.',
          );
        }
        return decoded;
      })().timeout(timeout);
    } on CompanyAdminException {
      rethrow;
    } on TimeoutException {
      throw const CompanyAdminException('Request timed out. Please retry.');
    } on IOException {
      throw const CompanyAdminException('Unable to reach server.');
    } on FormatException {
      throw const CompanyAdminException('Invalid server response.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> employees({int page = 1}) =>
      _send('GET', 'company/mobile/admin/employees?page=$page');
  Future<Map<String, dynamic>> departments() =>
      _send('GET', 'company/mobile/admin/departments');
  Future<void> createDepartment(String name) async {
    await _send('POST', 'company/mobile/admin/departments', {'name': name});
  }

  Future<void> renameDepartment(String id, String name) async {
    await _send(
      'PATCH',
      'company/mobile/admin/departments/${Uri.encodeComponent(id)}',
      {'name': name},
    );
  }
}
