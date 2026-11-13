import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/auth_identity.dart';
import 'package:powerhr_mobile/models/employee_navigation_policy.dart';
import 'package:powerhr_mobile/models/workspace_destination.dart';
import 'package:powerhr_mobile/views/employee_dashboard_view.dart';

AuthIdentity identity(AccountType type, {String? title, String? company}) =>
    AuthIdentity(
      userId: 'test-user',
      email: 'test@example.invalid',
      role: title ?? type.name,
      accountType: type,
      jobTitle: title,
      company: company,
    );

void main() {
  group('Phase 5 navigation boundaries', () {
    test(
      'Applicant, employee and SysAdmin resolve to separate destinations',
      () {
        expect(
          destinationFor(identity(AccountType.applicant)),
          WorkspaceDestination.applicant,
        );
        expect(
          destinationFor(identity(AccountType.employee, title: 'HR')),
          WorkspaceDestination.employee,
        );
        expect(
          destinationFor(identity(AccountType.sysAdmin)),
          WorkspaceDestination.unsupported,
        );
      },
    );

    test('exact HR title with company can open recruitment navigation', () {
      final permissions = EmployeeNavigationPolicy.fromIdentity(
        identity(AccountType.employee, title: 'HR', company: 'company-a'),
      );
      expect(permissions.canOpenRecruitment, isTrue);
      expect(permissions.canOpenAdministration, isFalse);
      expect(permissions.canOpenCompany, isTrue);
    });

    test(
      'exact Admin title with company can open administration navigation',
      () {
        final permissions = EmployeeNavigationPolicy.fromIdentity(
          identity(AccountType.employee, title: 'Admin', company: 'company-a'),
        );
        expect(permissions.canOpenAdministration, isTrue);
        expect(permissions.canOpenRecruitment, isFalse);
      },
    );

    test('display-name aliases do not create privileged navigation', () {
      for (final title in [
        'hr',
        'HR Manager',
        'Human Resources',
        'admin',
        'Company Admin',
      ]) {
        final permissions = EmployeeNavigationPolicy.fromIdentity(
          identity(AccountType.employee, title: title, company: 'company-a'),
        );
        expect(permissions.canOpenRecruitment, isFalse, reason: title);
        expect(permissions.canOpenAdministration, isFalse, reason: title);
      }
    });

    test('employee without company has no company-scoped navigation', () {
      for (final title in ['HR', 'Admin', 'software engineer']) {
        final permissions = EmployeeNavigationPolicy.fromIdentity(
          identity(AccountType.employee, title: title),
        );
        expect(permissions.canOpenCompany, isFalse);
        expect(permissions.canOpenRecruitment, isFalse);
        expect(permissions.canOpenAdministration, isFalse);
      }
    });

    test(
      'Applicant and SysAdmin cannot gain employee navigation from title',
      () {
        for (final type in [AccountType.applicant, AccountType.sysAdmin]) {
          final permissions = EmployeeNavigationPolicy.fromIdentity(
            identity(type, title: 'Admin', company: 'company-a'),
          );
          expect(permissions.canOpenCompany, isFalse);
          expect(permissions.canOpenAdministration, isFalse);
        }
      },
    );
  });

  group('Phase 5 Employee Dashboard regression', () {
    testWidgets('HR shows available recruitment module, not planned', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            identity: identity(
              AccountType.employee,
              title: 'HR',
              company: 'company-a',
            ),
            onSignOut: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('employee-hr-module')), findsOneWidget);
      expect(find.byKey(const Key('employee-admin-module')), findsNothing);
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('Admin shows available administration module', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            identity: identity(
              AccountType.employee,
              title: 'Admin',
              company: 'company-a',
            ),
            onSignOut: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('employee-admin-module')), findsOneWidget);
      expect(find.byKey(const Key('employee-hr-module')), findsNothing);
    });

    testWidgets('ordinary employee does not display HR/Admin workspace', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            identity: identity(
              AccountType.employee,
              title: 'software engineer',
              company: 'company-a',
            ),
            onSignOut: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('employee-general-module')), findsOneWidget);
      expect(find.byKey(const Key('employee-hr-module')), findsNothing);
      expect(find.byKey(const Key('employee-admin-module')), findsNothing);
    });

    testWidgets('HR without company shows a general module', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            identity: identity(AccountType.employee, title: 'HR'),
            onSignOut: () async {},
          ),
        ),
      );
      expect(find.byKey(const Key('employee-general-module')), findsOneWidget);
      expect(find.byKey(const Key('employee-hr-module')), findsNothing);
    });

    testWidgets('sign out still calls auth callback', (tester) async {
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            identity: identity(
              AccountType.employee,
              title: 'Admin',
              company: 'company-a',
            ),
            onSignOut: () async {
              signOuts++;
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('employee-sign-out')));
      await tester.pump();
      expect(signOuts, 1);
    });
  });
}
