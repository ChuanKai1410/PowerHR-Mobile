import 'package:flutter/material.dart';

import '../models/job_listing.dart';
import '../services/job_discovery_service.dart';
import 'job_detail_view.dart';

class JobDiscoveryView extends StatefulWidget {
  const JobDiscoveryView({required this.service, super.key});
  final JobDiscoveryService service;

  @override
  State<JobDiscoveryView> createState() => _JobDiscoveryViewState();
}

class _JobDiscoveryViewState extends State<JobDiscoveryView> {
  final _search = TextEditingController();
  final List<JobListing> _items = [];
  String _type = '';
  String? _error;
  bool _loading = false;
  bool _hasMore = false;
  int _page = 0;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _requestGeneration++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final generation = ++_requestGeneration;
    final nextPage = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _hasMore = false;
      }
    });
    try {
      final result = await widget.service.fetchPage(
        page: nextPage,
        search: _search.text,
        type: _type,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _items.addAll(result.items);
        _page = nextPage;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = e is JobDiscoveryException
            ? e.message
            : 'Unable to load jobs.';
      });
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find jobs')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    key: const Key('job-search'),
                    controller: _search,
                    maxLength: 100,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Job title or company',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _load(reset: true),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                  DropdownButtonFormField<String>(
                    key: const Key('job-type-filter'),
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Employment type',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All types')),
                      DropdownMenuItem(
                        value: 'full-time',
                        child: Text('Full-time'),
                      ),
                      DropdownMenuItem(
                        value: 'part-time',
                        child: Text('Part-time'),
                      ),
                      DropdownMenuItem(
                        value: 'internship',
                        child: Text('Internship'),
                      ),
                      DropdownMenuItem(
                        value: 'contract',
                        child: Text('Contract'),
                      ),
                      DropdownMenuItem(
                        value: 'freelance',
                        child: Text('Freelance'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _type = value ?? '';
                      });
                      _load(reset: true);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, key: const Key('job-error')),
                          TextButton(
                            onPressed: () => _load(reset: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _items.isEmpty
                  ? const Center(
                      child: Text('No open jobs found.', key: Key('job-empty')),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      child: ListView.builder(
                        itemCount: _items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  if (_error != null) Text(_error!),
                                  if (_loading)
                                    const CircularProgressIndicator(),
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
                          final job = _items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              key: Key('job-${job.id}'),
                              title: Text(job.title),
                              subtitle: Text(
                                '${job.companyName} · ${job.employmentType}${job.companyLocation.isEmpty ? '' : '\nCompany address: ${job.companyLocation}'}',
                              ),
                              isThreeLine: job.companyLocation.isNotEmpty,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => JobDetailView(job: job),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
