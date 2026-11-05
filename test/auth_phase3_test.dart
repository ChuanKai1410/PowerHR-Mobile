import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/auth_identity.dart';
import 'package:powerhr_mobile/models/workspace_destination.dart';

Map<String, dynamic> response(String type, {String? title}) => {
  'user': {
    '_id': '123',
    'email': 'test@example.invalid',
    'role': title ?? type,
    'accountType': type,
    'jobTitle': title,
    'company': null,
  },
};

void main() {
  test('Applicant navigates to applicant workspace', () {
    final id = AuthIdentity.fromJson(response('Applicant'));
    expect(id.accountType, AccountType.applicant);
    expect(id.jobTitle, isNull);
    expect(destinationFor(id), WorkspaceDestination.applicant);
  });
  for (final title in ['HR', 'Admin', 'Software Engineer']) {
    test('Employee title $title does not change account type', () {
      final id = AuthIdentity.fromJson(response('Employee', title: title));
      expect(id.accountType, AccountType.employee);
      expect(id.jobTitle, title);
      expect(destinationFor(id), WorkspaceDestination.employee);
    });
  }
  test('SysAdmin is not an Employee Admin', () {
    final id = AuthIdentity.fromJson(response('SysAdmin'));
    expect(destinationFor(id), WorkspaceDestination.unsupported);
  });
  test('unknown and missing account type fail closed', () {
    expect(
      () => AuthIdentity.fromJson(response('Guest')),
      throwsFormatException,
    );
    final missing = response('Applicant');
    (missing['user'] as Map<String, dynamic>).remove('accountType');
    expect(() => AuthIdentity.fromJson(missing), throwsFormatException);
  });
  test('employee requires jobTitle', () {
    expect(
      () => AuthIdentity.fromJson(response('Employee')),
      throwsFormatException,
    );
  });
}
