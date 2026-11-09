import 'package:flutter/material.dart';

import '../models/application_record.dart';
import '../services/application_tracking_service.dart';

class ApplicationTrackingView extends StatefulWidget {
  const ApplicationTrackingView({required this.service, super.key});
  final ApplicationTrackingService service;

  @override
  State<ApplicationTrackingView> createState() =>
      _ApplicationTrackingViewState();
}

class _ApplicationTrackingViewState extends State<ApplicationTrackingView> {
  final _records = <ApplicationRecord>[];
  bool _loading = false;
  bool _hasMore = false;
  String? _error;
  int _page = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final generation = ++_generation;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _records.clear();
        _page = 0;
        _hasMore = false;
      }
    });
    try {
      final result = await widget.service.fetchPage(page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        _records.addAll(result.items);
        _hasMore = result.hasMore;
        _page = page;
      });
    } catch (error, stackTrace) {
      debugPrint('[TRACKING ERROR] $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || generation != _generation) {
        return;
      }

      setState(() {
        _error = error is TrackingException
            ? error.message
            : 'Unable to load applications. Check Flutter console.';
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My applications')),
    body: SafeArea(
      child: _loading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, key: const Key('tracking-error')),
                  TextButton(
                    onPressed: () => _load(reset: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _records.isEmpty
          ? const Center(
              child: Text('No applications yet.', key: Key('tracking-empty')),
            )
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView.builder(
                itemCount: _records.length + 1,
                itemBuilder: (context, index) {
                  if (index == _records.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_error != null) Text(_error!),
                          if (_loading) const CircularProgressIndicator(),
                          if (_hasMore && !_loading)
                            OutlinedButton(
                              onPressed: () => _load(),
                              child: const Text('Load more'),
                            ),
                          if (_error != null && !_loading)
                            TextButton(
                              onPressed: () => _load(),
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    );
                  }
                  final record = _records[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      key: Key('application-${record.id}'),
                      title: Text(record.title),
                      subtitle: Text(
                        '${record.companyName}\nApplied: ${formatApplicationDate(record.appliedAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Chip(label: Text(record.status)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ApplicationTrackingDetailView(
                            service: widget.service,
                            applicationId: record.id,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    ),
  );
}

class ApplicationTrackingDetailView extends StatefulWidget {
  const ApplicationTrackingDetailView({
    required this.service,
    required this.applicationId,
    super.key,
  });
  final ApplicationTrackingService service;
  final String applicationId;

  @override
  State<ApplicationTrackingDetailView> createState() =>
      _ApplicationTrackingDetailViewState();
}

class _ApplicationTrackingDetailViewState
    extends State<ApplicationTrackingDetailView> {
  ApplicationRecord? _record;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.service.getDetails(widget.applicationId);
      if (!mounted) return;
      setState(() => _record = result);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is TrackingException
            ? error.message
            : 'Unable to load details.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Application details')),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, key: const Key('tracking-detail-error')),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _record!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _record!.companyName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _item('Application status', _record!.status),
                _item('Applied on', formatApplicationDate(_record!.appliedAt)),
                _item(
                  'Status updated',
                  formatApplicationDate(_record!.statusUpdatedAt),
                ),
                if (_record!.employmentType.isNotEmpty)
                  _item('Employment type', _record!.employmentType),
                if (_record!.description.isNotEmpty)
                  _item('Job description', _record!.description),
                if (!_record!.postingAvailable)
                  const Text('This posting is no longer available.'),
                if (_record!.offerStatus != null)
                  _item('Offer status', _record!.offerStatus!),
                if (_record!.interviews.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Interviews',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final interview in _record!.interviews)
                    ListTile(
                      title: Text(interview.type ?? 'Interview'),
                      subtitle: Text(formatApplicationDate(interview.date)),
                      trailing: Text(interview.status ?? ''),
                    ),
                ],
              ],
            ),
    ),
  );

  Widget _item(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );
}
