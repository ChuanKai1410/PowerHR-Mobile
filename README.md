# PowerHR Mobile

Flutter Android extension for the PSM1 project **Power Recruiter: A Cross-Platform
Workforce Management and Transparent Recruitment Ecosystem**.

## Baseline

- Requirements authority: `A23CS0062_ChewChuanKai_PSM1_Full_Report.pdf`.
- Android 10+ (minimum SDK 29), per SRS 2.5-2.6, physical PDF pages 243-244.
- Shared PowerHR-Server REST/JSON API, not APPS or a separate mobile backend.
- Model / Service / Provider / View organization follows the report's mobile design.
- All reports, tables and documentation are English. Keep changes narrowly scoped.

This Day 2 build is a development startup/connection harness, not an implementation of
the report's Applicant, HR or Admin screens. It calls only the existing server root endpoint.
No authentication, protected data, domain writes or STD acceptance are claimed.

## Structure

```text
lib/
  main.dart                         Composition and environment configuration
  app.dart                          App theme and provider lifecycle
  models/                           Configuration and backend response data
  services/                         HTTP access and response validation
  providers/                        ChangeNotifier state and commands
  views/                            Widgets consuming provider state
test/                               Foundation unit and widget tests
```

The Provider layer uses Flutter's built-in ChangeNotifier/ListenableBuilder and constructor
injection. No additional state-management package is needed for this small foundation.

## Toolchain and Commands

Initialized with Flutter 3.44.1 stable / Dart 3.12.1. Keep `pubspec.lock` tracked.
Use installed Android SDK/JDK settings confirmed by `flutter doctor --verbose`.
Gradle is capped at a 2 GB heap and two workers for the development machine. On low-memory
machines, build the APK before starting the emulator; the template's 8 GB heap exhausted
available memory during the first build. No system-wide memory settings were changed.

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Start PowerHR-Server on the matching port using its normal development configuration.
Android Emulator uses `10.0.2.2` to reach the host loopback interface. For a USB device,
`adb reverse tcp:3000 tcp:3000` permits the debug URL `http://127.0.0.1:3000`.
No API URL is hardcoded: without the compile-time setting, the screen shows Not configured
and sends no request. Rebuild/relaunch after changing the setting.

Only local hosts permit HTTP in debug builds. Nonlocal debug URLs and all profile/release
URLs must use HTTPS. Do not include credentials, queries or fragments in API_BASE_URL.
The root contract requires HTTP 200 JSON with `root: true` and a nonempty `env`.
Failures, malformed responses and a five-second timeout show Unavailable and allow retry.
This timeout is a development safeguard, not report performance acceptance evidence.

## Remaining Work

### Day 5 Login Service

The `AuthService` and `AuthSession` model now implement the existing `{ user, token }`
login contract. Credentials are sent once, redirects are not followed, response size/time
are bounded, and internal error text is not displayed. The service does not persist or log
passwords/tokens and is not yet connected to a login UI or session provider.

For an opt-in real backend check, start the Server repository's disposable fixture process
(`node test/fixtures/serve-login.js`) and run from this repository:

```powershell
flutter test test/real_backend_login_test.dart --dart-define=POWERHR_TEST_API_URL=http://127.0.0.1:3380
```

This runs as host-side Flutter tests, so the host loopback address is appropriate. The
five checks are skipped by default without this setting; skipped checks are not passes.
The fixture server uses local disposable MongoDB and synthetic credentials only. It does
not connect to Atlas or exercise the full production middleware. Stop it with Ctrl+C.

### Pending Acceptance

The production entry flow, API conventions, login/JWT, secure token storage and three-role
authorization are scheduled under P02/P03. Business features follow the 20-week workbook.
The generated release signing configuration still uses a debug key; this scaffold is not
distribution-ready. Finalize production application ID, signing, endpoint and branding before release.

## Technical References

PSM1 remains the functional authority; these sources explain implementation mechanics only:

- [Flutter architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter ChangeNotifier](https://docs.flutter.dev/app-architecture/recommendations)
- [Android Emulator networking](https://developer.android.com/studio/run/emulator-networking-address)
