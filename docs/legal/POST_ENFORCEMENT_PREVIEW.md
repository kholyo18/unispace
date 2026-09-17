# Post creation: transactional eligibility enforcement (review preview)

## Change contract

Base: PR #167 at `7e39f76a4e26256a4b7316719c727aa0bc2a040d`.
Only the existing `reserveOwnPost` / `publishOwnPost` pair is integrated in this
slice. The application entry point already registers both through
`createPostHandler`; no new callable name or client payload is introduced.
No main merge, Firebase deployment, live data/configuration, legal publication,
Flutter flag or representative approval is created by this change.

The existing owner, deleted-identifier, account, content/media, publication hash,
retry and follower-notification behavior remains in place. A reservation and its
publication receipt must still be created together; initial publication and its
notification records remain in the same transaction. No birth date or legal
receipt is copied into a public post.

## Server-only staged rollout

The transaction reads `legalEnforcement/postCreation` on every attempt. Its exact
schema is `{schemaVersion: 1, enabled: <boolean>}`. A missing document or a valid
false value preserves the pre-rollout path; neither represents legal acceptance.
An existing malformed configuration or failed read fails closed. Configuration
is never taken from an editable profile, client request, local storage or Flutter
build flag, and is not cached between reservation and publication.

With `enabled:true`, the existing V2 `assertInTransaction` helper rechecks the
caller, current publication, declaration, current age phase, personal receipt,
archive integrity and any required representative approval in the SAME Firestore
transaction as the post writes. Missing/disabled legal publication does not
silently disable enabled enforcement. Repeated reservation/publication requests
also undergo the check, even when their content was already acknowledged.

A published-policy change, representative revocation/expiry or account-state
change between reservation and publication can therefore reject publication
without a partial post/receipt/notification write. Reads precede every write.
Concurrent changes to documents read by the transaction participate in Firestore
transaction isolation/retry. The guard retains its existing request-time calendar
semantics; this slice does not introduce commit-time clock or continuous-session
monitoring guarantees.

The control remains absent in production because no production configuration is
written here. Enable only in an isolated emulator for this preview. Before any
real rollout, the operator must explicitly approve deployment/activation and
complete the pending legal, representative-review and application-wide work.
Server administrative access must be limited and audited. Deleting the control
by an administrator returns this staged integration to pre-rollout behavior;
never grant clients configuration writes. Test the ACTUAL deployed rules before
claiming that boundary is protected in production.

## Test scope

- Twenty dependency-free tests cover the strict rollout parser, disabled/absent
  staging semantics and propagation of a configuration decoding failure.
- The existing isolated Auth/Firestore/Functions emulator harness is extended,
  not replaced. It copies the exact checked-in post handler, its edit-content
  validation/notification helpers and the legal modules into its disposable
  sandbox, preserving source hashes.
- Only two additional callable exports are loaded in the test runtime. Storage
  access is a rejecting adapter; tests publish text-only content. No notification
  trigger, FCM, email delivery or external cloud service is loaded.
- New integration checks exercise the actual HTTP post endpoints with emulator
  tokens and real database transactions: denied unaccepted/under-minimum users,
  represented-user waiting, eligible publication, stale policy and revoked review
  after reservation, corrupt legal receipt, session/account restrictions, strict
  client payloads, ownership, retries, concurrent publication and notification
  preservation. Synthetic approvals are fixtures, never real verification.
- One controlled scheduling test invokes the actual post handler directly with
  a database proxy that changes the policy after the existing preflight read.
  The subsequent write transaction must reject it. The SDK/database are real;
  this test does not claim to simulate all database contention conditions.
- Direct REST attempts to read/list/change/delete the rollout control and directly
  create posts/publication receipts are denied under the complete repository
  rules candidate. An allowed synthetic profile read is the authentication control.

CI runs the old 55 consent / 147 eligibility suites plus the new parser suite,
then the existing legal emulator tests and the new post tests sequentially on a
fresh demo project. Same-repository Actions, read-only checkout permissions,
pinned actions/CLI, isolated credentials/project/endpoint checks and seven-day
bounded evidence retention are retained. No failure is skipped or suppressed.
The previous Flutter checks were not rerun by this source-only backend slice.

## Verification at authoring

Local Node 22.16.0: the 20 new parser tests passed; syntax checks for all authored
JavaScript and bash syntax checks for every changed workflow run block passed.
The four reconstructed base file blobs match the pinned repository bytes.
The local workspace is a scoped copy, not a full repository clone. DNS/network
prevents installing the emulator here; use this PR's actual CI run and artifacts
for fresh integration results, rather than inferring success from this document.

## Remaining boundaries (not silently expanded)

This is NOT full community enforcement. Reposts, comments, edits, polls, messages,
Storage uploads, signup/reactivation, deep links and other callables are unchanged.
In particular, this does not block raw uploads for an old reservation; the media
preflight may still perform existing metadata reads before the guarded transaction.
A synthetic reviewed representative record is not a real review workflow.
Root rules are an incomplete review candidate and are not asserted to match the
live project. App Check/IAM/production token signatures, real Google login,
retention/deletion/backup processes, actual operator identity and public legal
readiness still require the previously documented review and implementation.
No training, marketing or payment permission is added.

References consulted:
- https://firebase.google.com/docs/firestore/manage-data/transactions
- https://firebase.google.com/docs/firestore/transaction-data-contention
- https://firebase.google.com/docs/emulator-suite
