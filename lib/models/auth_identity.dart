class AuthIdentity {
  const AuthIdentity({
    required this.userId,
    required this.email,
    required this.role,
    this.company,
  });

  final String userId;
  final String email;
  // Server's presentation field. For Employee this is jobTitle,
  // NOT a trusted authorization grant or an account-type discriminator.
  final String role;
  final String? company;

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

    final companyValue = user['company'];
    if (companyValue != null && companyValue is! String) {
      throw const FormatException('Invalid current-user response.');
    }
    return AuthIdentity(
      userId: requiredString(user['_id']),
      email: requiredString(user['email']),
      role: requiredString(user['role']),
      company: companyValue as String?,
    );
  }
}
