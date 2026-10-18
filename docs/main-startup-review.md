# Main interface cleanup and startup review — 2026-10-03

## Scope and preserved behavior

The review targets the main library, its application shell and startup dependencies. Existing localization, theme/locale persistence, navigation, deep links, session checks, MFA, media authorization, and public classes imported through `main.dart` remain in place. No Firebase rules or backend deployment is part of this change.

## Changes

- Removed 17 unused, 3 duplicate and 4 unnecessary imports based on fresh analyzer diagnostics. Existing exports remain available.
- Removed four unreferenced private widgets: `_SocialNotificationTile`, `_Avatar`, `_PollTypeItem`, `_ThreadConnectorLine`.
- Removed unreferenced `_langName`, `_sectionLabelFor`, `_blockedByRef`, and the old HomeShell scroll handler with its unused state fields. Other active scroll handlers remain untouched.
- Moved appearance/drawer UI to `lib/app/parts/appearance.dart`, application root and HomeShell to `app_shell.dart`, and notes UI/model helpers to `notes.dart`. These remain parts of the same library, preserving private access and existing imports without introducing circular dependencies or changing public APIs.
- Introduced `lib/app/startup_tasks.dart`: local Hive/settings initialization overlaps Firebase initialization. Both finish before rendering. App Check still follows Firebase, and profile initialization follows both dependency groups. Existing error handling remains at the callers.
- Kept five Firebase initialization attempts; removed only the delay after the final failed attempt. Exhausted-retry backoff decreases from 3750 ms to 2500 ms, excluding the initialization attempts themselves. Successful first attempts have no backoff.
- Updated source-contract readers to include Dart parts, without relaxing their assertions.

## Verification

- `flutter test --no-pub test/startup_tasks_test.dart test/main_localization_test.dart test/fullscreen_pager_retention_test.dart`: **18 passed**. Six new startup tests cover concurrency, readiness gating, failure propagation and retry behavior.
- AST-based comparison against the exact pre-edit source after the listed removals: **473 declarations unchanged**; only `main` and `_initFirebaseWithRetry` intentionally differ.
- Targeted analyzer: **zero errors**; existing warnings and style diagnostics remain. Passing both the root library and its parts to the analyzer duplicates diagnostics in the log.
- Seven Node contract files: **23 passed, 7 failed**. Re-running with the exact pre-edit `main.dart` produces the same seven failures. They concern pre-existing account lifecycle, notification, upload and candidate-rules expectations; this refactor does not claim to fix them.

## Performance boundary

Moving code between files and removing dead widgets does not by itself prove a runtime speed improvement; release builds already eliminate much unreachable code. The actual startup change removes serial waiting between independent dependencies, plus 1250 ms of unnecessary delay only on exhausted Firebase retries. Physical-device cold-start timing and visual interaction have not been measured for this patch. No percentage speedup is claimed.

Detailed local command logs and the exact pre-edit snapshot are in `C:/Users/user/unispace/main_refactor/`.

- Android validation: `flutter build apk --debug --no-pub` succeeded (assembleDebug 147.8 seconds). APK generated at `build/app/outputs/flutter-apk/app-debug.apk`. This is a build check, not a device startup benchmark.
