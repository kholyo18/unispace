# Push recipient binding — source-only continuation after #205

## Contract and scope

Base: `88395b4a823cd7a16e4ca5a6db9feaabfc3f8499`. Only two production guards in `lib/main.dart` change. A signed-in account must have an explicit string `recipientId` equal to its current UID before foreground local presentation or opening a push payload. Missing/null recipient IDs no longer mean compatibility permission. No coercion, trimming, actor-name/actor-ID/user-ID fallback, queued retry or migration is added.

The existing local-notification response, background-open stream and cold-start frame callback all reach the guarded resolver. Foreground category/global preference checks and system foreground-presentation disabling remain. Matching actorless announcement/exam delivery remains compatible. Tap behavior for an otherwise matching recipient is not newly restricted by preference switches.

Seven files: main, a callback extractor and its tests, its generated fixture, Flutter behavioral tests, a read-only PR workflow, and this note. No Rules, backend handler, native code, dependency/lockfile, UI layout, message path or Stage 7 private-attachment changes. No deployment, live user/data/token/credential/IAM operation, real FCM delivery or release approval.

## Verification design

`node scripts/extract_push_recipient_callbacks.cjs` copies the production foreground listener, opened listener, initial frame body, JSON response parser and payload resolver verbatim from `main.dart` into a checked-in generated test fixture. The fixture is committed so ordinary whole-project analysis and direct test execution do not have a missing import; a Node test requires it to equal fresh extraction, and CI rechecks equality after restoring the current fixture from the pre-fix experiment. The fixture header hashes only the extracted callbacks, so unrelated main edits do not require a fixture refresh. It records source and generated SHA256 values and refuses missing/ambiguous markers. It does not reimplement the recipient predicate. The real preference service and Firebase Messaging/local-notification value types are used. Only current Auth identity, native show and navigation boundaries are controlled. This exercises actual callback decisions but is not an actual plugin-stream, platform notification or navigator/Firestore end-to-end test.

68 behavioral cases include missing/null/wrong/non-string IDs on four entry paths, sign-out, exact matching, unchanged payload mapping, delayed cold-start account changes, tapping an already displayed notification after an account change, no fallback identity, existing preference restrictions, system-type compatibility, data-only messages and malformed local JSON. Five Node cases validate extraction, refusal of invalid inputs and exact checked-in fixture parity. Six inherited Node source-contract checks retain registration, preference and entrypoint wiring.

Fresh local final run: 144 selected Flutter tests pass (68 new + 76 inherited), zero failures, using Flutter 3.44.9 / Dart 3.12.2 with `--no-test-assets`. The 68 new tests on the original main give 59 compatibility passes and exactly 9 intended behavior failures. Re-running does not create additional distinct tests. Direct scoped Dart analysis of the test and extracted final callbacks reports no issues. Node extraction/wiring checks pass. Remote standard-assets/Android/full-source results must be recorded in the PR after they finish; local results are not a substitute.

## Local environment and retained failures

Local source is reconstructed from retained snapshots and scoped patches, not a complete current Git clone. Its main file was verified byte-for-byte against the current GitHub blob `0c8a7d19ebcea3582522f794e4ab01a89f81b30a`; the inherited manifest/lock hashes match current main. Publication must start from the actual main tree, not this reconstruction.

The offline Flutter SDK initially attempted network resolution of its own relocated tools packages; a timed attempt stopped before application tests. Offline resolution of the SDK tools fixed that setup. The partial SDK lacks `flutter/dev`, so local `flutter analyze` cannot run; direct bundled Dart analysis was used instead. Initial extracted analysis found a harness private-type API and two brace findings in the touched guards; these were fixed, not ignored. The original logs are retained. Local cache lacks the package font needed by standard-assets tests; no replacement font or dependency change is included. CI intentionally uses normal assets and a full SDK.

Because the connector cannot upload a 1.6 MB main file as a patch, an isolated preparation branch uploads only the reviewed main Git blob using a hash-checked patch. Its temporary workflow has repository-content write permission solely to create that blob, verifies the exact base/patch/output hashes, never moves a ref and is not part of the final PR. The final source tree is independently built from real main plus the seven expected blobs. No SDK, font files or full-repository snapshot belong in delivery.

## Explicit remaining boundaries

UID equality is identity binding, not session freshness, event provenance, complete payload/schema validation or current permission to the referenced object. This does not reread the canonical notification before opening, invalidate an old notification for the same UID after re-login, add missing chat membership/block/mute enforcement, or fix stale in-app history/navigation. Existing post/profile authorization remains unchanged. Cold-start notifications without a signed-in user are discarded rather than queued.

This cannot retract a previously dispatched platform notification, clear the system tray or guarantee native display cancellation during an account transition. Pre-FCM checks and production rollout still require verification. #204's earlier unexplained fixture authentication failure remains unresolved; unrelated later passes do not repair it. Historical media, account migrations, library advisories, live Rules/IAM/App Check, device tests and Stage 7 remain outside this change.

Firebase's distinction between foreground callbacks, background/terminated notification presentation and opening callbacks is documented at: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
