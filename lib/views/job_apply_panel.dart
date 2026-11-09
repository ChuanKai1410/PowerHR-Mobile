import 'package:flutter/material.dart';

import '../services/job_application_service.dart';

class JobApplyPanel extends StatefulWidget {
  const JobApplyPanel({
    required this.postingId,
    required this.service,
    super.key,
  });
  final String postingId;
  final JobApplicationService service;

  @override
  State<JobApplyPanel> createState() => _JobApplyPanelState();
}

class _JobApplyPanelState extends State<JobApplyPanel> {
  bool _loading = true;
  bool _submitting = false;
  bool _applied = false;
  String? _status;
  String? _selectedId;
  String? _error;
  List<AvailableResume> _resumes = const [];

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
      final status = await widget.service.getStatus(widget.postingId);
      if (!mounted) return;
      if (status.applied) {
        setState(() {
          _applied = true;
          _status = status.status;
        });
      } else {
        final resumes = await widget.service.getMyResumes();
        if (!mounted) return;
        setState(() {
          _applied = false;
          _resumes = resumes;
          _selectedId = resumes.isEmpty ? null : resumes.first.id;
        });
      }
    } on JobApplicationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load application information.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting || _selectedId == null || _applied) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit application?'),
        content: const Text(
          'Your selected resume will be included with this application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.service.submit(
        postingId: widget.postingId,
        resumeId: _selectedId!,
      );
      if (!mounted) return;
      setState(() {
        _applied = true;
        _status = 'New';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
    } on JobApplicationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
      // A 409 might mean another request completed first; re-check only then.
      if (e.message.contains('already applied')) {
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to submit application.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Apply for this job',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_applied)
          Text(
            'Already applied${_status == null ? '' : ' · $_status'}',
            key: const Key('job-already-applied'),
          )
        else ...[
          if (_resumes.isEmpty)
            const Text(
              'No resume found. Create your resume before applying.',
              key: Key('job-no-resume'),
            ),
          if (_resumes.isNotEmpty)
            DropdownButtonFormField<String>(
              key: const Key('job-resume-select'),
              initialValue: _selectedId,
              decoration: const InputDecoration(
                labelText: 'Select saved resume',
              ),
              items: _resumes
                  .map(
                    (resume) => DropdownMenuItem(
                      value: resume.id,
                      child: Text(
                        resume.title.isEmpty
                            ? resume.name
                            : '${resume.name} · ${resume.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) => setState(() {
                      _selectedId = v;
                    }),
            ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('job-apply-submit'),
            onPressed: _selectedId == null || _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Apply now'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const Key('job-application-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loading || _submitting ? null : _load,
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}
