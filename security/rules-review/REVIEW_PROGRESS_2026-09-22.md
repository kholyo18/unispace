# Security/privacy review progress - 2026-09-22

Target: C:/Users/user/AndroidStudioProjects/UniSpace (kholyo18/unispace).
This is a bounded manual implementation stage, not a completed repository audit or the pending Deep Scan report. No cloud deployment was performed.

## Stage 1: session rules regression - complete for the tested boundaries

Baseline: session-security.test.cjs had 5 passing and 3 failing tests against root firestore.rules on a local Firestore emulator. Revoked records could be revived, legacy session fields could be altered freely, and revoked authentication could still read profiles.

Changes in root and candidate Firestore rules:
- Require the caller's server revocation cutoff check for profile reads and owner session access.
- Deny session deletion and all updates after revocation.
- Allow legacy records to transition to revoked using server timestamps.
- Preserve session identity fields on update while allowing current client metadata, activity, alias and trust updates.
- Validate session ID and initial revocation state on creation.

Verification (local demo project only):
- node --test --test-concurrency=1 test/session-security.test.cjs test/onboarding-security.test.cjs: 18 passed before adding two extra regression tests.
- node --test --test-concurrency=1 test/session-security.test.cjs test/mfa-recovery.test.cjs test/account-deletion-request.test.cjs test/account-deletion-worker.test.cjs: 37 passed, including the extra regression tests.
- git diff --check: passed.
- Emulator 1.20.2 required JVM flags -Duser.language=en -Duser.country=US to avoid a missing French resource bundle. FIRESTORE_EMULATOR_HOST=127.0.0.1:8190.

Limits: Auth calls are simulated in these backend tests; Flutter UI and live Firebase behavior have not been exercised. Session documents remain client-created. Preventing revival of a revoked record is not device-bound token revocation; a full per-device authorization design remains to be reviewed. The cutoff check is not yet applied consistently across every collection.

## Remaining stages

2. Profile privacy and relationships: map direct readers/writers, restrict private profile exposure without breaking search/profile UI, verify follow approval and both directions of blocking.
3. Notifications and chat: validate producers, immutable message identity, allowed participant changes, block/freeze enforcement and read-state writes.
4. Storage: reconcile actual client object paths and authorization, uploads/downloads, private media and download tokens.
5. Integration and release: run all relevant emulator suites, Flutter checks and two-account/device workflows; verify deployed functions and current rules before coordinated deployment.

Do not publish the entire candidate on the strength of this session-only verification. Preserve the existing unrelated lib/moduls3.dart change.
## Stage 2a: relationship writes and unblock consistency

Baseline: follow/public-profile suites returned 17 pass / 1 fail. Direct relationship writes were accepted by rules despite the server approval workflow. A new regression test also failed because unblock retained caller-owned blocked_users records.

Implemented:
- Root/candidate rules deny direct writes to followers, following, follow_requests and all three block collections. manageFollow remains the atomic mutation authority.
- Relationship/block reads check the caller authentication cutoff; explicit owner reads of blocked_users restore the legacy list stream used by settings.
- manageFollow unblock deletes caller-owned legacy and current blocks plus the corresponding reverse marker; the other user's independent block survives.
- The remaining blocked-account sheet now calls unblockAccount instead of deleting only one side directly.

Validation: local emulator run of follow-relationships.test.cjs, public-profile.test.cjs, session-security.test.cjs and onboarding-security.test.cjs: 40 passed, 0 failed. Two new tests cover legacy unblock/reverse block preservation and direct block rule permissions. git diff --check passed.

Incomplete privacy boundary: authenticated users can still read whole profile documents and relationship lists directly. Sanitized readPublicProfile success does not close that bypass. Map and migrate remaining readers before tightening these read rules. No claim of completed profile privacy.

Release ordering: deploy the updated manageFollow and release the sheet change before these rules. Legacy clients using direct relationship writes will be denied. No deployment or device/UI execution performed in this stage.
## Stage 2b: follow-list read privacy

Confirmed bypass: a new local emulator test could enumerate another account's followers/following directly (HTTP 200 instead of 403). The callable already enforced list audiences, but the direct rules bypassed it.

Root and candidate now restrict list requests to the authenticated owner. Single-document get remains available to either participant, preserving relationship checks used by chat/comment/repost UI. Other-account list screens already call readFollowList; direct list/count usages inspected in main.dart target the signed-in user's account.

Added follow-list-privacy.test.cjs: direct enumeration denial, owner/participant compatibility, both list kinds with everyone/none, private mutual relationships, viewer mirror rejection, blocks, and revoked credentials. Before fix: 4 pass / 1 fail. After fix, combined follow-list, relationship, public-profile, session and onboarding suites: 45 passed / 0 failed. Root/candidate hashes match; git diff --check passed.

This closes direct enumeration of relationship subcollections, not full-profile document reads. Full-profile reader migration remains outstanding. No cloud deployment or Flutter/device testing in this stage. Verify deployed readFollowList before coordinated client/rules rollout.