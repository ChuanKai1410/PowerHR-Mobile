import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/job_listing.dart';

class JobDiscoveryException implements Exception {
  const JobDiscoveryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class JobDiscoveryService {
  const JobDiscoveryService(
    this.baseUri, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final Duration timeout;

  Future<JobPage> fetchPage({
    int page = 1,
    String search = '',
    String type = '',
  }) async {
    final uri = baseUri
        .resolve('jobs/discover')
        .replace(
          queryParameters: {
            'page': '$page',
            'limit': '10',
            if (search.trim().isNotEmpty) 'search': search.trim(),
            if (type.isNotEmpty) 'type': type,
          },
        );
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await _fetch(client, uri).timeout(timeout);
    } on TimeoutException {
      throw const JobDiscoveryException('Request timed out. Try again.');
    } on IOException {
      throw const JobDiscoveryException('Cannot reach the server. Try again.');
    } on FormatException {
      throw const JobDiscoveryException('Invalid response from the server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<JobPage> _fetch(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw const JobDiscoveryException('Unable to load jobs. Try again.');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 1024 * 1024) {
        throw const FormatException('Job response too large');
      }
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return JobPage.fromJson(decoded);
  }
}
