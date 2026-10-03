import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/backend_status.dart';

class BackendService {
  const BackendService(
    this.baseUri, {
    this.timeout = const Duration(seconds: 5),
  });

  final Uri baseUri;
  final Duration timeout;

  Future<BackendStatus> check() async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await _readRoot(client).timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<BackendStatus> _readRoot(HttpClient client) async {
    final request = await client.getUrl(baseUri);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Backend returned HTTP ${response.statusCode}.');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 16384) {
        throw const FormatException('Backend root response is too large.');
      }
      bytes.addAll(chunk);
    }
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return BackendStatus.fromJson(json);
  }
}
