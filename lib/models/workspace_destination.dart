import 'auth_identity.dart';

enum WorkspaceDestination { applicant, employee, unsupported }

// Presentation routing only. Permissions are checked by the server on each API.
WorkspaceDestination destinationFor(AuthIdentity identity) {
  return switch (identity.accountType) {
    AccountType.applicant => WorkspaceDestination.applicant,
    AccountType.employee => WorkspaceDestination.employee,
    AccountType.sysAdmin ||
    AccountType.unknown => WorkspaceDestination.unsupported,
  };
}
