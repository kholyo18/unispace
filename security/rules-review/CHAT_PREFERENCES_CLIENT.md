# Chat preference client/Rules compatibility

## Scope

Continue from main 972022ad97f404b70e74c2efb2ab907d488e6cda (#201).
The existing #199 message, #200 activity and #201 preference Rules are unchanged.
This does not contain or retry publication of the previously blocked Stage 7 draft.
No Firebase deployment, credential/IAM change, dependency change or historical
user-data migration is performed.

## Changes

The old details writer passed literal dotted keys into set(..., merge:true),
while readers expected nested UID maps. Bubble selection also duplicated the
same write. ChatPreferencesClient now produces explicit nested maps for the
screen owner, preserving every other identity and unrelated theme fields.

Bind the client to the chat screen's UID and local viewer-session scope and pass
that same instance into details. Reject queued work after account/session change
or disposal, serialize rapid operations, and propagate errors without poisoning
subsequent retries. An already dispatched write cannot be recalled by a UI check;
only actual server authentication and Rules authorize it.

The details UI applies its explicit saved preview only after a successful write
and rechecks its session/mounted state. Busy actions do not issue duplicate writes.
Nickname, own mute flag, automatic-translation flag, bubble color/gradient and
wallpaper use the client. Own clear-history uses a server-timestamp transform;
it remains a local-view cutoff, not deletion of stored messages. Gallery/Storage
waits also recheck the bound session before attaching a wallpaper URL. Provider
offline writes may remain pending; no timeout is misrepresented as a rollback.

ChatPreferencesSnapshot ignores malformed old containers and invalid color/
gradient types rather than crashing or copying another member's values.
Nickname explanatory text no longer promises that shared document data is secret.
No translation request/processor is added or audited by persisting its existing
boolean setting. Existing unofficial/manual translation remains separate work.

## Verification design

- Executable Flutter tests exercise actual production client serialization,
  one-write transitions, failures/retry, queue ordering, session switch/disposal,
  server/delete sentinels, exact UID segments and robust snapshot parsing.
- Five static source-wiring checks complement execution, not replace it. Exactly
  two targeted checks fail on immutable old source and pass on the candidate.
- A standalone Dart exporter invokes the actual production client and emits its
  eleven synthetic payloads. Twelve Auth/Firestore emulator tests apply them with
  client ID tokens and a REST adapter, checking persisted canonical values,
  deleted leaves, server timestamps, preserved peer/other fields and denied
  anonymous/peer impersonation. Admin only seeds and inspects fixtures.
- One characterization test documents that an old literal dotted write still
  creates an unused field under current Rules, leaving the canonical name intact.
  Its success is proof of the old mismatch, not a claim that all unknown fields
  are forbidden. Old records are not silently promoted into canonical settings.
- New code analysis, locked Flutter dependency resolution, selected existing
  Flutter/security regressions and the full backend suite must pass. Native
  Android and physical-device results must be reported separately.

Actual results belong in the PR/evidence after execution, not inferred from this
workflow. REST payload transport is not a FlutterFire platform-channel/device
transport test. Local preliminary Dart analysis lacked installed flutter_lints;
only the CI analysis with locked project dependencies is a complete scoped check.

## Remaining boundaries

Preferences still reside in a chat document readable by both members. This is
write ownership and correct persistence, not preference confidentiality. Flat
chat-list mute flags versus the detail mute map are not reconciled; this does
not prove that push delivery honors every mute setting. Existing literal dotted
records are not repaired, and old malformed canonical documents may still reject
writes until a reviewed migration. Historical media URLs, Storage/cache privacy,
Stage 7 publication/rebase/device work, unread/summary authority, whole-message
schema and all-route block policy, per-device Auth-token revocation, dependency
advisories, live Rules/IAM/App Check and phased rollout remain open.

References: Firebase Add data to Cloud Firestore (nested updates/merge), FlutterFire
SetOptions API. Do not deploy review candidate Rules solely because this passes.
