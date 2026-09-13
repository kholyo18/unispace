# Author-only comment edit/delete

Local implementation; tests and runtime verification deferred by user request.

mutateComment supports edit/delete only. Strict input permits postId, commentId, action and edit text (trimmed, 1-10000 characters), never an actor UID or replacement comment tree. Authorized-post preflight is followed by transaction checks of current post author/state, actor/owner availability, cutoff, block directions and private-account follower access. Only the stored comment author may edit/delete; post ownership is not an override. Editing changes text/isEdited only, preserving media/votes/replies. Missing/ambiguous target IDs fail closed.

Deleting removes nested replies and legacy flat replyToId descendants and updates root count. Matching authored_comments mirrors are updated/deleted in the same transaction; references belonging to a different post are not changed. At most 450 descendant rows are deleted per call to stay within write limits. Larger threads fail with no partial deletion and require a separate job. Media objects and saved-comment snapshots are not deleted in this slice.

The main comment-screen edit/delete callbacks now call the server and no longer submit full trees or independently write author mirrors. Addition, comment votes, nested-thread-specific write handlers and the full live Firestore policy remain pending. Existing client write permissions may still bypass this endpoint until the complete policy is migrated; the partial local rules were not deployed. Original repost access and Auth disabled state are preflight snapshots, while primary Firestore privacy is rechecked in the transaction. Concurrent edits use last committed text; delete wins over subsequent edits. A lost delete response followed by retry can return not-found. Shared content-read throttling/cost applies.

Final checks pending: author vs other user/post owner; forged input; media/replies/votes preserved on edit; nested/flat deletion; index consistency including cross-post IDs; private/pending/block/revoked cases; concurrent edit/delete; failure/lost response; >450-descendant limit; existing suites and device workflows. Deploy callable before client.
