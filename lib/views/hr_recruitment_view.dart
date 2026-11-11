import 'package:flutter/material.dart';
import '../models/hr_recruitment.dart';
import '../services/hr_recruitment_service.dart';

class HrRecruitmentView extends StatefulWidget {
  const HrRecruitmentView({required this.service, super.key});
  final HrRecruitmentService service;
  @override
  State<HrRecruitmentView> createState() => _HrRecruitmentViewState();
}

class _HrRecruitmentViewState extends State<HrRecruitmentView> {
  final List<HrPosting> _items = [];
  int _page = 0, _generation = 0;
  bool _loading = false, _more = false;
  String? _error;
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
        _items.clear();
        _page = 0;
        _more = false;
      }
    });
    try {
      final result = await widget.service.postings(page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _more = result.hasMore;
        _page = page;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = error is HrRecruitmentException
            ? error.message
            : 'Unable to load postings.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recruitment management')),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading && _items.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!, key: const Key('hr-postings-error')),
              TextButton(
                onPressed: () => _load(reset: _page == 0),
                child: const Text('Retry'),
              ),
            ],
            if (!_loading && _error == null && _items.isEmpty)
              const Text(
                'No company postings found.',
                key: Key('hr-postings-empty'),
              ),
            for (final posting in _items)
              Card(
                child: ListTile(
                  key: Key('hr-posting-${posting.id}'),
                  title: Text(posting.title),
                  subtitle: Text(
                    '${posting.employmentType} · ${posting.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HrPostingApplicationsView(
                        service: widget.service,
                        posting: posting,
                      ),
                    ),
                  ),
                ),
              ),
            if (_loading && _items.isNotEmpty)
              const Center(child: CircularProgressIndicator()),
            if (_more && !_loading)
              OutlinedButton(
                onPressed: () => _load(),
                child: const Text('Load more'),
              ),
          ],
        ),
      ),
    ),
  );
}

class HrPostingApplicationsView extends StatefulWidget {
  const HrPostingApplicationsView({
    required this.service,
    required this.posting,
    super.key,
  });
  final HrRecruitmentService service;
  final HrPosting posting;
  @override
  State<HrPostingApplicationsView> createState() =>
      _HrPostingApplicationsViewState();
}

class _HrPostingApplicationsViewState extends State<HrPostingApplicationsView> {
  final List<HrApplication> _items = [];
  int _page = 0, _generation = 0;
  bool _loading = false, _more = false;
  String? _error;
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
        _items.clear();
        _page = 0;
        _more = false;
      }
    });
    try {
      final result = await widget.service.applications(
        widget.posting.id,
        page: page,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _more = result.hasMore;
        _page = page;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = error is HrRecruitmentException
            ? error.message
            : 'Unable to load applications.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _update(HrApplication application) async {
    const statuses = [
      'New',
      'Viewed',
      'Pending',
      'Interviewed',
      'Accepted',
      'Rejected',
    ];
    String chosen = statuses.contains(application.status)
        ? application.status
        : 'New';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Update application status'),
          content: DropdownButtonFormField<String>(
            key: const Key('hr-status-select'),
            initialValue: chosen,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (next) {
              if (next != null) refresh(() => chosen = next);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: chosen == application.status
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await widget.service.updateStatus(
        widget.posting.id,
        application.id,
        chosen,
      );
      if (!mounted) return;
      await _load(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is HrRecruitmentException
                ? error.message
                : 'Unable to update status.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.posting.title)),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Applications', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_loading && _items.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!, key: const Key('hr-applications-error')),
              TextButton(
                onPressed: () => _load(reset: _page == 0),
                child: const Text('Retry'),
              ),
            ],
            if (!_loading && _error == null && _items.isEmpty)
              const Text(
                'No applications for this posting.',
                key: Key('hr-applications-empty'),
              ),
            for (final application in _items)
              Card(
                child: ListTile(
                  key: Key('hr-application-${application.id}'),
                  title: Text(application.applicantName),
                  subtitle: Text('Status: ${application.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Change status',
                    onPressed: () => _update(application),
                  ),
                ),
              ),
            if (_loading && _items.isNotEmpty)
              const Center(child: CircularProgressIndicator()),
            if (_more && !_loading)
              OutlinedButton(
                onPressed: () => _load(),
                child: const Text('Load more'),
              ),
          ],
        ),
      ),
    ),
  );
}
