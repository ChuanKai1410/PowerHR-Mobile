import 'package:flutter/material.dart';

import '../models/auth_identity.dart';
import '../models/workspace_destination.dart';

/// Authenticated placeholder. No protected business operations are enabled yet.
class WorkspaceView extends StatelessWidget {
  const WorkspaceView({
    required this.identity,
    required this.onSignOut,
    super.key,
  });

  final AuthIdentity identity;
  final Future<void> Function() onSignOut;

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
