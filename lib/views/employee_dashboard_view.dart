import 'package:flutter/material.dart';

import '../models/auth_identity.dart';

/// Employee-only landing page. UI labels are not authorization decisions.
/// Privileged HR/admin actions are deliberately not enabled in this phase.
class EmployeeDashboardView extends StatelessWidget {
  const EmployeeDashboardView({
    required this.identity,
    required this.onSignOut,
    super.key,
  });

  final AuthIdentity identity;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = identity.jobTitle?.trim() ?? '';
    final displayTitle = title.isEmpty ? 'Employee' : title;
    final normalizedTitle = title.toLowerCase();
    final isHr =
        normalizedTitle == 'hr' ||
        normalizedTitle == 'hr manager' ||
        normalizedTitle == 'human resources';
    final isAdmin =
        normalizedTitle == 'admin' || normalizedTitle == 'company admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            key: const Key('employee-sign-out'),
            tooltip: 'Sign out',
            onPressed: () => onSignOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text('Welcome back', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(identity.email, key: const Key('employee-email')),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your position',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayTitle,
                            key: const Key('employee-job-title'),
                            style: theme.textTheme.titleLarge,
                          ),
                          if (identity.company != null) ...[
                            const SizedBox(height: 6),
                            Text('Company: ${identity.company}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Workspace', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (isHr) ...[
              const _UpcomingModule(
                key: Key('employee-hr-module'),
                icon: Icons.people_outline,
                title: 'Recruitment management',
                description:
                    'HR features will be connected after server-side scope verification.',
              ),
            ] else if (isAdmin) ...[
              const _UpcomingModule(
                key: Key('employee-admin-module'),
                icon: Icons.apartment_outlined,
                title: 'Company administration',
                description:
                    'Admin features will be connected after server-side scope verification.',
              ),
            ] else ...[
              const _UpcomingModule(
                key: Key('employee-general-module'),
                icon: Icons.work_outline,
                title: 'Employee workspace',
                description:
                    'Employee-specific functions are not available in this phase.',
              ),
            ],
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Access to HR and company data is enforced by the server. '
                        'A job title shown here does not grant permissions.',
                        key: Key('employee-scope-notice'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('employee-sign-out-button'),
              onPressed: () => onSignOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingModule extends StatelessWidget {
  const _UpcomingModule({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Chip(label: Text('Planned')),
    ),
  );
}
