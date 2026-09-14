# Rules reconciliation, 2026-09-14

Project: fachub-c631c. Published snapshots were retrieved through authenticated read-only Firebase Rules API access on 2026-09-14. Release/ruleset IDs and timestamps are recorded in published-manifest.json. Re-fetch before deployment to detect intervening changes. These files are not wired into firebase.json. Existing firestore.rules and live releases are unchanged.

## This candidate slice

Based on the full published Firestore policy, not the partial local deploy file. Denies client read/write for community_reports, legacy community_comment_reports, and nested poll_responses. Denies direct post creation to prevent forging moderation/count fields at creation; reserves and publication already use Admin SDK. Denies updates to moderation/reportCount/reportScore for everyone, including authors and moderators; removes the old direct report-score and moderator update exceptions. Explicitly denies report quota records. Existing unrelated published permissions are retained for compatibility and are not endorsed as safe.

Required functions before client/rules rollout: reserveOwnPost, publishOwnPost, publishRepost, submitPostReport, submitCommentReport, submitAccountReport, readOwnReportStatus, moderateCommunityReport, readModerationInbox, readModerationPreview, submitPollAnswers, readOwnPollResponses. Old clients relying on direct writes will fail under this candidate. Verify deployed functions, release/update policy, and all affected flows before selecting rules for deployment. No tests or deployment performed.

## Verified source blockers to a complete policy

- main.dart syncAuthorOnPosts still queries and batch-updates posts; profile _loadCounts directly aggregates own posts. syncAuthorPrivateOnPosts is duplicated in main.dart and privacy_account_overview_tab.dart. Privacy tab also synchronizes search/like flags. Preserve or migrate these before closing direct post reads/writes.
- Published users read allows all authenticated users to read whole profiles; owner write permits security-sensitive field changes. Need a field-level contract covering signup/profile/security/account deletion before restricting it. Local firestore.rules contains tighter session/follow/security policies but omits chats, notifications, favorites/hidden data and other production paths; merge deliberately, do not replace production with the local file.
- Candidate retains direct vote/comment changes, author post updates/deletes, and broad post reads from the published baseline. This is NOT a completed content authorization policy. Nested comments can still be altered through retained legacy permissions until that slice is closed.
- Published notification create/update/delete rules allow cross-user operations; map remaining producers and read-state actions before restriction.
- Storage published policy permits any authenticated user to read/write community_posts media, and does not require chat membership for chat media. Need ownership/reservation checks for post uploads, separate comment uploader paths, chat membership, object size/type limits, and a download-token policy. No Storage candidate yet: replacing it with a blanket deny would break current media flows.
- Remaining rules need revocation cutoff checks consistently; this candidate retains baseline checks outside the migrated boundaries.

## Deferred verification

Compile/emulator rule tests, ordinary user and moderator direct-denial cases, forged create/update fields, callable success via Admin SDK, poll results/submission, report statuses, old-client compatibility, profile sync/counts, chats/notifications, storage uploads/downloads and two-account app scenarios. git diff --check is whitespace evidence only.

## Author sync follow-up

The sections above record the initial slice. Current candidate now denies all direct community_posts mutations: privacy synchronization, own count loading and name/photo propagation have moved to callables. Additional deployment prerequisites: syncOwnPostPrivacy, syncOwnPostIdentity, readOwnProfileCounts, setPostVote, mutateComment, createComment, editOwnPost and deleteOwnPost. The remaining direct post-data query found in privacy_account_overview_tab.dart is account export; direct reads remain enabled until that export is migrated. No rule compilation/runtime validation or deployment has occurred.

## Export follow-up

The post section of account export now uses readOwnPostExportPage. Current candidate denies direct community_posts reads and writes, with poll_responses separately denied. This supersedes earlier transitional post-read/update notes. Confirm all callable deployment prerequisites and run the deferred whole-app compatibility checks before deployment. Other account export sections, profile fields, notifications and Storage are still pending.

## Profile export follow-up

The profile section now calls readOwnProfileExport and exports only explicit personal fields and saved privacy settings, not a raw user document. Additional callable prerequisite: readOwnProfileExport. This does not yet restrict profile access elsewhere or complete sensitive-field write policy; remaining per-user export sections need review.

## List export follow-up

The six relationship/bookmark sections now use readOwnListExportPage and explicit reference/timestamp projections. Additional deployment prerequisite: readOwnListExportPage. _downloadMyData no longer directly queries Firestore documents. This does not change direct access required by interactive list/profile/settings screens.

## Profile field candidate

Profile updates now use a provisional top-level and nested security allowlist with session cutoff. Client create/delete is denied pending verification of server lifecycle coverage. See PROFILE_FIELDS.md for the editor contract and unresolved voluntary-vs-administrative account-state distinction. Broad authenticated profile reads remain a blocker. Do not deploy the candidate until writer coverage and all deferred tests are complete.
