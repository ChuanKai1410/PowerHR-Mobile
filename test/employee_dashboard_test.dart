import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/auth_identity.dart';
import 'package:powerhr_mobile/views/employee_dashboard_view.dart';

AuthIdentity employee(String title) => AuthIdentity(
  userId: 'test-employee',
  email: 'employee@example.test',
  role: 'Employee',
  accountType: AccountType.employee,
  jobTitle: title,
  company: 'company-a',
);

void main() {
  testWidgets('EMP-01 HR job title renders planned HR label only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeeDashboardView(
          identity: employee('HR'),
          onSignOut: () async {},
        ),
      ),
    );
    expect(find.byKey(const Key('employee-hr-module')), findsOneWidget);
    expect(find.byKey(const Key('employee-admin-module')), findsNothing);
    expect(find.text('Available'), findsOneWidget);
    expect(find.byKey(const Key('employee-scope-notice')), findsOneWidget);
  });

  testWidgets('EMP-02 admin title renders planned administration label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeeDashboardView(
          identity: employee('Admin'),
          onSignOut: () async {},
        ),
      ),
    );
    expect(find.byKey(const Key('employee-admin-module')), findsOneWidget);
    expect(find.byKey(const Key('employee-hr-module')), findsNothing);
  });

  testWidgets('EMP-03 ordinary employee receives general workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeeDashboardView(
          identity: employee('software engineer'),
          onSignOut: () async {},
        ),
      ),
    );
    expect(find.byKey(const Key('employee-general-module')), findsOneWidget);
  });

  testWidgets('EMP-04 sign out callback is invoked', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeeDashboardView(
          identity: employee('HR'),
          onSignOut: () async {
            count++;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('employee-sign-out')));
    await tester.pump();
    expect(count, 1);
  });
}
