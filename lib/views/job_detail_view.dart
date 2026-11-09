import 'package:flutter/material.dart';

import '../models/job_listing.dart';
import '../models/app_config.dart';
import '../services/token_store.dart';
import '../services/job_application_service.dart';
import 'job_apply_panel.dart';

class JobDetailView extends StatelessWidget {
  const JobDetailView({required this.job, super.key});
  final JobListing job;

  @override
  Widget build(BuildContext context) {
    final location = job.companyLocation;
    final salary = job.salaryMin == null && job.salaryMax == null
        ? 'Not specified'
        : '${job.salaryMin ?? '—'} – ${job.salaryMax ?? '—'} (currency not specified)';
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              job.companyName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (location.isNotEmpty) Text('Company address: $location'),
            const SizedBox(height: 16),
            Chip(label: Text(job.employmentType)),
            _section(context, 'Description', job.description),
            _section(context, 'Qualification', job.qualification),
            _section(context, 'Salary range', salary),
            _section(context, 'Industry', job.industry),
            _section(context, 'Work environment', job.environment),
            _section(
              context,
              'Minimum experience',
              job.experienceMin?.toString() ?? 'Not specified',
            ),
            _section(
              context,
              'Application deadline',
              job.deadline?.toLocal().toString().split(' ').first ??
                  'Not specified',
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final api = AppConfig.fromEnvironment().apiBaseUri;
                if (api == null) return const Text('API is not configured.');
                return JobApplyPanel(
                  postingId: job.id,
                  service: JobApplicationService(api, const SecureTokenStore()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String heading, String value) =>
      Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(value.isEmpty ? 'Not specified' : value),
          ],
        ),
      );
}
