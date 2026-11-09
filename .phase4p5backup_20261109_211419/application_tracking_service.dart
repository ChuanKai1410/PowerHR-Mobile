import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/application_record.dart';
import 'token_store.dart';

class TrackingException implements Exception {
  const TrackingException(this.message, {this.unauthorized = false});
  final String message;
  final bool unauthorized;
  @override
  String toString() => message;
}

class TrackingPage {
  const TrackingPage({required this.items, required this.hasMore});
  final List<ApplicationRecord> items;
  final bool hasMore;
}

class ApplicationTrackingService {
  const ApplicationTrackingService(
    this.baseUri,
    this.tokens, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final TokenStore tokens;
  final Duration timeout;

  Future<Map<String, dynamic>> _request(String route) async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      throw const TrackingException(
        'Session expired. Please sign in again.',
        unauthorized: true,
      );
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(baseUri.resolve(route));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final chunks = <int>[];
        await for (final chunk in response) {
          if (chunks.length + chunk.length > 1048576) {
            throw const FormatException('Response too large');
          }
          chunks.addAll(chunk);
        }
        final decoded = jsonDecode(utf8.decode(chunks));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid response');
        }
        if (response.statusCode == 401) {
          throw const TrackingException(
            'Session expired. Please sign in again.',
            unauthorized: true,
          );
        }
        if (response.statusCode != 200) {
          final msg = decoded['error'];
          throw TrackingException(
            msg is String ? msg : 'Unable to load applications.',
          );
        }
        return decoded;
      })().timeout(timeout);
    } on TrackingException {
      rethrow;
    } on TimeoutException {
      throw const TrackingException('Request timed out. Please retry.');
    } on IOException {
      throw const TrackingException('Unable to reach server. Please retry.');
    } on FormatException {
      throw const TrackingException('Invalid application response.');
    } finally {
      client.close(force: true);
    }
  }

  Future<TrackingPage> fetchPage({int page = 1}) async {
    if (page < 1) throw const TrackingException('Invalid page.');
    final data = await _request('jobs/tracking/me?page=$page&limit=10');
    if (data['items'] is! List || data['hasMore'] is! bool) {
      throw const TrackingException('Invalid application response.');
    }
    final items = (data['items'] as List).map((row) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Invalid application');
      }
      return ApplicationRecord.fromJson(row);
    }).toList();
    return TrackingPage(items: items, hasMore: data['hasMore'] as bool);
  }

  Future<ApplicationRecord> getDetails(String id) async {
    final data = await _request('jobs/tracking/me/${Uri.encodeComponent(id)}');
    final item = data['application'];
    if (item is! Map<String, dynamic>) {
      throw const TrackingException('Invalid application response.');
    }
    return ApplicationRecord.fromJson(item);
  }
}
