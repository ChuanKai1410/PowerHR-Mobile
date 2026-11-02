import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';

enum AuthState { idle, signingIn, authenticated, failed }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;
  AuthState state = AuthState.idle;
  AuthSession? session;
  String? errorMessage;
  bool _disposed = false;

  Future<void> login({required String email, required String password}) async {
    if (_disposed || state == AuthState.signingIn) return;
    state = AuthState.signingIn;
    errorMessage = null;
    session = null;
    notifyListeners();
    try {
      final result = await _service.login(email: email, password: password);
      if (_disposed) return;
      session = result;
      state = AuthState.authenticated;
    } on AuthException catch (e) {
      if (_disposed) return;
      errorMessage = e.message;
      state = AuthState.failed;
    } catch (_) {
      if (_disposed) return;
      errorMessage = 'Unable to sign in. Please try again.';
      state = AuthState.failed;
    }
    notifyListeners();
  }

  void logout() {
    if (_disposed || state == AuthState.signingIn) return;
    session = null;
    errorMessage = null;
    state = AuthState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
