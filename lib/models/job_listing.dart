class JobListing {
  const JobListing({
    required this.id,
    required this.title,
    required this.companyName,
    required this.employmentType,
    required this.description,
    required this.qualification,
    this.companyCity = '',
    this.companyState = '',
    this.industry = '',
    this.environment = '',
    this.salaryMin,
    this.salaryMax,
    this.deadline,
    this.experienceMin,
    this.experienceMax,
  });

  final String id;
  final String title;
  final String companyName;
  final String employmentType;
  final String description;
  final String qualification;
  final String companyCity;
  final String companyState;
  final String industry;
  final String environment;
  final num? salaryMin;
  final num? salaryMax;
  final DateTime? deadline;
  final num? experienceMin;
  final num? experienceMax;

  String get companyLocation {
    final parts = [companyCity, companyState].where((e) => e.trim().isNotEmpty);
    return parts.join(', ');
  }

  static String _required(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Invalid job listing response');
    }
    return value;
  }

  factory JobListing.fromJson(Map<String, dynamic> json) {
    String optional(Object? v) => v is String ? v : '';
    num? numeric(Object? v) => v is num ? v : null;
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return JobListing(
      id: _required(json['id']),
      title: _required(json['title']),
      companyName: _required(json['companyName']),
      employmentType: _required(json['employmentType']),
      description: optional(json['description']),
      qualification: optional(json['qualification']),
      companyCity: optional(json['companyCity']),
      companyState: optional(json['companyState']),
      industry: optional(json['industry']),
      environment: optional(json['environment']),
      salaryMin: numeric(json['salaryMin']),
      salaryMax: numeric(json['salaryMax']),
      deadline: date(json['deadline']),
      experienceMin: numeric(json['experienceMin']),
      experienceMax: numeric(json['experienceMax']),
    );
  }
}

class JobPage {
  const JobPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
  });
  final List<JobListing> items;
  final int page;
  final bool hasMore;
  final int total;

  factory JobPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List ||
        json['page'] is! int ||
        json['total'] is! int ||
        json['hasMore'] is! bool) {
      throw const FormatException('Invalid job page');
    }
    return JobPage(
      items: items
          .map((e) {
            if (e is! Map<String, dynamic>) {
              throw const FormatException('Invalid job item');
            }
            return JobListing.fromJson(e);
          })
          .toList(growable: false),
      page: json['page'] as int,
      total: json['total'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}
