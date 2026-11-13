import 'auth_identity.dart';

/// Client-side navigation only; server validates all permissions independently.
/// Values deliberately match the DB-backed exact job-title checks in
/// util/companyScopeGuards.js (requireHiringRole / requireCompanyRole).
class EmployeeNavigationPolicy {
  const EmployeeNavigationPolicy({
    required this.canOpenRecruitment,
    required this.canOpenAdministration,
    required this.canOpenCompany,
  });

  final bool canOpenRecruitment;
  final bool canOpenAdministration;
  final bool canOpenCompany;

  factory EmployeeNavigationPolicy.fromIdentity(AuthIdentity identity) {
    if (identity.accountType != AccountType.employee) {
      return const EmployeeNavigationPolicy(
        canOpenRecruitment: false,
        canOpenAdministration: false,
        canOpenCompany: false,
      );
    }
    return EmployeeNavigationPolicy(
      canOpenRecruitment: identity.jobTitle == 'HR' && identity.company != null,
      canOpenAdministration:
          identity.jobTitle == 'Admin' && identity.company != null,
      canOpenCompany: identity.company != null,
    );
  }
}
