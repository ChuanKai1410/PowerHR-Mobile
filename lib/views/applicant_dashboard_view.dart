import 'package:flutter/material.dart';
import '../models/application_record.dart';
import '../models/auth_identity.dart';
import '../services/applicant_profile_service.dart';
import '../services/application_tracking_service.dart';
import '../services/job_discovery_service.dart';
import 'applicant_profile_view.dart';
import 'application_tracking_view.dart';
import 'job_discovery_view.dart';

class ApplicantDashboardView extends StatefulWidget {
  const ApplicantDashboardView({
    required this.identity,
    required this.trackingService,
    required this.jobDiscoveryService,
    required this.onSignOut,
    this.profileService,
    super.key,
  });
  final AuthIdentity identity;
  final ApplicationTrackingService trackingService;
  final JobDiscoveryService jobDiscoveryService;
  final ApplicantProfileService? profileService;
  final Future<void> Function() onSignOut;
  @override
  State<ApplicantDashboardView> createState() => _ApplicantDashboardViewState();
}

class _ApplicantDashboardViewState extends State<ApplicantDashboardView> {
  TrackingPage? _page;
  String? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.trackingService.fetchPage(page: 1);
      if (!mounted || generation != _generation) return;
      setState(() => _page = result);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = error is TrackingException
            ? error.message
            : 'Unable to load dashboard information.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _openProfile() {
    final service = widget.profileService;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile service is not configured.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ApplicantProfileView(service: service),
      ),
    );
  }

  void _openJobs() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => JobDiscoveryView(service: widget.jobDiscoveryService),
    ),
  );
  void _openApplications() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ApplicationTrackingView(service: widget.trackingService),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent =
        _page?.items.take(3).toList(growable: false) ??
        const <ApplicationRecord>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicant Dashboard'),
        actions: [
          IconButton(
            key: const Key('dashboard-sign-out'),
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text('Welcome back', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                widget.identity.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_history_outlined,
                        size: 34,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total applications',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_loading && _page == null)
                              const SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(),
                              )
                            else
                              Text(
                                _page?.total.toString() ?? '—',
                                key: const Key('dashboard-total-applications'),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Quick actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              _ActionTile(
                key: const Key('dashboard-find-jobs'),
                icon: Icons.search,
                title: 'Find jobs',
                subtitle: 'Explore and search available opportunities',
                onTap: _openJobs,
              ),
              _ActionTile(
                key: const Key('dashboard-my-applications'),
                icon: Icons.assignment_outlined,
                title: 'My applications',
                subtitle: 'Review your submitted applications and progress',
                onTap: _openApplications,
              ),
              _ActionTile(
                key: const Key('dashboard-my-profile'),
                icon: Icons.person_outline,
                title: 'My profile',
                subtitle: 'View and update your applicant information',
                onTap: _openProfile,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent applications',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    key: const Key('dashboard-view-all'),
                    onPressed: _openApplications,
                    child: const Text('View all'),
                  ),
                ],
              ),
              if (_loading && _page == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _page == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          key: const Key('dashboard-load-error'),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No applications yet. Explore available jobs to get started.',
                      key: Key('dashboard-no-applications'),
                    ),
                  ),
                )
              else
                ...recent.map(
                  (record) => Card(
                    child: ListTile(
                      key: Key('dashboard-recent-${record.id}'),
                      leading: const CircleAvatar(
                        child: Icon(Icons.work_outline),
                      ),
                      title: Text(
                        record.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${record.companyName}\nApplied: ${formatApplicationDate(record.appliedAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Chip(label: Text(record.status)),
                      onTap: _openApplications,
                    ),
                  ),
                ),
              if (_error != null && _page != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
