# Authorized comment votes

Local implementation; automated and device checks deferred by user request.

mutateComment now accepts action vote with postId/commentId and desired -1/0/1 state. Existing edit/delete behavior is retained. Verified-token/content preflight plus transaction checks cover primary post privacy, cutoff, availability, blocking and authoritative follow state. Voting additionally checks the target and its nested/legacy flat ancestors, moderator-hidden IDs, account availability and block directions. The caller need not own the comment; private commenters may still receive votes on accessible public comments. Unknown/missing/ambiguous IDs fail closed. Per-comment voter lists never leave the server.

Only the caller's vote membership and net score change are updated inside the current server-side tree. Duplicate desired-state writes do not double-count. Other comments, replies, text and media are preserved. Existing aggregate score discrepancies are not rebuilt. Shared content-read throttling, preflight costs, embedded document-size limits and preflight Auth/original-repost races still apply.

Main comment-screen callbacks (also passed to reply views) use the endpoint and committed score rather than local arithmetic. Overlapping submissions per comment are ignored. Switching from like to dislike now retracts the existing like notification. Notification helpers remain client-side and non-atomic, as in post votes. The unused client whole-tree writer was removed. Complete live write-rule enforcement and other specialized comment paths still require review; do not replace production with the partial root rules.

Pending final checks: every vote transition, retries/concurrent users, target/ancestor hidden-blocked-deleted cases, private/pending/follower access, forged UID/count input, text/media preservation, nested callback refresh, lost responses and notification parity, existing security suites and two-account device flows. Deploy updated mutateComment before client.

Update: like aggregates are now updated atomically on the server; see LIKE_NOTIFICATIONS.md. Earlier references to client notification helpers describe the prior stage.
