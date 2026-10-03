class BackendStatus {
  const BackendStatus({required this.environment});

  factory BackendStatus.fromJson(Map<String, dynamic> json) {
    if (json['root'] != true ||
        json['env'] is! String ||
        (json['env'] as String).trim().isEmpty) {
      throw const FormatException('Unexpected backend root response.');
    }
    return BackendStatus(environment: json['env'] as String);
  }

  final String environment;
}
