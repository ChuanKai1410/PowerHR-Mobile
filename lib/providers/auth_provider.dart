import 'package:flutter/foundation.dart';

import '../models/auth_identity.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/token_store.dart';

enum AuthState {
  idle,
  restoring,
  signingIn,
  authenticated,
  failed,
  verificationUnavailable,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service, this._sessionService, this._tokenStore);

  final AuthService _service;
  final SessionService _sessionService;
  final TokenStore _tokenStore;
  AuthState state = AuthState.idle;
  AuthIdentity? identity;
  String? errorMessage;
  bool _disposed = false;
  int _generation = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restore() async {
    if (_disposed ||
        state == AuthState.signingIn ||
        state == AuthState.restoring) {
      return;
    }
    final generation = ++_generation;
    state = AuthState.restoring;
    identity = null;
    errorMessage = null;
    _notify();
    String? token;
    try {
      token = await _tokenStore.read();
      if (_disposed || generation != _generation) return;
      if (token == null || token.isEmpty) {
        state = AuthState.idle;
      } else {
        identity = await _sessionService.getMe(token);
        if (_disposed || generation != _generation) return;
        state = AuthState.authenticated;
      }
    } on SessionUnauthorized {
      if (_disposed || generation != _generation) return;
      try {
        await _tokenStore.delete();
      } catch (_) {
        errorMessage = 'Unable to clear expired session. Retry or sign out.';
        state = AuthState.verificationUnavailable;
        _notify();
        return;
      }
      if (_disposed || generation != _generation) return;
      state = AuthState.idle;
      errorMessage = 'Session expired. Please sign in again.';
    } catch (_) {
      if (_disposed || generation != _generation) return;
      state = AuthState.verificationUnavailable;
      errorMessage =
          'Unable to verify session. Check your connection and retry.';
    }
    _notify();
  }

  Future<void> login({required String email, required String password}) async {
    if (_disposed ||
        state == AuthState.signingIn ||
        state == AuthState.restoring) {
      return;
    }
    final generation = ++_generation;
    state = AuthState.signingIn;
    identity = null;
    errorMessage = null;
    _notify();
    try {
      final result = await _service.login(email: email, password: password);
      if (_disposed || generation != _generation) return;
      // Do not persist an unverified login response.
      final verified = await _sessionService.getMe(result.token);
      if (_disposed || generation != _generation) return;
      if (verified.userId != result.userId) {
        throw const SessionUnavailable();
      }
      await _tokenStore.write(result.token);
      if (_disposed || generation != _generation) return;
      identity = verified;
      state = AuthState.authenticated;
    } on AuthException catch (e) {
      if (_disposed || generation != _generation) return;
      errorMessage = e.message;
      state = AuthState.failed;
    } on SessionUnauthorized {
      if (_disposed || generation != _generation) return;
      errorMessage = 'Unable to verify login session. Please try again.';
      state = AuthState.failed;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      errorMessage =
          'Unable to complete sign in. Check the server and secure storage.';
      state = AuthState.failed;
    }
    _notify();
  }

  Future<void> logout() async {
    if (_disposed) return;
    final generation = ++_generation;
    // Hide any authenticated identity immediately.
    identity = null;
    state = AuthState.restoring;
    errorMessage = null;
    _notify();
    try {
      await _tokenStore.delete();
      if (_disposed || generation != _generation) return;
      state = AuthState.idle;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      state = AuthState.verificationUnavailable;
      errorMessage = 'Unable to clear stored session. Please retry sign out.';
    }
    _notify();
  }

  @override
  void dispose() {
    _generation++;
    _disposed = true;
    super.dispose();
  }
}
