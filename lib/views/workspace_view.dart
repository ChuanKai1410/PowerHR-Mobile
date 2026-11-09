import '../services/token_store.dart';
import '../services/application_tracking_service.dart';
import 'application_tracking_view.dart';
import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/job_discovery_service.dart';
import 'job_discovery_view.dart';

import '../models/auth_identity.dart';
import '../models/workspace_destination.dart';
import '../services/applicant_profile_service.dart';
import 'applicant_profile_view.dart';

/// Authenticated placeholder. No protected business operations are enabled yet.
class WorkspaceView extends StatelessWidget {
  const WorkspaceView({
    required this.identity,
    required this.onSignOut,
    this.profileService,
    super.key,
  });

  final AuthIdentity identity;
  final Future<void> Function() onSignOut;
  final ApplicantProfileService? profileService;

  @override
  Widget build(BuildContext context) {
    final destination = destinationFor(identity);
    final title = switch (destination) {
      WorkspaceDestination.applicant => 'Applicant Workspace',
      WorkspaceDestination.employee => 'Employee Workspace',
      WorkspaceDestination.unsupported => 'Account not supported',
    };
    final description = switch (destination) {
      WorkspaceDestination.applicant =>
        'Applicant features will be implemented in the next modules.',
      WorkspaceDestination.employee =>
        'Employee features will be implemented in the next modules.',
      WorkspaceDestination.unsupported =>
        'This mobile build does not support this account type.',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(identity.email, textAlign: TextAlign.center),
                  Text(
                    'Account type: ${identity.accountType.name}',
                    textAlign: TextAlign.center,
                  ),
                  if (identity.jobTitle != null)
                    Text(
                      'Job title: ${identity.jobTitle}',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (destination == WorkspaceDestination.applicant &&
                      profileService != null)
                    OutlinedButton.icon(
                      key: const Key('open-applicant-profile'),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('My Profile'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ApplicantProfileView(service: profileService!),
                        ),
                      ),
                    ),
                  if (destination == WorkspaceDestination.applicant) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('open-application-tracking'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('My applications'),
                      onPressed: () {
                        final api = AppConfig.fromEnvironment().apiBaseUri;
                        if (api == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('API is not configured.'),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ApplicationTrackingView(
                              service: ApplicationTrackingService(
                                api,
                                const SecureTokenStore(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('open-job-discovery'),
                      onPressed: () {
                        final uri = AppConfig.fromEnvironment().apiBaseUri;
                        if (uri == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('API is not configured.'),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDiscoveryView(
                              service: JobDiscoveryService(uri),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.work_outline),
                      label: const Text('Find jobs'),
                    ),
                  ],
                  FilledButton(
                    onPressed: onSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
