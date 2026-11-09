class ApplicantProfile {
  const ApplicantProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.profilePicture,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String? profilePicture;

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    if (profile is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile response');
    }
    String string(String key) {
      final value = profile[key];
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid profile response');
      }
      return value;
    }

    final picture = profile['profilePicture'];
    if (picture != null && picture is! String) {
      throw const FormatException('Invalid profile response');
    }
    return ApplicantProfile(
      userId: string('userId'),
      firstName: string('firstName'),
      lastName: string('lastName'),
      email: string('email'),
      gender: string('gender'),
      profilePicture: picture as String?,
    );
  }
}
