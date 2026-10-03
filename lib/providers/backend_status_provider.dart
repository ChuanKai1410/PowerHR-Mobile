import 'package:flutter/foundation.dart';

import '../models/backend_status.dart';
import '../services/backend_service.dart';

enum ConnectionState { notConfigured, idle, checking, connected, unavailable }

class BackendStatusProvider extends ChangeNotifier {
  BackendStatusProvider(this._service)
    : state = _service == null
          ? ConnectionState.notConfigured
          : ConnectionState.idle;

  final BackendService? _service;
  bool _disposed = false;
  ConnectionState state;
  BackendStatus? status;

  Future<void> check() async {
    if (_disposed || _service == null || state == ConnectionState.checking) {
      return;
    }
    state = ConnectionState.checking;
    status = null;
    notifyListeners();
    try {
      final result = await _service.check();
      if (_disposed) return;
      status = result;
      state = ConnectionState.connected;
    } catch (_) {
      if (_disposed) return;
      state = ConnectionState.unavailable;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
