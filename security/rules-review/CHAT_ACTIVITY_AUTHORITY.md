# Participant-owned chat activity — bounded continuation

Baseline main: `169c9bf2c2a493487b0a87d1eb16eb1d3000e0b5` (merged #199).
This independent change does not publish the local Stage 7 private-media code.
No Firebase deployment, live data/claims/token change or dependency upgrade.

## Contract

- `chats/{chatId}.lastReadAt` and `.typing` are maps keyed by participant UID.
  New entries or changed values must be Firestore timestamps equal to request.time.
- A current participant may change only their own entry. Parent replacement,
  deletion and a simultaneous summary write cannot change the other participant.
- Own lastReadAt cannot be removed. Own typing may be removed. Repeating an
  unchanged operation remains allowed. Server timestamp transforms refresh marks.
- New chats may omit these maps, initialize empty maps, or initialize only the
  creator's own server-timestamp entries. They cannot claim a peer read/typing.
- Unchanged malformed legacy containers do not block unrelated operations. A
  malformed entire container needs reviewed repair; a valid map's caller-owned
  invalid/future leaf can be replaced with server time without touching peers.
- Existing membership, session revocation, suspension and #199 message-level
  interaction guards remain. Root candidate is not a complete release policy.

## Flutter compatibility and reader behavior

The existing screen used dotted string keys in several `set(..., merge:true)`
operations while readers consume nested maps. ChatActivityClient supplies nested
maps and the production screen passes them to the actual merge API. UID segments
are literal map keys (including dots), not interpolated field paths. Read writes
reset only the caller's canonical unread count and never replace another entry.

The writer captures the screen's UID and process-local viewer session. Account
switch, observed logout/login or disposal suppresses future writes and stale
success. These checks are NOT credentials and cannot recall an already dispatched
write; Rules enforce ownership under the actual request's authenticated UID.

The screen uses the client in both read-acknowledgement locations and typing
start/idle-stop/send-stop. Empty composer stops typing. Failures are caught without
announcing successful delivery or logging raw token/request content. Malformed
activity containers are ignored by the reader instead of throwing. Peer typing
expires after four seconds using a cancellable local timer, including when no
subsequent snapshot arrives. Future/stale timestamps are not treated as active.
Local clock skew can still affect this approximate indicator.

## Evidence plan

Actual Auth/Firestore emulator-issued client tokens and REST writes/transforms,
not Admin SDK, prove Rules permissions. Admin is only for fixtures/inspection.
Ten specifically named tests reproduce old-policy failures, then pass with the
candidate. Tests include valid nested merges, server timestamps, peer preservation,
parent-map attacks, creation, simultaneous writes, suspension and revocation.

Executable Dart tests invoke the production client with injected write/session
boundaries. Source-contract checks verify its actual screen integration, but are
not a FlutterFire platform-channel or real-phone test. The existing CI backend,
Flutter regressions and Android build must be checked independently.

The first focused local run passed 95 of 96 cases: a test compared REQUEST_TIME
against REST commitTime, which are not the same timestamp. The assertion now
compares the server-returned timestamp transform result with stored data. No
production rule was weakened and all original authorization assertions remain.

## Remaining limits and rollout

This is not proof of a human reading a message, nor a redesign of when the screen
acknowledges a snapshot, background/offline queue handling, receipts opt-outs or
all-route privacy policy. Read/typing entries remain visible to chat members.
It does not enforce unread counter increments, summary ownership, message schema,
full messaging/block policy, per-device Auth-token revocation or all chat fields.
Literal dotted legacy fields are not canonical activity and are not bulk-migrated.
Other pre-existing dotted-set settings/send-summary paths need separate review.

No live Rules were fetched or deployed. Validate deployed services, compatible
clients, historical records and rollout before activation. Rebase any later
Stage 7 patch to retain both #199 interaction guards and these activity guards;
its old full rule/chat files must not overwrite current main. Bearer media URLs,
cloud IAM/App Check, dependency advisories, device/E2E tests and legacy migration
remain open release work.

Primary reference: https://firebase.google.com/docs/reference/rules/rules.firestore.Request
For server-side timestamp writes request.time equals the transform timestamp;
this does not imply equality with the separate REST commitTime field.
