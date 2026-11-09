import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/job_listing.dart';

void main() {
  final job = {
    'id': 'abc123',
    'title': 'Software Engineer',
    'companyName': 'Example Company',
    'employmentType': 'full-time',
    'description': 'Build software',
    'qualification': 'Degree',
    'companyCity': 'Muar',
    'companyState': 'Johor',
  };
  test('parses a valid job', () {
    final result = JobListing.fromJson(job);
    expect(result.title, 'Software Engineer');
    expect(result.companyLocation, 'Muar, Johor');
  });
  test('invalid required fields fail closed', () {
    expect(
      () => JobListing.fromJson({...job, 'title': null}),
      throwsFormatException,
    );
  });
  test('parses pagination envelope', () {
    final result = JobPage.fromJson({
      'items': [job],
      'page': 1,
      'total': 1,
      'hasMore': false,
    });
    expect(result.items, hasLength(1));
    expect(result.hasMore, false);
  });
}
