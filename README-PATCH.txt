PowerHR Mobile Authentication Phase 2 - Android only

Based on current GitHub main branch, 2026-11-04.

1. From PowerHR-Mobile run:
   flutter pub add flutter_secure_storage
2. Back up or commit your local changes, then copy the patch's lib/ files into the repo, preserving paths.
3. Run:
   dart format lib
   flutter analyze
   flutter test
   flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
4. Test sign in, force-stop/relaunch, restore, expired token, no network, sign out and relaunch.

No server files changed. Server returns role as Employee.jobTitle, so client display is not authorization.
Server currently also supports a separate SysAdmin discriminator; no roles or privileges have been changed.

IMPORTANT: this is not a production-secure system. A valid JWT is still accepted until expiry;
logout clears only the local secret and does not revoke issued JWTs server-side.
No mobile code was executed by the authoring environment. Verify with Flutter commands above.
