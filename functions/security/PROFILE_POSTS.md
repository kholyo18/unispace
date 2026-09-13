# Authorized profile posts

readProfilePosts requires userId and cursor, checks target visibility and projects each post using existing current audience/block/moderation/repost checks. Pages scan 25 records ordered by createdAt and document ID; cursor deletion does not break pagination. On the first page the server may also return the owner's authorized pinned post, after verifying authorId equals the target. Cursor progress remains based on the scanned page. Response limit is 6 MiB; quota is 60/minute in profilePostLimits.

Both profile screens use a shared paginated loader instead of raw Firestore post streams. Original/media/repost tabs use the loaded subset, with refresh/load-more controls. Own-profile pin placement and actions remain. New server data arrives on explicit refresh or local account/block/follow/profile signals, not a live stream. Remote revocation is not instantaneous. The other-profile post counter currently reflects loaded originals, not a server total.

Deploy callable and merge profile-post-index.json into the complete index inventory before enabling client. Do not replace deployed indexes or incomplete rules blindly. No deployment or runtime tests performed.

Deferred checks: owner/visitor/private/follower/block cases, pinned ID belonging to another account, deleted/hidden/reposted originals, duplicate pin pagination, empty pages, tabs/layout, account changes, read costs, parser compatibility and indexes. Other direct post accesses still require migration.
