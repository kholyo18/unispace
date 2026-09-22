# Stage 5 — server-owned account lifecycle

Status: review candidate, not deployed. Baseline is the stage-4 merge
`cd9589c9dfe88d64584446f34e8d30042f265ed8`. Do not deploy the complete root
candidate without the live-policy/client compatibility review.

## Authority and representation

`accountStateControls/{uid}` is server-only, including reads. It holds schemaVersion
1, an increasing revision, selfDisabled, selfFrozen, adminSuspended, updatedAt and
lastAction. Administrative changes retain only the latest administrative actor,
time and bounded reason code. No unbounded/free-form reason or historical event
log is introduced. The deletion worker removes this record during account purge.

`users/{uid}.accountStatus` and `security.frozen` remain compatibility projections
for current clients and existing content checks. Clients cannot change/remove the
state flags or lifecycle timestamps, including through a whole security-map
replacement. Profile identity, normal editors and unrelated security metadata are
preserved. The new service uses dotted updates instead of replacing security maps.

`setOwnAccountState` accepts exactly action and expectedUid. The target is always
UID from a freshly verified ID token (including provider revocation checking),
never an arbitrary target from the payload. expectedUid must match that verified
identity: it binds an earlier confirmation when an SDK changes credentials during
an asynchronous operation. Actions are deactivate/reactivate/freeze/unfreeze.
Reactivation clears voluntary disable and freeze, never administrative suspension.
Duplicate self changes are idempotent. Canonical state, projection and deletion
request are read transactionally; malformed, terminal or inconsistent state is
rejected rather than repaired silently.

`setAdministrativeAccountRestriction` requires BOTH the signed custom claim
accountAdministrator=true AND that same claim on the current Firebase Auth user
record. It also requires authentication within five minutes, a currently usable
administrator account, a different target UID, suspended:boolean, expectedRevision
and one of policy/abuse/security/reviewed reason codes. Stale revisions fail.
No existing hard-coded content moderator or profile role is granted this role.
No real user's claims/permissions have been provisioned by this change.

Suspension atomically records the canonical restriction, its disabled projection
and an application-side authRevocations cutoff. Reinstatement preserves the user's
voluntary flags, prior cutoff and Firebase Auth's independent disabled setting.
This is not Firebase-provider refresh-token revocation or per-device token binding.

## Enforcement and explicit exceptions

The configured CommonJS Functions entrypoint applies an additional account access
guard to ordinary authenticated callable requests. It denies suspended/malformed
canonical controls before invoking the existing handlers; all existing token and
operation checks remain. This also covers profile readers that previously checked
only the target. Anonymous requests still reach their existing handler's explicit
auth/recovery validation; the guard does not turn them into authenticated users.

Only revokeAllUserSessions, detachPushDevice, requestAccountDeletion and
markCurrentSession use the unwrapped SDK registration. Their own authentication
checks remain; these are logout/privacy cleanup/session-display operations, not a
path to removing an administrative restriction. Background push handlers already
reject disabled target projections. In-flight operations cannot be recalled; this
is not a claim of atomic suspension across every external system.

Firestore's activeSession gate also checks administrative controls. Protected
social access and personal saved/hidden writes cannot bypass a suspension. A
suspended owner whose authentication is newer than the cutoff can still read their
own raw status to reach the existing status/support UI; this does not permit profile
mutation, social access or reading anyone else's raw profile.

## Client migration and deletion

The two reactivation writers, deactivation writer, freeze toggle and unfreeze
screen use AccountStateService and the production AccountStateClient. They send
only a self-service action and expected caller assertion; there is no direct-write
fallback. In-flight responses are scoped to the local viewer session. This is a
client UI safeguard in addition to the server expectedUid check, not an identity
credential by itself.

The two legacy deletion paths previously deleted Auth directly, without reliably
creating the scheduled-purge request. Both now use requestAccountDeletion. The
modern deletion screen uses the same request client and binds its confirmation to
the initial UID. Auth deletion still occurs on the server after a durable deletion
request. Local sign-out is guarded and invoked without intervening awaited work.
The request handler now rejects malformed/application-revoked authentication
cutoffs and accepts an optional matching expectedUid for backward compatibility;
current clients always send it. Old confirm-only requests remain authenticated
self-deletion requests, but do not gain the new client intent-binding guarantee.
Existing deletion order and 30-day processing contract are unchanged.

## Legacy inactive state — explicit rollout blocker

A historical disabled/frozen flag has no trustworthy origin marker. It is NOT
silently imported as voluntary. Active legacy profiles initialize automatically;
inactive/unknown/inconsistent records fail with failed-precondition until a trusted
operator classifies them and creates a reviewed matching canonical record.
No live records were examined, classified, restored or deleted in this audit.
An upgrade/review/migration plan is REQUIRED before publishing this slice. The
administrative callable intentionally does not auto-classify unknown old flags.

## Verification plan and limits

- Seven specifically named direct-write/access regressions against immutable old
  Rules; the same cases must pass under the candidate. Emulator-only fixtures.
- Real Auth/Firestore emulator tests of self/admin actions, role removal, cutoff,
  terminal deletion, idempotence, concurrent deletion, projection preservation and
  the callable guard. Provider-disabled Auth remains disabled after reinstatement.
- Existing backend suite, deletion worker and source contracts, including purge of
  the new control document without deleting another user's controls.
- Production Dart client tests with injected session/network boundaries, plus
  existing recovery/MFA/session/profile/privacy and legal-widget tests.
- Static source contracts and syntax/hash checks are NOT app runtime tests.

No production deployment, claim provisioning, IAM change, live data migration,
Storage change or dependency update is included. App Check, deployment/IAM review,
physical-device flows, provider-session cleanup, per-device auth token binding,
old notification/follower provenance, full messaging-policy/schema enforcement,
Storage/token URLs and dependency advisories remain separate release work.

Primary platform references: Firebase Firestore rules-fields/rules-conditions
(server SDK bypasses client Rules and requires IAM), and Firebase Admin BaseAuth
verifyIdToken(checkRevoked=true) documentation. The API guard is needed precisely
because Admin SDK handlers do not execute Firestore client Rules.
