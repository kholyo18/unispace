# Follow relationship authority

Local change, not deployed. `manageFollow` in europe-west1 owns follow, unfollow,
cancel, accept, reject, block and unblock mutations. The caller UID is taken from
a freshly verified ID token with revocation checking and the protected cutoff.
Caller-provided names, photos, approval flags or actor IDs are not accepted.

A public account is followed immediately. A private account gets a pending request;
only that account can accept an existing matching pending request. Accepted records
on the target's followers collection grant access to readPublicProfile. An existing
requester-owned following mirror cannot grant access. Current legitimate followers
remain accepted when an account becomes private.

Both relationship documents and the request are changed transactionally. Duplicate
requests and approvals do not produce duplicate notifications. Notification records
use the existing read=false schema and server-derived actor identity. Blocking
removes both directions and both pending requests atomically. Unblocking never
restores relationships and cannot remove a block owned by the other account.

Rules deny all client writes to followers, following, follow_requests,
blocked_accounts and blocked_by. Participants can read their own relationship or
request status; owners can list their records. Public or follower-visible list
browsing still needs a separate authorized read endpoint. Legacy blocked_users
settings are recognized on reads but their identifier-resolution UI is not migrated
by this change. Existing relationship records are preserved; audit legacy records
if the old deployed policy allowed forged follower writes.

Before release, deploy the callable, compatible client and reconciled rules
together. Never overwrite the complete production policy with this repository's
partial root rules. Missing callable failures deliberately have no direct-write
fallback. Existing count fields are not rebuilt here; do not treat cached counters
as authorization. Firebase Auth and Firestore account-state changes cannot be one
transaction; document status and block checks are transactional while Auth-disabled
status is checked immediately before the transaction.

Tests use real Firestore emulator transactions and rules, with mocked Admin Auth.
Staging checks with two actual accounts remain required, including notification
delivery, concurrent approval/cancellation, blocking, and privacy changes.
