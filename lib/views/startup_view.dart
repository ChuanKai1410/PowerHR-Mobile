import 'package:flutter/material.dart' hide ConnectionState;

import '../providers/backend_status_provider.dart';

class StartupView extends StatelessWidget {
  const StartupView({required this.provider, super.key});

  final BackendStatusProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PowerHR')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            final label = switch (provider.state) {
              ConnectionState.notConfigured => 'Not configured',
              ConnectionState.idle => 'Not checked',
              ConnectionState.checking => 'Checking',
              ConnectionState.connected => 'Connected',
              ConnectionState.unavailable => 'Unavailable',
            };
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Development',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Startup Check',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.dns_outlined),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Backend'),
                                const SizedBox(height: 4),
                                Semantics(liveRegion: true, child: Text(label)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Check connection',
                            onPressed:
                                provider.state == ConnectionState.checking ||
                                    provider.state ==
                                        ConnectionState.notConfigured
                                ? null
                                : provider.check,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Environment',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(provider.status?.environment ?? 'Not available'),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
