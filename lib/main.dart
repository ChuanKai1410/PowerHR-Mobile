import 'package:flutter/material.dart';

import 'app.dart';
import 'models/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/backend_status_provider.dart';
import 'services/auth_service.dart';
import 'services/backend_service.dart';
import 'services/session_service.dart';
import 'services/token_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final baseUri = config.apiBaseUri;
  runApp(
    PowerHrApp(
      provider: BackendStatusProvider(
        baseUri == null ? null : BackendService(baseUri),
      ),
      authProvider: baseUri == null
          ? null
          : AuthProvider(
              AuthService(config),
              SessionService(baseUri),
              const SecureTokenStore(),
            ),
    ),
  );
}
