import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/employee_company.dart';
import 'token_store.dart';

class EmployeeCompanyException implements Exception {
  const EmployeeCompanyException(this.message);
  final String message;
  @override
  String toString() => message;
}

class EmployeeCompanyService {
  const EmployeeCompanyService(
    this.baseUri,
    this.tokens, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final TokenStore tokens;
  final Duration timeout;

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      throw const EmployeeCompanyException(
        'Session expired. Please sign in again.',
      );
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(baseUri.resolve(path));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 262144) {
            throw const FormatException('Response too large.');
          }
          bytes.addAll(chunk);
        }
        if (response.statusCode == 401) {
          throw const EmployeeCompanyException(
            'Session expired. Please sign in again.',
          );
        }
        if (response.statusCode == 403) {
          throw const EmployeeCompanyException(
            'You are not authorized to view this information.',
          );
        }
        if (response.statusCode == 404) {
          throw const EmployeeCompanyException('Company not found.');
        }
        if (response.statusCode != 200) {
          throw const EmployeeCompanyException(
            'Unable to load company information.',
          );
        }
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid response.');
        }
        return decoded;
      })().timeout(timeout);
    } on EmployeeCompanyException {
      rethrow;
    } on TimeoutException {
      throw const EmployeeCompanyException('Request timed out. Please retry.');
    } on IOException {
      throw const EmployeeCompanyException(
        'Unable to reach server. Please retry.',
      );
    } on FormatException {
      throw const EmployeeCompanyException('Invalid company response.');
    } finally {
      client.close(force: true);
    }
  }

  Future<EmployeeCompany> getOverview() async =>
      EmployeeCompany.fromJson(await _get('company/mobile/me/overview'));
  Future<List<EmployeeDepartment>> getDepartments() async {
    final response = await _get('company/mobile/me/departments');
    if (response['items'] is! List) {
      throw const EmployeeCompanyException('Invalid department response.');
    }
    try {
      return (response['items'] as List)
          .map<EmployeeDepartment>((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid department.');
            }
            return EmployeeDepartment.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const EmployeeCompanyException('Invalid department response.');
    }
  }
}
