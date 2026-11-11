import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/hr_recruitment.dart';
import 'token_store.dart';

class HrRecruitmentException implements Exception {
  const HrRecruitmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HrRecruitmentService {
  const HrRecruitmentService(
    this.baseUri,
    this.tokens, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final TokenStore tokens;
  final Duration timeout;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      throw const HrRecruitmentException(
        'Session expired. Please sign in again.',
      );
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.openUrl(method, baseUri.resolve(path));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final buffer = <int>[];
        await for (final part in response) {
          if (buffer.length + part.length > 524288) {
            throw const FormatException('Response too large');
          }
          buffer.addAll(part);
        }
        if (response.statusCode == 401) {
          throw const HrRecruitmentException(
            'Session expired. Please sign in again.',
          );
        }
        if (response.statusCode == 403) {
          throw const HrRecruitmentException('HR access is not authorized.');
        }
        final payload = jsonDecode(utf8.decode(buffer));
        if (payload is! Map<String, dynamic>) {
          throw const FormatException('Invalid response');
        }
        if (response.statusCode != 200) {
          throw HrRecruitmentException(
            payload['error'] is String
                ? payload['error'] as String
                : 'Request failed.',
          );
        }
        return payload;
      })().timeout(timeout);
    } on HrRecruitmentException {
      rethrow;
    } on TimeoutException {
      throw const HrRecruitmentException('Request timed out. Please retry.');
    } on IOException {
      throw const HrRecruitmentException(
        'Unable to reach server. Please retry.',
      );
    } on FormatException {
      throw const HrRecruitmentException('Invalid server response.');
    } finally {
      client.close(force: true);
    }
  }

  HrPage<T> _page<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (data['items'] is! List ||
        data['hasMore'] is! bool ||
        data['total'] is! int) {
      throw const HrRecruitmentException('Invalid list response.');
    }
    final items = (data['items'] as List)
        .map<T>((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid item');
          }
          return parser(item);
        })
        .toList(growable: false);
    return HrPage<T>(
      items: items,
      hasMore: data['hasMore'] as bool,
      total: data['total'] as int,
    );
  }

  Future<HrPage<HrPosting>> postings({int page = 1}) async => _page(
    await _request('GET', 'jobs/hr/mobile/postings?page=$page'),
    HrPosting.fromJson,
  );
  Future<HrPage<HrApplication>> applications(
    String postingId, {
    int page = 1,
  }) async => _page(
    await _request(
      'GET',
      'jobs/hr/mobile/postings/${Uri.encodeComponent(postingId)}/applications?page=$page',
    ),
    HrApplication.fromJson,
  );
  Future<void> updateStatus(
    String postingId,
    String applicationId,
    String status,
  ) async {
    await _request(
      'PATCH',
      'jobs/hr/mobile/postings/${Uri.encodeComponent(postingId)}/applications/${Uri.encodeComponent(applicationId)}/status',
      {'status': status},
    );
  }
}
