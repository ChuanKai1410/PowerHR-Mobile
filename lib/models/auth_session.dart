class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.token,
  });

  final String userId;
  final String email;
  // A presentation label, not a client-side authorization grant.
  final String role;
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response.');
    }
    String requiredString(Object? value) {
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid login response.');
      }
      return value;
    }

    return AuthSession(
      userId: requiredString(user['_id']),
      email: requiredString(user['email']),
      role: requiredString(user['role']),
      token: requiredString(json['token']),
    );
  }
}
