import 'package:flutter/material.dart';

import '../models/applicant_profile.dart';
import '../services/applicant_profile_service.dart';

class ApplicantProfileView extends StatefulWidget {
  const ApplicantProfileView({required this.service, super.key});
  final ApplicantProfileService service;
  @override
  State<ApplicantProfileView> createState() => _ApplicantProfileViewState();
}

class _ApplicantProfileViewState extends State<ApplicantProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String _gender = 'Prefer not to say';
  ApplicantProfile? _profile;
  bool _busy = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final profile = await widget.service.fetch();
      if (!mounted) return;
      _setProfile(profile);
    } on ProfileUnauthorized {
      if (!mounted) return;
      setState(
        () => _error = 'Session expired or access denied. Sign in again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load profile. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setProfile(ApplicantProfile profile) {
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    setState(() {
      _profile = profile;
      _gender = profile.gender;
    });
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.service.update(
        firstName: _firstName.text,
        lastName: _lastName.text,
        gender: _gender,
      );
      // Re-read the authoritative persisted record.
      final verified = await widget.service.fetch();
      if (!mounted) return;
      _setProfile(verified);
      setState(() => _success = 'Profile updated successfully.');
    } on ProfileUnauthorized {
      if (mounted) {
        setState(
          () => _error = 'Session expired or access denied. Sign in again.',
        );
      }
    } on ProfileRejected catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to save or verify profile. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _busy && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Text(
                        _error!,
                        key: const Key('profile-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (_success != null)
                      Text(
                        _success!,
                        key: const Key('profile-success'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    if (_profile == null) ...[
                      const Text('Profile unavailable.'),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ] else ...[
                      const Icon(Icons.account_circle_outlined, size: 72),
                      const SizedBox(height: 12),
                      Text(
                        'Email: ${_profile!.email}',
                        key: const Key('profile-email'),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('profile-first-name'),
                        controller: _firstName,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'First name is required.'
                            : null,
                      ),
                      TextFormField(
                        key: const Key('profile-last-name'),
                        controller: _lastName,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Last name is required.'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        key: const Key('profile-gender'),
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _gender = value);
                                }
                              },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('profile-save'),
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? 'Saving...' : 'Save changes'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _load,
                        child: const Text('Reload'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
