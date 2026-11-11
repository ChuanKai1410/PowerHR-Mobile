import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/employee_company.dart';

void main() {
  test('Parses company overview and server capabilities', () {
    final company = EmployeeCompany.fromJson({
      'company': {
        'id': 'abc',
        'name': 'Example Ltd',
        'city': 'Muar',
        'state': 'Johor',
        'country': 'Malaysia',
      },
      'capabilities': {
        'canReadDepartments': true,
        'canManageHiring': true,
        'canManageCompany': false,
      },
    });
    expect(company.name, 'Example Ltd');
    expect(company.location, 'Muar, Johor, Malaysia');
    expect(company.capabilities.canManageHiring, true);
    expect(company.capabilities.canManageCompany, false);
  });
  test('Rejects missing capability booleans', () {
    expect(
      () => EmployeeCompany.fromJson({
        'company': {'id': 'abc', 'name': 'Company'},
        'capabilities': {'canReadDepartments': true},
      }),
      throwsFormatException,
    );
  });
  test('Parses a department allowlisted record', () {
    final dept = EmployeeDepartment.fromJson({
      'id': 'a',
      'name': 'Engineering',
    });
    expect(dept.name, 'Engineering');
  });
}
