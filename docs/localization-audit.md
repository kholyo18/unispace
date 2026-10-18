# UniSpace localization audit — 2026-10-03

Supported UI languages: Arabic (`ar`), English (`en`), French (`fr`). First launch selects the supported device language, with English fallback. A saved selection is retained. Runtime locale changes update inherited direction and authored UI text.

## Text and display locations

| Area | Display sources | Translation source |
| --- | --- | --- |
| Login, app settings, feed, search, media, polls, comments, profile, moderation | `lib/main.dart` | `lib/l10n/main_strings.dart` |
| Signup, terms, recovery, security, privacy controls, phone/MFA | `lib/features/auth`, `lib/ui/auth`, `lib/ui/settings` | `auth_settings_strings.dart`, `auth_terms_strings.dart` |
| Community/privacy documents, deletion, GPA and Spider | `lib/features/legal`, `features/settings/privacy`, `features/gpa`, `features/spider` | `feature_strings.dart` and existing `S` |
| Chat, bottom navigation, image retry and service errors | `lib/features/shell`, `lib/ui/widgets`, `lib/services` | `shell_strings.dart` |
| Academic catalogs and faculty search | `lib/moduls2.dart`, `lib/moduls3.dart`, `lib/ui/faculty_search_page.dart` | `modules_strings.dart` |
| Existing study/exam/other shared labels | `lib/generated/l10n.dart` | `lib/l10n/intl_{ar,en,fr}.arb` and synchronized `lib/generated/intl` |
| Foreground and backend notification templates | `notification_display_text.dart`, `functions/security/push-notification-text.js` | Static reviewed templates per language |

Catalogs use authored source text as keys. Context-bound lookup reads the active `Localizations`; background formatting uses the locale maintained by `S.load`. Interpolation is single-pass and does not translate or recursively replace supplied user values. Keep added keys and their language entries together.

## Preserved contracts

- Firestore identifiers, action values, report reason IDs, gender values, academic names/weights/credits, and poll serialization defaults stay canonical.
- User-authored posts, messages, names, announcements and exam content are not machine-translated by this change. Known built-in tags have localized display labels without changing their stored values.
- Arabic uses inherited RTL; English/French use inherited LTR. Email/username/code and deliberate content-specific direction remain intentional.
- Two opaque academic abbreviations beginning `ك.ع.خ.اع.` remain verbatim rather than receiving an invented expansion.
- Existing unused legacy legal catalog copies were not rewritten; active policy screens contain complete translated documents.

## Verification

- AST audit: 1,110 static main-text lookup sites, zero missing catalog keys.
- Final combined localization suites: 50 passed. After removing unused catalog entries, the four main locale/report-selection tests passed again. The main UI catalog contains 803 used messages.
- Auth/recovery/terms locale fixtures: 18 passed in the final focused run.
- Existing catalog parity: 4 passed; all 1,671 generated messages match ARB keys, values and placeholders.
- Shell/academic/image/upload tests: 31 passed; push-display tests separately pass.
- Push locale backend: 6 emulator integration tests and 55 unit policy/template tests passed. No production writes used for those tests.
- Whole-project Dart analysis: zero errors; existing warnings/style backlog remain.

Initial complete Flutter run: 353 passed, 1 skipped, 9 failed. Six failures were old Arabic-specific fixtures without an explicit Arabic locale; those fixtures were corrected and their 18-test focused run passed. Remaining baseline failures are the commented-out `test/widget_test.dart` placeholder with no main, and two `simple_login_terms_test` expectations for a collapsed legal panel and recovery control absent in the pre-change main file. Runtime login behavior was preserved.

## Delivery boundary

The push registration addition accepts only `ar`, `en`, `fr`, preserves the existing authenticated session/recipient/preferences checks, and sends language-specific batches through the same fresh delivery checks. The legacy registration default remains Arabic. Backend entrypoints are `syncPushDevice` and `pushOnNotification` in `europe-west1`.

Client transmission of the language field, immediate synchronization at language selection, and deployment remain pending explicit consent requested after automatic approval review rejected the additional sync invocation. The client locale field was removed again so registration remains compatible with the currently deployed backend. The server-side optional locale implementation is locally tested and ready for review. Do not enable the client field before deploying the compatible backend. A debug APK build succeeded; no APK installation or production deployment was performed as part of this audit.

The Intl generation utility is not installed in this checkout; the small existing ARB corrections were synchronized with runtime generated files and verified by catalog parity tests. Runtime generated Intl files are now includable in version control so a clean checkout retains those corrections.

Final verification: debug APK build succeeded after the last source edit. SHA-256: `D3BEFCB71019FDE1E5478D4840B4C042572B889228A304393A6C962836D02BF4`. Final scoped analysis reports zero errors (453 warnings/style notices remain). Device visual testing and rendered GPA PDF layout verification were not performed.
