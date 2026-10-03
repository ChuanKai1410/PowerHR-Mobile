import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/app_config.dart';
import 'package:powerhr_mobile/models/backend_status.dart';
import 'package:powerhr_mobile/providers/backend_status_provider.dart';
import 'package:powerhr_mobile/services/backend_service.dart';

class ControlledService extends BackendService {
  ControlledService() : super(Uri.parse('https://example.invalid/'));
  final pending = Completer<BackendStatus>();
  int calls = 0;

  @override
  Future<BackendStatus> check() {
    calls++;
    return pending.future;
  }
}

void main() {
  group('API configuration', () {
    test('missing URL does not select a production endpoint', () {
      expect(AppConfig('').apiBaseUri, isNull);
    });
    test('normalizes HTTPS base path', () {
      expect(
        AppConfig('https://example.invalid/api').apiBaseUri.toString(),
        'https://example.invalid/api/',
      );
    });
    test('local HTTP is debug-only', () {
      expect(
        AppConfig('http://10.0.2.2:3000', allowLocalHttp: true).apiBaseUri,
        Uri.parse('http://10.0.2.2:3000/'),
      );
      expect(
        () => AppConfig('http://10.0.2.2:3000', allowLocalHttp: false),
        throwsFormatException,
      );
      expect(
        () => AppConfig('http://example.invalid', allowLocalHttp: true),
        throwsFormatException,
      );
    });
    test('rejects credentials, query, fragment and invalid scheme', () {
      for (final url in [
        'https://user:secret@example.invalid',
        'https://example.invalid?token=secret',
        'https://example.invalid#token',
        'ftp://example.invalid',
        'not-a-url',
      ]) {
        expect(() => AppConfig(url), throwsFormatException);
      }
    });
  });

  group('Backend HTTP service', () {
    late HttpServer server;
    late BackendService service;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      service = BackendService(Uri.parse('http://127.0.0.1:${server.port}/'));
    });
    tearDown(() => server.close(force: true));

    void respond(String body, {int status = 200}) {
      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/');
        request.response.statusCode = status;
        request.response.write(body);
        await request.response.close();
      });
    }

    test('reads existing Fastify root contract', () async {
      respond(jsonEncode({'root': true, 'env': 'development'}));
      expect((await service.check()).environment, 'development');
    });
    test('rejects non-200 responses', () async {
      respond('unavailable', status: 503);
      await expectLater(service.check(), throwsA(isA<HttpException>()));
    });
    test('does not follow redirects', () async {
      respond('', status: 302);
      await expectLater(service.check(), throwsA(isA<HttpException>()));
    });
    test('rejects malformed JSON', () async {
      respond('<html>unexpected server</html>');
      await expectLater(service.check(), throwsFormatException);
    });
    test('rejects a JSON response from a different service', () async {
      respond('{"root":false,"env":"development"}');
      await expectLater(service.check(), throwsFormatException);
    });
    test('rejects oversized root response', () async {
      respond(' ' * 16385);
      await expectLater(service.check(), throwsFormatException);
    });
    test('times out when the server does not respond', () async {
      server.listen((request) {});
      final slow = BackendService(
        service.baseUri,
        timeout: const Duration(milliseconds: 100),
      );
      await expectLater(slow.check(), throwsA(isA<TimeoutException>()));
    });
  });

  group('Provider lifecycle', () {
    test('unconfigured provider makes no request', () async {
      final provider = BackendStatusProvider(null);
      await provider.check();
      expect(provider.state, ConnectionState.notConfigured);
      provider.dispose();
    });
    test('publishes loading/success and prevents duplicate requests', () async {
      final service = ControlledService();
      final provider = BackendStatusProvider(service);
      final states = <ConnectionState>[];
      provider.addListener(() => states.add(provider.state));
      final pending = provider.check();
      await provider.check();
      expect(service.calls, 1);
      service.pending.complete(const BackendStatus(environment: 'development'));
      await pending;
      expect(states, [ConnectionState.checking, ConnectionState.connected]);
      expect(provider.status?.environment, 'development');
      provider.dispose();
    });
    test('failed request exposes unavailable state', () async {
      final service = ControlledService();
      final provider = BackendStatusProvider(service);
      final pending = provider.check();
      service.pending.completeError(const SocketException('test failure'));
      await pending;
      expect(provider.state, ConnectionState.unavailable);
      expect(provider.status, isNull);
      provider.dispose();
    });
    test('completion after disposal does not notify', () async {
      final service = ControlledService();
      final provider = BackendStatusProvider(service);
      final pending = provider.check();
      provider.dispose();
      service.pending.complete(const BackendStatus(environment: 'test'));
      await pending;
    });
  });
}
