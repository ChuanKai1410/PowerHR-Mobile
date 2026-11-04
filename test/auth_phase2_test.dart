import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/app_config.dart';
import 'package:powerhr_mobile/models/auth_identity.dart';
import 'package:powerhr_mobile/models/auth_session.dart';
import 'package:powerhr_mobile/providers/auth_provider.dart';
import 'package:powerhr_mobile/services/auth_service.dart';
import 'package:powerhr_mobile/services/session_service.dart';
import 'package:powerhr_mobile/services/token_store.dart';

class MemoryTokenStore implements TokenStore {
  String? token;
  @override
  Future<void> delete() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }
}

class FakeAuthService extends AuthService {
  FakeAuthService() : super(AppConfig('https://example.invalid/'));
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(
    userId: 'user1',
    email: email,
    role: 'HR',
    token: 'test-token',
  );
}

class FakeSessionService extends SessionService {
  FakeSessionService() : super(Uri.parse('https://example.invalid/'));
  Object? failure;
  int calls = 0;
  @override
  Future<AuthIdentity> getMe(String token) async {
    calls++;
    if (failure != null) throw failure!;
    return const AuthIdentity(
      userId: 'user1',
      email: 'hr@example.invalid',
      role: 'HR',
    );
  }
}

void main() {
  test('login verifies current user before storing token', () async {
    final tokens = MemoryTokenStore();
    final sessions = FakeSessionService();
    final provider = AuthProvider(FakeAuthService(), sessions, tokens);
    await provider.login(email: 'hr@example.invalid', password: 'password');
    expect(sessions.calls, 1);
    expect(tokens.token, 'test-token');
    expect(provider.state, AuthState.authenticated);
    expect(provider.identity?.role, 'HR');
    await provider.logout();
    expect(tokens.token, isNull);
    expect(provider.identity, isNull);
    provider.dispose();
  });

  test('restores verified session after restart', () async {
    final tokens = MemoryTokenStore()..token = 'saved-token';
    final sessions = FakeSessionService();
    final provider = AuthProvider(FakeAuthService(), sessions, tokens);
    await provider.restore();
    expect(provider.state, AuthState.authenticated);
    expect(sessions.calls, 1);
    provider.dispose();
  });

  test('expired session clears saved token', () async {
    final tokens = MemoryTokenStore()..token = 'expired-token';
    final sessions = FakeSessionService()
      ..failure = const SessionUnauthorized();
    final provider = AuthProvider(FakeAuthService(), sessions, tokens);
    await provider.restore();
    expect(provider.state, AuthState.idle);
    expect(tokens.token, isNull);
    expect(provider.identity, isNull);
    provider.dispose();
  });

  test('network failure retains token but not authenticated state', () async {
    final tokens = MemoryTokenStore()..token = 'saved-token';
    final sessions = FakeSessionService()..failure = const SessionUnavailable();
    final provider = AuthProvider(FakeAuthService(), sessions, tokens);
    await provider.restore();
    expect(provider.state, AuthState.verificationUnavailable);
    expect(tokens.token, 'saved-token');
    expect(provider.identity, isNull);
    sessions.failure = null;
    await provider.restore();
    expect(provider.state, AuthState.authenticated);
    provider.dispose();
  });

  test('login does not save a token if session verification fails', () async {
    final tokens = MemoryTokenStore();
    final sessions = FakeSessionService()
      ..failure = const SessionUnauthorized();
    final provider = AuthProvider(FakeAuthService(), sessions, tokens);
    await provider.login(email: 'hr@example.invalid', password: 'password');
    expect(provider.state, AuthState.failed);
    expect(tokens.token, isNull);
    provider.dispose();
  });
}
