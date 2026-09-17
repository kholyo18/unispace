# Legal/eligibility Firebase Emulator verification

This suite tests the existing legal modules against real Firebase Auth, Firestore
and callable Functions emulators. It does not deploy or enable the feature. Its
base is PR #166, commit `8f80dc37fdc2c5f2951d5ef0f86388cd58d988d4`.

## Isolation and scope

`test/emulator/legal/prepare.cjs` creates a **new disposable temporary directory**.
It copies the existing legal handlers and `register-eligibility.js` without edits,
uses the committed Functions manifest/lockfile, and copies the repository's entire
`firestore.rules` candidate byte-for-byte. Source SHA256 hashes and the exact
commit are written to `source-manifest.json` and retained as evidence.

The test-only Functions entry point exports the two V1 and three V2 callables.
It deliberately does not import unrelated production notification/email handlers.
There are no new production exports, no changes to the application entry point,
no manifest/lockfile update, and no modification of deployed or repository rules.

Every SDK entry point and test HTTP helper requires the exact project
`demo-unispace-legal-integration`, explicit test opt-in and the fixed loopback
Auth/Firestore/Functions endpoints. It rejects cloud-credential settings,
conflicting project IDs, remote hosts and redirected HTTP requests. The temporary
sandbox has no `.firebaserc`, pre-existing data, persistence import, or export.
Only synthetic `example.test` accounts/documents are created inside the emulator.
The representative-review fixture is test data, **not identity verification** or
instructions for approving a real account. No invitation or email is sent.

The Actions workflow uses read-only repository permissions, pinned official
checkout/setup-node/artifact actions and a same-repository PR gate. It uses Node
24 and Java 21, `npm ci --ignore-scripts` for the unchanged Functions lockfile,
and `firebase-tools@15.30.1` installed outside the checkout. The CLI version is
pinned; its transitive dependencies are resolved by npm at installation time.
No repository/project secrets, automatic merge, deployment or release flags are used.

## What the tests exercise

- HTTP callable envelopes, Auth-emulator-issued tokens and actual Admin SDK
  verification, including unavailable accounts and refresh-token revocation.
- Actual Firestore reads, `serverTimestamp`, atomic archive/receipt transactions,
  sequential retries and concurrent HTTP acceptance requests.
- Explicit decisions, immutable declaration retries, malformed dates, account
  binding, stale publication rejection and V1/V2 separation.
- Under-minimum denial, represented personal-consent waiting, synthetic matching
  review and its revocation/expiry, and the `assertInTransaction` integration seam
  with a synthetic protected write in an actual Firestore transaction.
- The complete committed rules candidate denies client get/list/write/delete of
  legal namespaces and nested receipts. A permitted synthetic profile read is a
  positive control proving that denial is not simply a broken authentication path.
- Separate dependency-free tests verify that unsafe emulator configuration is
  rejected before initializing Firebase.

## Important limits

Auth emulator tokens are unsigned and accepted only in emulator mode. This does
not prove real token signature validation, Google Sign-In, cloud IAM or App Check.
The emulator models transactions but is not evidence of production contention,
latency, indexes, quotas or every difference from deployed Firebase.

The root rules file is labeled **incomplete review candidate**. Passing tests of
these legal namespaces does not certify other paths or prove these are the deployed
rules. Existing app write/upload/signup routes still do not universally call the
eligibility guard. The synthetic guarded write here proves the seam, not that all
application routes use it. No Storage emulator or upload protection is tested here.

This is not a Flutter/device/full-app end-to-end test, real representative review,
DOB correction workflow, deletion/retention system or legal approval. Prior release
blockers remain. No legal text or translations are altered by this verification.

## Execution and evidence

Run the checked-in `legal-emulator-checks.yml` job on a same-repository draft PR.
Do not substitute a real Firebase project when preparing this test. The job writes
its tested SHA, source hashes, runtime versions, isolation-test TAP and emulator
result log to its artifact. A queued, skipped or failed run is not a successful test.
Results must be read from the actual artifact/run, not inferred from this document.

Primary technical references:
- https://firebase.google.com/docs/emulator-suite/connect_auth
- https://firebase.google.com/docs/emulator-suite/connect_firestore
- https://firebase.google.com/docs/functions/local-emulator
