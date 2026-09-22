# Follow and profile-contract reconciliation — 2026-09-22

Baseline: `62e74ee86641ea1c80c41c384aa301a286a65913` (merged PR #192).
This is a source-policy change, NOT a deployed-rule reconciliation or release approval.

## Implemented boundary

`followers`, `following`, `follow_requests`, `blocked_accounts`, and `blocked_by`
are now server-written only. `manageFollow` owns both relationship sides, pending
requests, and the block mirrors. Both participants retain individual status reads;
only the collection owner may list raw records. Other-profile list browsing already
uses `readFollowList`, which applies audience, private-account and block checks.
All these direct reads use the same protected session-revocation cutoff as chats.

Legacy `blocked_users` records are owner-readable and server-written. Notification
filtering (`main.dart`), settings (`blocked_users_service.dart`), and block controls
still read these records. Denying all legacy reads broke those consumers. Unblocking
now deletes only the caller-owned legacy record as well as the modern pair; it never
removes a peer-owned block and never silently recreates a follow relationship.

The remaining direct delete in `_unblock(_BlockedAccount account)` now invokes
`unblockAccount`, with account-switch checks before the request and after the await.
The callable is the authority; the UI does not optimistically claim success.
The existing helper handles revision notifications, avoiding double increments.

Malformed revocation cutoffs fail closed in `manageFollow`.

The public-profile projection now includes the allowlisted `whoCanMessage` policy.
The default remains `mutual`, matching `PrivacySettings`; invalid values become
`none`. This fixes an omitted field consumed by `chatMessagingBlockedReason`.
It does NOT make the client messaging gate a server-enforced chat policy.

## Source compatibility review

Tracked Dart relationship references were inventoried and their surrounding code
reviewed. Direct relationship consumers in main.dart and chat_page.dart are owner
lists/counts or participant document gets. Public list screens use readFollowList.
Follow/cancel/accept/reject/block/unblock mutations use manageFollow after the one
legacy unblock-sheet fix. Source-contract tests protect those specific seams;
they are not a complete Dart data-flow proof, Flutter compilation or device tests.

## Verification design

New tests use Auth-emulator signup tokens, Admin SDK only for fixture/state setup,
client Firestore REST requests for Rules assertions, and real Admin Auth verification
inside callable handlers. They run only with loopback emulator endpoints and an
explicit demo project. Seven regression cases also run against the immutable
pre-fix policy; CI requires the exact seven expected failures there before running
the current policy. Existing follow, profile, chat and projection tests are rerun.
A separate all-backend test job keeps broader failures visible. Results must be
read from completed runs; no success is claimed by this document alone.

## Remaining blockers

- Raw `users/{uid}` reads still allow authenticated users to fetch entire profiles.
  Restricting those requires migrating remaining direct other-profile consumers,
  including isUserPrivate and canCommentOnAuthor. This slice does not fix that leak.
- Previously forged follower records are NOT made trustworthy by changing Rules.
  No production records were audited or removed. Audit provenance and explicitly
  plan legacy relationship re-approval before relying on old records.
- Account-state ownership, notifications, sessions, Storage access and token URLs,
  dependency advisories, and full cloud IAM/deployed-config verification remain open.
- Client-side messaging preferences still need server-side enforcement and full
  chat-write schema validation. This projection repair is not that migration.
- Legacy blocks keyed by identifiers rather than real target UIDs require a separate
  resolution/migration plan. No broad legacy deletion or automatic conversion occurs.

Before any production deployment, verify deployed manageFollow/readFollowList,
release a compatible client, audit existing data and re-fetch live rules. Do not
blindly deploy this candidate or weaken it to accommodate old direct-write clients.

## Session failures exposed by the full test run

At commit `7ff359375b6c8bea1fe06e22dfc4bff644ae965b`, the focused suite passed
113/113 but the complete backend suite passed 165/168. All three failures came
from inherited session Rules: reactivating a revoked record, editing arbitrary
legacy fields, and reading the profile with a revoked authentication timestamp.
The first-run evidence is retained; those failures were not skipped or reclassified.

The follow-up policy applies the shared cutoff to raw profile reads and session
reads/writes; it does NOT restrict raw profiles to their owners yet. New sessions
follow the actual Flutter initialization schema. Activity, alias, device metadata
and trusted-device UI preferences remain editable on active records, with immutable
session ID, installation ID and creation time. Legacy initialization may add the
current schema while preserving unknown legacy fields, but cannot freely edit them.
Revocation permits only the four actual Flutter revocation fields with server
timestamps and the three supported reasons. Repeated revocation is allowed, but
heartbeat/alias writes, resurrection and client deletion are denied after revocation.
Twelve additional emulator tests cover these denial and legitimate-use boundaries.

This protects record integrity and the shared server-owned authentication cutoff.
It is NOT cryptographically bound per-device token revocation: clients still create
session records, `isTrusted` remains UI metadata, and a malicious authenticated client
could invent a different session ID. Proper per-session enforcement requires a
separate server-owned, token-bound session design and a compatible rollout.
Fresh CI must confirm this follow-up before it is considered verified.
