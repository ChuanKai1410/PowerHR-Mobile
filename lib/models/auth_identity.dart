enum AccountType { applicant, employee, sysAdmin, unknown }

class AuthIdentity {
  const AuthIdentity({
    required this.userId,
    required this.email,
    required this.role,
    this.accountType = AccountType.unknown,
    this.jobTitle,
    this.company,
  });

  final String userId;
  final String email;
  // Retained for compatibility with the existing API and Phase 2 tests.
  // This is a display label, NEVER a server authorization grant.
  final String role;
  final AccountType accountType;
  final String? jobTitle;
  final String? company;

  String get displayTitle => switch (accountType) {
    AccountType.applicant => 'Applicant',
    AccountType.employee => jobTitle!,
    AccountType.sysAdmin => 'System administrator',
    AccountType.unknown => 'Unknown account',
  };

  factory AuthIdentity.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid current-user response.');
    }
    String requiredString(Object? value) {
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid current-user response.');
      }
      return value;
    }

    String? optionalString(Object? value) {
      if (value == null) return null;
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid current-user response.');
      }
      return value;
    }

    final type = switch (user['accountType']) {
      'Applicant' => AccountType.applicant,
      'Employee' => AccountType.employee,
      'SysAdmin' => AccountType.sysAdmin,
      _ => throw const FormatException('Unsupported account type.'),
    };
    final title = optionalString(user['jobTitle']);
    if (type == AccountType.employee && title == null) {
      throw const FormatException('Employee job title is required.');
    }
    if (type != AccountType.employee && title != null) {
      throw const FormatException('Unexpected job title.');
    }
    return AuthIdentity(
      userId: requiredString(user['_id']),
      email: requiredString(user['email']),
      role: requiredString(user['role']),
      accountType: type,
      jobTitle: title,
      company: optionalString(user['company']),
    );
  }
}
