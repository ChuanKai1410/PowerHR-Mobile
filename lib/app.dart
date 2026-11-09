import 'package:flutter/material.dart';

import 'providers/auth_provider.dart';
import 'providers/backend_status_provider.dart';
import 'services/applicant_profile_service.dart';
import 'views/login_view.dart';
import 'views/startup_view.dart';

class PowerHrApp extends StatefulWidget {
  const PowerHrApp({
    required this.provider,
    this.authProvider,
    this.profileService,
    super.key,
  });

  final BackendStatusProvider provider;
  final AuthProvider? authProvider;
  final ApplicantProfileService? profileService;

  @override
  State<PowerHrApp> createState() => _PowerHrAppState();
}

class _PowerHrAppState extends State<PowerHrApp> {
  @override
  void initState() {
    super.initState();
    widget.provider.check();
    widget.authProvider?.restore();
  }

  @override
  void dispose() {
    widget.provider.dispose();
    widget.authProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerHR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16724B),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Builder(
        builder: (context) => StartupView(
          provider: widget.provider,
          onLogin: widget.authProvider == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LoginView(
                      provider: widget.authProvider!,
                      profileService: widget.profileService,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
