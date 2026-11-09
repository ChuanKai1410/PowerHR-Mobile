import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'token_store.dart';

class JobApplicationException implements Exception {
  const JobApplicationException(this.message, {this.unauthorized = false});
  final String message;
  final bool unauthorized;
  @override
  String toString() => message;
}

class AvailableResume {
  const AvailableResume({
    required this.id,
    required this.name,
    required this.title,
  });
  final String id;
  final String name;
  final String title;

  factory AvailableResume.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid resume');
    }
    return AvailableResume(
      id: id,
      name: data['name'] is String ? data['name'] as String : 'Untitled resume',
      title: data['title'] is String ? data['title'] as String : '',
    );
  }
}

class ApplicationStatus {
  const ApplicationStatus({required this.applied, this.status});
  final bool applied;
  final String? status;
}

class JobApplicationService {
  const JobApplicationService(
    this.baseUri,
    this.tokens, {
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUri;
  final TokenStore tokens;
  final Duration timeout;

  Future<Map<String, dynamic>> _request(
    String method,
    String route, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      throw const JobApplicationException(
        'Your session has expired. Please sign in again.',
        unauthorized: true,
      );
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final uri = baseUri.resolve(route);
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final buffer = <int>[];
        await for (final chunk in response) {
          if (buffer.length + chunk.length > 262144) {
            throw const FormatException('Response too large');
          }
          buffer.addAll(chunk);
        }
        final decoded = jsonDecode(utf8.decode(buffer));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid response');
        }
        if (response.statusCode == 401) {
          throw const JobApplicationException(
            'Your session has expired. Please sign in again.',
            unauthorized: true,
          );
        }
        if (response.statusCode != 200 && response.statusCode != 201) {
          final serverError = decoded['error'];
          throw JobApplicationException(
            serverError is String && serverError.isNotEmpty
                ? serverError
                : 'Unable to process the application.',
          );
        }
        return decoded;
      })().timeout(timeout);
    } on JobApplicationException {
      rethrow;
    } on TimeoutException {
      throw const JobApplicationException('Request timed out. Please retry.');
    } on IOException {
      throw const JobApplicationException(
        'Unable to reach server. Please retry.',
      );
    } on FormatException {
      throw const JobApplicationException('Invalid server response.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<AvailableResume>> getMyResumes() async {
    final data = await _request('GET', 'jobs/apply/me/resumes');
    if (data['items'] is! List) {
      throw const JobApplicationException('Invalid resume response.');
    }
    return (data['items'] as List)
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid resume');
          }
          return AvailableResume.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<ApplicationStatus> getStatus(String postingId) async {
    final data = await _request(
      'GET',
      'jobs/apply/me/status/${Uri.encodeComponent(postingId)}',
    );
    if (data['applied'] is! bool) {
      throw const JobApplicationException('Invalid application status.');
    }
    return ApplicationStatus(
      applied: data['applied'] as bool,
      status: data['status'] is String ? data['status'] as String : null,
    );
  }

  Future<void> submit({
    required String postingId,
    required String resumeId,
  }) async {
    await _request('POST', 'jobs/apply/me', {
      'postingId': postingId,
      'resumeId': resumeId,
    });
  }
}
