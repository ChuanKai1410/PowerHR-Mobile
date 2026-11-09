import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/services/job_application_service.dart';

void main() {
  test('resume metadata parses without exposing owner identifiers', () {
    final resume = AvailableResume.fromJson({
      'id': '507f1f77bcf86cd799439011',
      'name': 'Example Applicant',
      'title': 'Developer',
    });
    expect(resume.id, '507f1f77bcf86cd799439011');
    expect(resume.title, 'Developer');
  });
  test('resume without id is rejected', () {
    expect(
      () => AvailableResume.fromJson({'name': 'Missing ID'}),
      throwsFormatException,
    );
  });
  test('application status is explicit', () {
    const status = ApplicationStatus(applied: true, status: 'New');
    expect(status.applied, isTrue);
    expect(status.status, 'New');
  });
}
