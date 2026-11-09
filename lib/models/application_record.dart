class ApplicationRecord {
  const ApplicationRecord({
    required this.id,
    required this.title,
    required this.companyName,
    required this.status,
    this.postingId,
    this.employmentType = '',
    this.appliedAt,
    this.statusUpdatedAt,
    this.postingAvailable = false,
    this.description = '',
    this.interviews = const [],
    this.offerStatus,
  });

  final String id;
  final String title;
  final String companyName;
  final String status;
  final String? postingId;
  final String employmentType;
  final DateTime? appliedAt;
  final DateTime? statusUpdatedAt;
  final bool postingAvailable;
  final String description;
  final List<InterviewRecord> interviews;
  final String? offerStatus;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory ApplicationRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final company = json['companyName'];
    final status = json['status'];
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        company is! String ||
        status is! String ||
        status.isEmpty) {
      throw const FormatException('Invalid application record');
    }
    final rawInterviews = json['interviews'];
    if (rawInterviews != null && rawInterviews is! List) {
      throw const FormatException('Invalid interview records');
    }
    final List<dynamic> interviewItems = rawInterviews is List
        ? rawInterviews
        : const <dynamic>[];
    return ApplicationRecord(
      id: id,
      title: title,
      companyName: company,
      status: status,
      postingId: json['postingId'] is String
          ? json['postingId'] as String
          : null,
      employmentType: json['employmentType'] is String
          ? json['employmentType'] as String
          : '',
      appliedAt: _date(json['appliedAt']),
      statusUpdatedAt: _date(json['statusUpdatedAt']),
      postingAvailable: json['postingAvailable'] == true,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      offerStatus: json['offerStatus'] is String
          ? json['offerStatus'] as String
          : null,
      interviews: interviewItems.map<InterviewRecord>((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid interview record');
        }
        return InterviewRecord.fromJson(item);
      }).toList(),
    );
  }
}

class InterviewRecord {
  const InterviewRecord({this.date, this.type, this.status});
  final DateTime? date;
  final String? type;
  final String? status;

  factory InterviewRecord.fromJson(Map<String, dynamic> json) =>
      InterviewRecord(
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        type: json['type'] is String ? json['type'] as String : null,
        status: json['status'] is String ? json['status'] as String : null,
      );
}

String formatApplicationDate(DateTime? value) {
  if (value == null) return 'Not available';
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
