import 'package:flutter/material.dart';

import 'app.dart';
import 'models/app_config.dart';
import 'providers/backend_status_provider.dart';
import 'services/backend_service.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    PowerHrApp(
      provider: BackendStatusProvider(
        config.apiBaseUri == null ? null : BackendService(config.apiBaseUri!),
      ),
    ),
  );
}
