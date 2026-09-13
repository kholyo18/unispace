# Author-owned post deletion

Local implementation; tests/device validation deferred at user request.

deleteOwnPost accepts only postId, derives the actor from a verified non-revoked bearer token, and transactionally checks the cutoff and stored authorId. It deletes only the matching owner's community_posts document (including embedded comments), clears an own pinnedPostId reference if it matches, and stores a server-only postDeletionReceipts record. Repeating the request after a lost response returns success only for the original owner and only if the document remains absent. Reused post IDs fail closed. Receipts have no content snapshot and must remain inaccessible to clients. Owner deletion is allowed independently of voluntary freeze/discoverability; Firebase Auth disabled/revoked accounts are rejected by token verification. Admin moderation deletion is a separate operation.

All three identified user-delete callbacks (feed, profile, comments screen) now call this endpoint. Feed/profile callbacks propagate failures to their existing confirmation UI instead of reporting false success. Existing user confirmations remain. Deleting a Storage reference named community_posts/{postId} never reliably cleaned up objects under that prefix; those best-effort client calls were removed.

This does NOT delete uploaded media, nested subcollections, authored/saved comment mirrors, saved-post entries, notifications or denormalized quote copies. Authorized readers reject the missing original, but other legacy readers or tokenized media URLs may still expose copies until their migration and cleanup. A bounded, resumable server cleanup workflow and Storage policy are required before claiming complete content erasure. Receipts are deletion acknowledgements, NOT a running cleanup job.

Other creation/edit/repost writes still need migration and rules must prevent arbitrary authorId changes and resurrection of deleted IDs. Existing loose live rules would undermine ownership checks; production rules have not been inspected or deployed. Do not deploy the partial root rules as the complete policy.

Pending final checks: other user denied; owner public/private/frozen; missing post; concurrent/repeated deletion; pinned-reference cleanup; forged UID; token/cutoff revocation; reused ID; caller error and success UI; deletion followed by quote open; media/metadata cleanup plan; existing suites and device flows. Deploy callable/verified rules before client.
