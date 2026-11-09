import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/applicant_profile.dart';
import 'token_store.dart';

class ProfileUnauthorized implements Exception {}

class ProfileUnavailable implements Exception {}

class ProfileRejected implements Exception {
  ProfileRejected(this.message);
  final String message;
}

class ApplicantProfileService {
  ApplicantProfileService(
    this.baseUri,
    this.tokenStore, {
    this.timeout = const Duration(seconds: 10),
  });

  final Uri baseUri;
  final TokenStore tokenStore;
  final Duration timeout;

  Future<ApplicantProfile> fetch() => _request('GET');

  Future<ApplicantProfile> update({
    required String firstName,
    required String lastName,
    required String gender,
  }) => _request(
    'PATCH',
    payload: {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'gender': gender,
    },
  );

  Future<ApplicantProfile> _request(
    String method, {
    Map<String, dynamic>? payload,
  }) async {
    final token = await tokenStore.read();
    if (token == null || token.isEmpty) throw ProfileUnauthorized();
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final uri = baseUri.resolve('users/profile/me');
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (payload != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(payload));
        }
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 1048576) throw ProfileUnavailable();
          bytes.addAll(chunk);
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw ProfileUnauthorized();
        }
        if (response.statusCode == 400) {
          throw ProfileRejected('Please check your profile details.');
        }
        if (response.statusCode != 200) throw ProfileUnavailable();
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) throw ProfileUnavailable();
        return ApplicantProfile.fromJson(decoded);
      })().timeout(timeout);
    } on ProfileUnauthorized {
      rethrow;
    } on ProfileRejected {
      rethrow;
    } catch (_) {
      throw ProfileUnavailable();
    } finally {
      client.close(force: true);
    }
  }
}
