# Push delivery and Firebase Auth revocation

## Scope and observed gap

Base: `d489abafae3a230cdc69b2bde513057ac9cf0161`, after merged #206. This is a recipient-registration delivery check, not a change to login, recipient opening, Rules, device identity, or the deferred Stage 7 media work. No deployment or live Auth/Firestore/FCM operation is authorized or performed.

The dispatcher already fetched the recipient's current Auth UserRecord before each multicast, but checked only `disabled`. It checked the registration's authenticated timestamp against the Firestore `authRevocations` mirror and session metadata, not Auth `tokensValidAfterTime`. Thus revocation in Auth alone could leave an existing registration eligible. This can occur through administrative revocation or a password reset independently of that mirror. The actual password-reset flow is not exercised by these tests.

## Change and compatibility

The existing per-batch UserRecord now also gates each canonical registration using its server-bound `authTime`. No additional Auth request is introduced. The existing binding owner, session identity/generation, token equality, preferences, notification identity, actor, block, content and Firestore cutoff checks remain conjunctive and unchanged.

Auth cutoff equality is allowed, matching the pinned Firebase Admin Node SDK's `auth_time * 1000 < tokensValidAfterTime` revocation comparison. The separate Firestore policy deliberately retains its stricter `authTime > revokedBefore` requirement. Do not conflate them. UTC/ISO timestamps are parsed without dropping fractional milliseconds; invalid authentication timestamps and explicit invalid/non-string/negative cutoff values deny delivery. An undefined optional Auth cutoff retains SDK compatibility.

A denial does not delete tokens/bindings/sessions, modify notifications, mark them read, or fabricate a Firestore revocation mirror. Genuine reauthentication plus the existing synchronization callable can restore delivery. In a mixed batch, fresh registrations remain eligible while older ones are withheld. Actor token revocation is not incorrectly applied to the recipient's distinct registration.

References: https://firebase.google.com/docs/auth/admin/manage-sessions ; https://firebase.google.com/docs/reference/admin/node/firebase-admin.auth.userrecord ; pinned `firebase-admin/lib/auth/base-auth.js`, `verifyDecodedJWTNotRevokedOrDisabled`.

## Fresh local evidence before publication

- Node v24.21.0; credential-free `demo-unispace-security`, loopback Auth and Firestore emulators. Actual registration and dispatch handlers. FCM is captured, never sent to devices.
- New integration suite on unchanged base: 11 tests, 5 compatibility passes and exactly 6 named `AUTHCUTOFF:` assertion failures, exit 1; no cancellations/skips or fixture errors. These are six scenarios for one missing authorization boundary, not six independent vulnerabilities.
- Final focused suite: **136 passed, zero failed/cancelled/skipped, exit 0**. This is 116 inherited tests plus 20 new tests (11 integration and 9 unit). The separate 9-test unit run is a subset and is not added again.
- Integration covers real Auth-only revocation, SDK rejection of the old ID token, genuine reauthentication/resynchronization, mixed registrations, Auth UID deletion/recreation, 501 synthetic token fixtures with revocation after the first 500, lookup errors/recovery, and existing system/preferences/Firestore compatibility. Named malformed/absent Auth-metadata tests explicitly fault-inject the getUser result; the real-revocation tests do not stub token verification or Auth state.
- Time-dependent tests cross the recorded authentication-second boundary once, then assert the real Auth cutoff and revoked-ID-token result. No verification retry, disabled assertion, or skipped test was introduced.
- JavaScript syntax and scoped whitespace checks pass. All pre-change production security files reconstructed from retained merged sources independently hash to Git tree `80dace98163da6497fe0e52a6d988e7c510d5270`, exactly matching current main's `functions/security` tree. Manifests/lock and configured index also match main. The local workspace is not a complete current Git clone; do not claim full-current-repository results from it.
- Remote results are pending at this pre-publication snapshot. Existing push-delivery and full-backend PR workflows include both new `push-delivery-*.test.cjs` files. Their exact-head outcomes must be verified before merge.

## Remaining boundaries

Auth data is read once per batch. Revocation after that read may race an already dispatched request; a first batch cannot be recalled, and system-tray/local cached payloads are not erased. This does not implement token-bound per-device login, every-route sign-out invalidation, stale-payload provenance, full notification schema or chat mute authorization. Absent optional Auth metadata is not proof of a live revocation. Native-device/iOS delivery and live Firebase Rules/Functions/IAM/App Check remain unverified. No Android build is claimed for this backend-only patch. Historical #204 fixture-authentication failure remains unexplained and is not fixed by these successful runs. Stage 7, media/data migrations and dependency changes are untouched. This is not production release approval.
