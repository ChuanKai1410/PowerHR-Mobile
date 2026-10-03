import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/models/app_config.dart';
import 'package:powerhr_mobile/services/auth_service.dart';

void main() {
  const url = String.fromEnvironment('POWERHR_TEST_API_URL');
  const password =
      'PsmFixture-Only!42'; // Public disposable-fixture credential.
  group('Disposable real backend login', skip: url.isEmpty, () {
    for (final entry in {
      'applicant': 'Applicant',
      'hr': 'HR',
      'sysadmin': 'SysAdmin',
      'company-admin': 'Admin',
    }.entries) {
      test(entry.key, () async {
        final service = AuthService(AppConfig(url));
        final session = await service.login(
          email: '${entry.key}@example.invalid',
          password: password,
        );
        expect(session.role, entry.value);
        expect(session.email, '${entry.key}@example.invalid');
        expect(session.userId, isNotEmpty);
        expect(session.token.split('.'), hasLength(3));
      });
    }
    test('wrong password returns a safe error', () async {
      final service = AuthService(AppConfig(url));
      await expectLater(
        service.login(email: 'applicant@example.invalid', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email or password',
          ),
        ),
      );
    });
  });
}
