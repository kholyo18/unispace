# Stage 7 local verification — 22 September 2026

## Scope and persistence

This branch contains read-only test-tool preparation workflows and this evidence summary. It does NOT contain the Stage 7 application implementation. Main remains at `67592a9cefac8aac013e3691676e42996b1cdf15` (merged Stage 6). No application merge, Firebase deployment, live account/media/token changes or dependency-lockfile update is included.

The Stage 7 draft supplied in the conversation was applied to a complete, verified archive of that main commit in an isolated local workspace. Firebase credentials were not used; all tests selected an explicit demo project and loopback emulators. The previous blocked attempt to publish the application draft was not reproduced through a privileged workflow. Tool preparation checks out only the already merged source, with no persisted checkout credentials.

## Fresh execution

- Node 22.16.0, Java 21, Firebase CLI 15.18.0; real Auth, Firestore and Storage emulators.
- Full combined run of `functions/test/*.test.cjs` and `functions/storage-test/*.test.cjs`: **497 passed, 0 failed, 0 cancelled, 0 skipped; exit 0**. TAP duration: 80749.096218 ms.
- The 497 include the new private-media cases and existing backend/Storage tests. Standalone reruns and the 22 pure/source checks are not added as independent tests.
- Raw permission assertions use client credentials; business handlers use the actual Admin SDK against emulators. The HTTP media handler is exercised through a local HTTP server, not a deployed Cloud Functions endpoint.
- The successful full run used a temporary diagnostic preload that prints only active Node resource types on an unref'ed interval. It does not alter application files or authorization responses. This helper is not an application dependency.
- Node 24, Flutter tests, whole-app analysis, APK building and physical-device checks of this draft remain **UNVERIFIED** in this continuation.

Local execution evidence delivered separately in the conversation: `full-suite-diagnostic.log`, `emulator-initial.log`, `strict-input-before-fix.log`, `pure-corrected.log`, `all-backend-and-storage.log` and `isolated-chat.log`.

## Failures diagnosed, retained and corrected

1. Initial private-media run: **42 passed / 6 failed / 48 total**. Six assertions expected HTTP 404 after removing staged bytes, but the Firebase emulator authorizes before checking existence and returned 403. Tests now separately assert that Admin Storage reports the staged object absent, and that the uncredentialed/old-token request is denied. The authenticated member-download checks remain. This is a corrected test expectation, not six separately fixed production vulnerabilities.
2. Added a strict input regression for array/object `type` values. `Object.hasOwn` coerced those values during an early allowlist check. An explicit string check now rejects them at the input boundary. The later type matcher already rejected non-string values; no demonstrated unauthorized media exposure is claimed.
3. A full-suite invocation exceeded the container command deadline and was terminated. It is not counted as a successful run. A focused existing-chat diagnostic passed 25/25; the subsequent complete combined run produced the 497/497 result above.
4. A source-only run against an incomplete workspace failed because `firebase.json` was absent. Tests were then run against the complete verified main archive, not a synthetic replacement config.

## Reproducible tool preparation

- Run 35786812001 prepared the baseline source, locked server dependencies and emulator binaries and passed existing baseline Storage tests. Artifact 10720207967 SHA-256: `2206ce7def145eee8d6c2699b43a5804b1b6e3a14e8282493744581eb341e3ef`.
- Floating stable Flutter selected 3.47.5 in run 35787914529. `flutter pub get --enforce-lockfile` failed (exit 65) because five SDK-constrained packages would change: intl, matcher, meta, test_api and vector_math. The failure was not suppressed and the application lockfile was not updated.
- Run 35788221922 pinned Flutter 3.44.9 and successfully resolved the unchanged lockfile, with an explicit `git diff --exit-code` guard. It prepared test tooling only; that is NOT a successful run of the draft's Flutter tests.
- The tool archive exceeded the connector's download-size limit. Run 35788656132 verified its checksums and split it into smaller download artifacts. This step did not run or modify the draft. Font files and credentials are excluded from the Flutter tooling archives.
- The local runtime later stopped responding during tooling extraction. Frontend and Node 24 execution are not claimed from successful downloads or packaging.

## Remaining release blockers

Complete Flutter/client and Android verification; independently verified publication and rendering integration; real Cloud Storage generation/precondition/retention and public-access configuration; historical bearer URLs and non-chat media migration; abandoned-file cleanup and cache lifecycle; caller-bound per-device login revocation; messaging schema/policy enforcement; legacy inactive-account and historical-record provenance; dependency advisory remediation; live Firebase Rules, IAM and App Check; end-to-end device testing and staged rollout.

Do not treat emulator success as whole-app/cloud approval. Existing live download tokens were not rotated and main was not changed by this verification branch.
