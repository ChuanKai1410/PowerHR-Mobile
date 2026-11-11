import 'package:flutter/material.dart';
import '../models/employee_company.dart';
import '../services/employee_company_service.dart';

class EmployeeCompanyView extends StatefulWidget {
  const EmployeeCompanyView({required this.service, super.key});
  final EmployeeCompanyService service;
  @override
  State<EmployeeCompanyView> createState() => _EmployeeCompanyViewState();
}

class _EmployeeCompanyViewState extends State<EmployeeCompanyView> {
  EmployeeCompany? _company;
  List<EmployeeDepartment>? _departments;
  String? _error;
  String? _departmentsError;
  bool _loading = true;
  bool _departmentsLoading = false;
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
      _company = null;
      _departments = null;
      _departmentsError = null;
    });
    try {
      final result = await widget.service.getOverview();
      if (!mounted || generation != _generation) return;
      setState(() {
        _company = result;
        _departments = null;
        _departmentsError = null;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = error is EmployeeCompanyException
            ? error.message
            : 'Unable to load company overview.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadDepartments() async {
    if (_departmentsLoading ||
        _company?.capabilities.canReadDepartments != true) {
      return;
    }
    final generation = _generation;
    setState(() {
      _departmentsLoading = true;
      _departmentsError = null;
    });
    try {
      final result = await widget.service.getDepartments();
      if (!mounted || generation != _generation) return;
      setState(() => _departments = result);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _departmentsError = error is EmployeeCompanyException
            ? error.message
            : 'Unable to load departments.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _departmentsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;
    return Scaffold(
      appBar: AppBar(title: const Text('My company')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading && company == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null) ...[
                Text(_error!, key: const Key('company-error')),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
              if (company != null) ...[
                Text(
                  company.name,
                  key: const Key('company-name'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (company.location.isNotEmpty) Text(company.location),
                if (company.sector.isNotEmpty)
                  Text('Sector: ${company.sector}'),
                if (company.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  Text(company.description),
                ],
                if (company.website.isNotEmpty)
                  Text('Website: ${company.website}'),
                const SizedBox(height: 20),
                Text(
                  'Available capabilities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  company.capabilities.canManageHiring
                      ? 'Recruitment management: server eligible (not enabled in this module)'
                      : 'Recruitment management: unavailable',
                ),
                Text(
                  company.capabilities.canManageCompany
                      ? 'Company administration: server eligible (not enabled in this module)'
                      : 'Company administration: unavailable',
                ),
                const SizedBox(height: 16),
                if (company.capabilities.canReadDepartments) ...[
                  OutlinedButton.icon(
                    key: const Key('company-load-departments'),
                    onPressed: _departmentsLoading ? null : _loadDepartments,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('View departments'),
                  ),
                  if (_departmentsLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_departmentsError != null)
                    Text(
                      _departmentsError!,
                      key: const Key('departments-error'),
                    ),
                  if (_departments != null) ...[
                    Text(
                      'Departments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_departments!.isEmpty)
                      const Text('No departments found.'),
                    for (final dept in _departments!)
                      ListTile(title: Text(dept.name)),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
