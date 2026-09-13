# Server-owned post votes

Local implementation, tests and device validation deferred by user request.

setPostVote accepts only postId and desired vote (-1, 0, 1). The caller is derived from a verified token. Existing authorized-post projection validates content and original repost/comment access. The write transaction rechecks current post author, removal state, actor/owner account state, revocation cutoff, block directions and authoritative follower access before changing only the caller's membership and net score delta. No voter lists or client-provided score/actor are accepted or returned. Duplicate desired-state calls do not double-count; concurrent devices use last committed desired state. Existing aggregate count discrepancies are not rebuilt.

Both post-card implementations (search and regular posts) now use the callable, keep optimistic feedback, prevent overlapping taps per card and restore local state on error. A lost response may mean the server committed while local state rolled back; retrying the same desired state is safe. Existing client notification helpers are preserved and driven by the returned committed transition. Notifications are not atomic with the vote and may be lost after a disconnect; moving aggregation to the server is pending.

Original repost access and Firebase Auth account status are checked before the transaction, so changes to those during the write remain a race; primary post privacy/block/follower/revocation state is rechecked transactionally. The shared content-read limit and projection cost apply to votes. Storage still uses legacy arrays and remains bounded by Firestore document size. Other comment vote/write paths and complete live Firestore rules remain unmigrated; the callable alone does not prevent direct legacy writes if live rules permit them. Do not deploy the partial root rules over production.

Pending final checks: all vote transitions and retries; concurrent accounts/devices; private/pending/accepted follows; blocked/frozen/deleted/revoked users; removed/reposted content; forged score/UID input; notification parity; rollback and lost responses; existing suites and two-account device flow. Deploy callable before this client.

Update: like aggregates are now updated atomically on the server; see LIKE_NOTIFICATIONS.md. Earlier references to client notification helpers describe the prior stage.
