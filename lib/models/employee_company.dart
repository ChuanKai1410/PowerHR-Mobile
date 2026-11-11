class EmployeeCapabilities {
  const EmployeeCapabilities({
    required this.canReadDepartments,
    required this.canManageHiring,
    required this.canManageCompany,
  });
  final bool canReadDepartments;
  final bool canManageHiring;
  final bool canManageCompany;

  factory EmployeeCapabilities.fromJson(Map<String, dynamic> json) {
    final read = json['canReadDepartments'];
    final hiring = json['canManageHiring'];
    final company = json['canManageCompany'];
    if (read is! bool || hiring is! bool || company is! bool) {
      throw const FormatException('Invalid company capabilities.');
    }
    return EmployeeCapabilities(
      canReadDepartments: read,
      canManageHiring: hiring,
      canManageCompany: company,
    );
  }
}

class EmployeeCompany {
  const EmployeeCompany({
    required this.id,
    required this.name,
    required this.capabilities,
    this.description = '',
    this.website = '',
    this.sector = '',
    this.city = '',
    this.state = '',
    this.country = '',
  });
  final String id;
  final String name;
  final EmployeeCapabilities capabilities;
  final String description;
  final String website;
  final String sector;
  final String city;
  final String state;
  final String country;

  String get location =>
      [city, state, country].where((v) => v.isNotEmpty).join(', ');

  factory EmployeeCompany.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    final permission = json['capabilities'];
    if (company is! Map<String, dynamic> ||
        permission is! Map<String, dynamic>) {
      throw const FormatException('Invalid company overview.');
    }
    final id = company['id'];
    final name = company['name'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid company overview.');
    }
    String optional(String key) =>
        company[key] is String ? company[key] as String : '';
    return EmployeeCompany(
      id: id,
      name: name,
      capabilities: EmployeeCapabilities.fromJson(permission),
      description: optional('description'),
      website: optional('website'),
      sector: optional('sector'),
      city: optional('city'),
      state: optional('state'),
      country: optional('country'),
    );
  }
}

class EmployeeDepartment {
  const EmployeeDepartment({required this.id, required this.name});
  final String id;
  final String name;
  factory EmployeeDepartment.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String || json['name'] is! String) {
      throw const FormatException('Invalid department record.');
    }
    return EmployeeDepartment(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
