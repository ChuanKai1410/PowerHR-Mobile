class HrPosting {
  const HrPosting({
    required this.id,
    required this.title,
    required this.status,
    required this.employmentType,
  });
  final String id, title, status, employmentType;
  factory HrPosting.fromJson(Map<String, dynamic> json) {
    final id = json['id'], title = json['title'], status = json['status'];
    if (id is! String || id.isEmpty || title is! String || status is! String) {
      throw const FormatException('Invalid posting');
    }
    return HrPosting(
      id: id,
      title: title,
      status: status,
      employmentType: json['employmentType'] is String
          ? json['employmentType'] as String
          : '',
    );
  }
}

class HrApplication {
  const HrApplication({
    required this.id,
    required this.applicantName,
    required this.status,
  });
  final String id, applicantName, status;
  factory HrApplication.fromJson(Map<String, dynamic> json) {
    final id = json['id'],
        name = json['applicantName'],
        status = json['status'];
    if (id is! String || id.isEmpty || name is! String || status is! String) {
      throw const FormatException('Invalid application');
    }
    return HrApplication(id: id, applicantName: name, status: status);
  }
}

class HrPage<T> {
  const HrPage({
    required this.items,
    required this.hasMore,
    required this.total,
  });
  final List<T> items;
  final bool hasMore;
  final int total;
}
