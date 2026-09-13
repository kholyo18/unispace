# Authorized comment-screen entry

Local implementation; automated and device tests deferred at user request.

readAuthorizedPost uses the same projection and authorization as search pages, with strict postId input. It returns only a current accessible post and filtered comments, including moderator hiddenCommentIds. Deleted/inaccessible originals and unavailable users are rejected. Existing page limits also apply to single reads (shared per-user 60/minute budget). This is a snapshot, not continuous authorization.

Every CommentsScreen entry now waits for this endpoint and builds the existing screen with freshly authorized data; it never renders the passed cached post while waiting or on error. Account switches and local block changes invalidate the screen. Retry performs a fresh read. Search-card refresh after returning from comments also uses the endpoint. The obsolete direct post read for moderator-hidden comment IDs is removed.

Pending work: migrate comment/post mutation transactions, nested thread screens, media/original-post routes and other direct reads; inspect complete live Firestore rules. No live rules were replaced. Existing interaction handlers retain their old transactions and are NOT protected solely by this read gate. Permission changes after opening are not continuously monitored. Block/account invalidation intentionally discards the comment screen state; a composed unsent draft may be lost.

Deploy callable before client. Final verification pending: initial loading never shows cached content; deleted/private/blocked/frozen cases; retry; account switch; local block invalidation; moderator-hidden nested comments; reopened updated comments; ranking/parser compatibility; existing comment write behavior; large posts/rate limit; direct-vs-search navigation with two accounts.
