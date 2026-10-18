# Flutter development build timing — 2026-10-03

The user clarified that the delay is while launching from Flutter/Android Studio, not loading content inside the app. No application/authentication/feed code was changed in this pass.

## Change

In android/gradle.properties, enable org.gradle.caching=true, org.gradle.parallel=true and org.gradle.vfs.watch=true. Keep existing JVM, dependency, signing and release configuration. The verbose log confirms local build-cache use and active filesystem watching.

## Measured evidence

Same source and command throughout: flutter build apk --debug --no-pub -v. Stopwatch wall time includes Flutter setup, Gradle and final APK hashing. No flutter clean was run. All four builds succeeded.

| Run | Total wall seconds | Gradle seconds |
| --- | ---: | ---: |
| Original configuration, initial baseline | 182.99 | 167.3 |
| Optimized configuration, first run | 101.44 | 83.4 |
| Optimized configuration, repeated | 57.59 | 41.4 |
| Original configuration, warmed comparison | 69.90 | 53.9 |

The matched warm samples show about 12 seconds less total build time with the new configuration. The initial 183-to-58 drop must NOT be attributed entirely to configuration: warmed caches and machine load contribute. This is a small local sample, not a guaranteed speedup. The final original-configuration comparison restored the optimized file in a finally block.

Flutter's installed asset builder reports that directory asset declarations force its asset target to rerun. Keep these declarations: replacing them with a hand-maintained file list could silently omit future images/fonts. Full builds also hash a large universal debug APK. These costs remain.

## Development workflow

Run the debug app once, then use Hot Reload for compatible Dart/UI edits (terminal r or the IDE lightning button). Use Hot Restart (terminal R) when state/initialization must restart. Native Android or plugin changes require stopping and running again. Avoid routine flutter clean; use it for a diagnosed stale-build problem.

No device was connected. Phone installation, launching through the IDE itself, runtime cold-start timing and Hot Reload latency were not measured. The APK benchmark is a universal debug build; device-specific flutter run can differ.

References:
- https://docs.gradle.org/current/userguide/performance.html
- https://docs.gradle.org/current/userguide/file_system_watching.html
- https://docs.flutter.dev/tools/hot-reload

Local raw logs and timing JSON: C:/Users/user/unispace/build_speed/