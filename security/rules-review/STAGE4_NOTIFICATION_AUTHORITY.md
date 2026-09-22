# Stage 4 — notification authority and push binding

Baseline: `ef4c0c13b66f49a4084533af20f379ca6d0f0d53`, merge of #194.
This is reviewed source, not deployed Firebase policy. No live user data, token,
credential, account, rule release or cloud configuration has been changed.

## Verified source contract

All current business-event notification producers are in the configured
CommonJS backend: follow-relationships, post-votes/like-notifications,
comment-mutations/like-notifications, create-comment, create-post/new-post-notifications,
and repost. The Flutter `pushNotification` and `pushNotificationFromMe` helpers
were not invoked by any other current source path; they are removed rather than
retained as a future direct-write fallback. Pure message formatting is unchanged.

Flutter notification consumers retain the current schema: unread badge queries
filter `read == false`; compact/history queries order by `createdAt`; mark-one
and mark-all write only `read: true`; dismiss-one and dismiss-all delete owned
notification documents. Their existing batch sizes and navigation remain unchanged.
Raw event creation and payload edits are denied even to the recipient or an actor
listed inside an aggregate. Only the active recipient can read, acknowledge or
dismiss. Acknowledgement is idempotent and cannot reset `read` to false; a new
server-side event may legitimately reset an aggregate to unread.

Device registration uses `PushPreferencesService` -> `syncPushDevice` and
`detachPushDevice`. No Flutter file directly reads/writes `fcm_tokens`. Direct
client access to that collection is therefore denied. The protected
`pushTokenOwners` and revocation subcollections already had no client grant.

## Push delivery changes

Delivery now requires all of: server binding owned by the recipient, safe
nonnegative integer authentication time newer than a valid global cutoff,
an active existing session with matching ID and creation timestamp, and the
canonical hashed token document with matching authentication/session metadata
and complete boolean preferences. Arbitrary duplicate/legacy documents no
longer authorize delivery. Global/category opt-outs remain enforced.

`syncPushDevice` rejects malformed global cutoffs, per-device revocation markers
and existing binding times. Frozen accounts cannot register; a frozen owner can
still detach an existing device. Moving device ownership keeps the previous
account's revocation marker; a stale detach cannot remove another account's
binding. Malformed binding records need explicit repair instead of silent trust.

The existing dispatch code still rechecks notification existence, creation time,
read state, account availability, blocks, session and content access. Invalid
FCM tokens are removed with compare-before-delete; transient failures do not
cause valid records to be deleted. These are not exactly-once delivery guarantees.
A revocation committed after the final check cannot recall an in-flight or
already delivered push. Push tests replace only the external FCM sender; they do
not prove physical phone delivery or OS background behavior.

## Notification content minimization

New comment/reply notification envelopes contain generic Arabic text plus IDs,
not excerpts copied from the underlying comment. The original comment remains
unchanged and the app still opens it through its authorized content path.
Existing historical notification text is not bulk-migrated or deleted. Actor
names and photos are still retained in notification documents; this is not a
complete historical-data retention or notification-read projection solution.

## Profile-field audit, intentionally separate

Added tests exercise existing protections for backend identity, username/email,
roles, counters, unknown security keys, academic map shape and obsolete recovery
code clearing, plus normal editor updates and session revocation.

`accountStatus` and `security.frozen` remain client-editable for voluntary
activation/deactivation and freeze/unfreeze flows. They MUST NOT be treated as
administrator-imposed sanctions. The existing data does not identify who imposed
legacy restrictions. A separate, server-owned administrative-state contract and
migration is still required. No automatic reinterpretation or live migration was
performed. Tests preserving voluntary activation are compatibility tests, not
proof of administrative enforcement.

## Verification and evidence boundaries

New coverage: 22 Rules/client-REST cases, 25 registration/delivery integration
cases, 10 production event-producer cases, 14 pure policy cases, 8 profile-write
contract cases and 4 static Flutter-source checks. These are 83 additional Node
tests; static checks are not Flutter runtime tests. Fixtures require BOTH local
Auth and Firestore emulators and use an explicit demo project. Raw Rules
assertions use Auth-emulator-issued ID tokens, not Admin SDK permissions. Real
production handlers are invoked with Admin Auth/Firestore emulator clients;
callable HTTP transport and App Check are not exercised.

The dedicated workflow reproduces exactly 14 named failures against the immutable
pre-fix Rules/handlers and then checks the current source. The inherited full
backend workflow runs every test file; focused groups overlap that full result.
Fresh execution counts and any failures are recorded in the PR and delivery
report only after the logs are read. No pass is claimed from this test inventory.

## Rollout prerequisites

1. Verify currently deployed business-event functions and device-sync callables.
2. Stage the compatible client and new backend; verify token sync/session startup,
   opt-out, logout, account switching and ordinary event creation with test users.
3. Inventory legacy/unbound token registrations. They intentionally stop receiving
   pushes until successful synchronization; do not enable the new dispatch policy
   for an unprepared client population. No live tokens were examined here.
4. Re-fetch and reconcile deployed Rules before choosing a final policy. Do not
   deploy the entire root review candidate blindly. Existing old clients with raw
   notification/token writers will receive permission errors after this change.
5. Require device/end-to-end acceptance and a reviewed rollback strategy. Never
   use unrestricted client event writes as an automatic fallback.

Still open: server-owned lifecycle/admin restrictions, chat write schema and
messaging-policy enforcement, legacy follower provenance, token-bound per-device
login revocation, Storage/token URLs, cache/retention, live IAM/App Check/rules
reconciliation and dependency advisory remediation. No library or lockfile changed.

## Primary technical references

- https://firebase.google.com/docs/firestore/security/rules-fields
  (field-diff allowlists; server SDK access is outside client Rules).
- https://firebase.google.com/docs/functions/firestore-events
  (event ordering is not guaranteed and invocation may happen more than once).
