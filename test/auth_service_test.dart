import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/app_config.dart';
import 'package:powerhr_mobile/models/auth_session.dart';
import 'package:powerhr_mobile/services/auth_service.dart';

void main() {
  final valid = {
    'user': {
      '_id': 'fixture-id',
      'email': 'applicant@example.invalid',
      'role': 'Applicant',
    },
    'token': 'fixture-token-not-a-jwt',
  };
  Matcher failure(String message) => throwsA(
    isA<AuthException>().having((e) => e.message, 'message', message),
  );

  test('requires a configured endpoint', () {
    expect(() => AuthService(AppConfig('')), throwsStateError);
  });
  test('requires user identity, role, email and token', () {
    for (final value in [
      {},
      {'user': {}, 'token': 'x'},
      {...valid, 'token': ''},
    ]) {
      expect(
        () => AuthSession.fromJson(Map<String, dynamic>.from(value)),
        throwsFormatException,
      );
    }
  });
  test('preserves company Admin without promoting it to SysAdmin', () {
    final json = {
      ...valid,
      'user': {'_id': 'id', 'email': 'admin@example.invalid', 'role': 'Admin'},
    };
    expect(AuthSession.fromJson(json).role, 'Admin');
  });

  group('Login HTTP', () {
    late HttpServer server;
    late AuthService service;
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      service = AuthService(AppConfig('http://127.0.0.1:${server.port}/api/'));
    });
    tearDown(() => server.close(force: true));
    Future<AuthSession> login() => service.login(
      email: ' applicant@example.invalid ',
      password: ' fixture password ',
    );
    void respond(int status, String body) {
      server.listen((request) async {
        request.response.statusCode = status;
        request.response.write(body);
        await request.response.close();
      });
    }

    test(
      'posts only credentials, preserves base path and password whitespace',
      () async {
        server.listen((request) async {
          expect(request.method, 'POST');
          expect(request.uri.path, '/api/auth/login');
          expect(request.headers.contentType?.mimeType, 'application/json');
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          final data = jsonDecode(await utf8.decoder.bind(request).join());
          expect(data, {
            'email': 'applicant@example.invalid',
            'password': ' fixture password ',
          });
          request.response.write(jsonEncode(valid));
          await request.response.close();
        });
        final result = await login();
        expect(result.userId, 'fixture-id');
        expect(result.token, 'fixture-token-not-a-jwt');
      },
    );
    test('rejects empty input without a request', () async {
      await expectLater(
        service.login(email: '', password: 'x'),
        failure('Check your email and password.'),
      );
    });
    for (final entry in {
      400: 'Check your email and password.',
      429: 'Too many attempts. Please try again later.',
      500: 'Unable to sign in. Please try again.',
      302: 'Unable to sign in. Please try again.',
    }.entries) {
      test(
        'handles HTTP ${entry.key} without exposing response details',
        () async {
          respond(entry.key, 'private internal details');
          await expectLater(login(), failure(entry.value));
        },
      );
    }
    test('handles incorrect credentials', () async {
      respond(401, '{"error":"Invalid email or password"}');
      await expectLater(login(), failure('Invalid email or password'));
    });
    test('handles inactive accounts', () async {
      respond(401, '{"error":"Account not activated"}');
      await expectLater(login(), failure('Account not activated'));
    });
    test('rejects malformed response without showing raw HTML', () async {
      respond(200, '<html>private information</html>');
      await expectLater(login(), failure('Invalid response from the server.'));
    });
    test('rejects incomplete session', () async {
      respond(200, '{}');
      await expectLater(login(), failure('Invalid response from the server.'));
    });
    test('bounds response size', () async {
      respond(200, ' ' * 1048577);
      await expectLater(login(), failure('Invalid response from the server.'));
    });
    test('times out without retrying credentials', () async {
      var calls = 0;
      server.listen((request) {
        calls++;
      });
      final slow = AuthService(
        AppConfig(service.baseUri.toString()),
        timeout: const Duration(milliseconds: 100),
      );
      await expectLater(
        slow.login(email: 'test', password: 'test'),
        failure('The request timed out. Please try again.'),
      );
      expect(calls, 1);
    });
  });
}
