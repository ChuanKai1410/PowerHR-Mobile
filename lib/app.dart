import 'package:flutter/material.dart';

import 'providers/backend_status_provider.dart';
import 'views/startup_view.dart';

class PowerHrApp extends StatefulWidget {
  const PowerHrApp({required this.provider, super.key});

  final BackendStatusProvider provider;

  @override
  State<PowerHrApp> createState() => _PowerHrAppState();
}

class _PowerHrAppState extends State<PowerHrApp> {
  @override
  void initState() {
    super.initState();
    widget.provider.check();
  }

  @override
  void dispose() {
    widget.provider.dispose();
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
      home: StartupView(provider: widget.provider),
    );
  }
}
