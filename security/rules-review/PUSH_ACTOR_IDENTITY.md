# Required identity for social notification delivery

Base: main `d8fd8c6972432cc89547271a23e6713665e864a2`, after #204.

## Contract and change

Only `announcement` and `exam_reminder` retain the existing ability to omit an actor. Every other kind must provide a valid `actorId` before the existing Auth, profile and two-direction block checks. Unknown kinds still fail the #204 allowlist. Present but malformed actor IDs on system notifications remain denied by the existing validation. This four-line guard is applied on each multicast iteration.

`actorName` and `actorIds` are not substituted for missing identity. A social notification missing, nulling or emptying `actorId` cannot escape eligibility checks. Rejection does not delete the notification, mark it read or remove a healthy device registration. A valid repaired record can be retried. A sent batch cannot be recalled; identity changes after the last check can still race an already dispatched request.

This is defense in depth at the delivery boundary for server-written or historical malformed records, not a claim that untrusted clients can create these records under the candidate Rules. The current follow producer already writes `actorId` from the authenticated caller. Three integration tests run that real producer (public follow, private request, acceptance), inspect its resulting notification and feed it to the real dispatch handler.

## Verification before publication

Local focused execution: **116 passing, 0 failing/cancelled/skipped**, exit 0, on Node v22.16.0 and local Auth/Firestore emulators. The set contains #204's 89 tests and 27 new integration tests. These are selected checks, not all repository tests. FCM is captured rather than sent; Auth, Firestore, registration, follow and dispatch handlers are real collaborators. No credential or live project is used. The prior unresolved fixture-authentication failure is not claimed fixed by this work.

Corrected-fixture pre-fix execution: 27 cases, 6 compatibility passes and precisely 21 intended actor-identity failures. All 21 failure names have the `ACTORIDENTITY:` prefix. After the production guard, all 27 pass inside the 116-case run. No production expectations were weakened.

The first baseline attempt had two additional failures because the new test passed an ignored argument to the existing zero-argument fixture. The new test now explicitly updates the desired type and asserts it before dispatch. Its initial 4-pass/23-fail log remains retained; it is not counted as 23 product defects. The unchanged corrected pre-fix code is the actual 6-pass/21-fail regression evidence.

The retained offline source reconstruction is adequate for these scoped production handlers, whose baseline blob hashes were verified, but is not a complete current Git checkout. The existing read-only `security-push-delivery-verify.yml` automatically includes the new `push-delivery-*.test.cjs` file. Remote CI uses the full actual main tree, Node 24 and ordinary Flutter assets. Fresh remote results must be read rather than inferred from the local pass. No CI workflow, Rules, Flutter, native files, entrypoint or dependency manifest/lock was changed.

## Compatibility and remaining work

Actorless social records previously accepted by the generic dispatcher now stay undelivered. This patch does not invent an actor, migrate old data, authorize arbitrary system-message producers, or prove the underlying follow event remains current. Existing system kinds and category opt-outs are preserved. Explicit actor IDs still undergo the existing checks. This is not a complete notification schema, per-chat push authorization/mute system, delivery deduplication, stale-payload opening or device-test implementation.

Stage 7 remains outside this patch. Old media URLs, unread/summary authority, device-token lifecycle, dependency findings, legacy migrations and live Firebase/IAM/App Check verification are not closed by this change. No Firebase deployment, real device send, live-data change, credential operation or permissions change was performed.
