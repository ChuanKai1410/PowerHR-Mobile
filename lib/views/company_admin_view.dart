import 'package:flutter/material.dart';
import '../services/company_admin_service.dart';

class CompanyAdminView extends StatefulWidget {
  const CompanyAdminView({required this.service, super.key});
  final CompanyAdminService service;
  @override
  State<CompanyAdminView> createState() => _CompanyAdminViewState();
}

class _CompanyAdminViewState extends State<CompanyAdminView> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _version++;
    super.dispose();
  }

  List<Map<String, dynamic>> _readItems(Map<String, dynamic> json) {
    final rows = json['items'];
    if (rows is! List) throw const FormatException('Invalid list');
    return rows.map<Map<String, dynamic>>((row) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Invalid row');
      }
      if (row['id'] is! String || row['name'] is! String) {
        throw const FormatException('Invalid record');
      }
      return row;
    }).toList();
  }

  Future<void> _load({bool next = false}) async {
    if (_loading) return;
    final token = ++_version;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requestedPage = next ? _page + 1 : 1;
      final responses = await Future.wait([
        widget.service.employees(page: requestedPage),
        if (!next) widget.service.departments(),
      ]);
      final employeeRows = _readItems(responses.first);
      if (responses.first['hasMore'] is! bool) {
        throw const FormatException('Invalid pagination');
      }
      final departmentRows = next ? null : _readItems(responses.last);
      if (!mounted || token != _version) return;
      setState(() {
        _employees = next ? [..._employees, ...employeeRows] : employeeRows;
        if (departmentRows != null) _departments = departmentRows;
        _page = requestedPage;
        _hasMore = responses.first['hasMore'] as bool;
      });
    } catch (e) {
      if (!mounted || token != _version) return;
      setState(() {
        _error = e is CompanyAdminException
            ? e.message
            : 'Unable to load company administration.';
        _employees = [];
        _departments = [];
        _hasMore = false;
      });
    } finally {
      if (mounted && token == _version) setState(() => _loading = false);
    }
  }

  Future<void> _editDepartment({Map<String, dynamic>? department}) async {
    final controller = TextEditingController(
      text: department?['name'] as String? ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          department == null ? 'New department' : 'Rename department',
        ),
        content: TextField(
          controller: controller,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Department name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    if (name.length < 2 || name.length > 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department name must be 2 to 80 characters.'),
        ),
      );
      return;
    }
    try {
      if (department == null) {
        await widget.service.createDepartment(name);
      } else {
        await widget.service.renameDepartment(department['id'] as String, name);
      }
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is CompanyAdminException
                ? e.message
                : 'Unable to save department.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Company administration')),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Departments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('admin-add-department'),
              onPressed: _loading ? null : () => _editDepartment(),
              icon: const Icon(Icons.add),
              label: const Text('Add department'),
            ),
            if (_departments.isEmpty && !_loading)
              const Text('No departments to display.'),
            for (final dept in _departments)
              ListTile(
                key: Key('admin-department-${dept['id']}'),
                title: Text(dept['name'] as String),
                trailing: IconButton(
                  tooltip: 'Rename department',
                  onPressed: _loading
                      ? null
                      : () => _editDepartment(department: dept),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            const Divider(),
            Text(
              'Employee directory (read-only)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final employee in _employees)
              ListTile(
                key: Key('admin-employee-${employee['id']}'),
                leading: const Icon(Icons.person_outline),
                title: Text(employee['name'] as String),
                subtitle: Text(
                  employee['jobTitle'] is String
                      ? employee['jobTitle'] as String
                      : '',
                ),
              ),
            if (_employees.isEmpty && !_loading)
              const Text('No employees to display.'),
            if (_hasMore && !_loading)
              OutlinedButton(
                onPressed: () => _load(next: true),
                child: const Text('Load more'),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null) ...[
              Text(_error!, key: const Key('admin-error')),
              TextButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
            const SizedBox(height: 12),
            const Text(
              'Employee edits, compensation and account permissions are not available on Mobile.',
            ),
          ],
        ),
      ),
    ),
  );
}
