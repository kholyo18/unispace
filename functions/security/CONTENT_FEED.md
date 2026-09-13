# Authorized feed migration

readContentFeedPage reuses the authorized post projection, including current author audience, block checks, unavailable accounts, moderation, and original repost/comment validation. It returns only projected posts and caller-specific vote membership. Each page scans at most 25 documents and limits projected data to 6 MiB. The cursor is timestamp seconds/nanoseconds plus document ID, so equal timestamps and a deleted cursor document do not break pagination. Empty authorized pages can still have a next cursor; the client offers older posts.

CommunityScreen initial and additional loads use this callable. New posts use a non-overlapping 15-second poll while the route is active, replacing the direct Firestore listener. Existing 60-second audience rechecks remain; no instantaneous revocation guarantee. Feed requests have a separate 60/minute per-user limit. Existing search/single-post interfaces are unchanged.

Deployment prerequisite: deploy the callable before using this client. No fallback to raw document reads is provided. No deployment performed here.

Scope limits: this does not close other direct community_posts readers, change deployed Firestore/Storage rules, revoke downloaded media, or revalidate every existing post's current deletion/moderation state. Full policy reconciliation remains required; do not deploy the incomplete local rules blindly. Profile decisions and post reads are separate snapshots, not one transaction.

Verification deferred by user: pagination with identical timestamps/deleted cursors/empty pages; private and accepted follower cases; both-direction blocks; removed originals/comments; malformed and oversized pages; account switches; polling/recheck overlap; parser compatibility for all media/polls; emulator rules; latency and read cost. Source diff reviewed; no runtime or automated test claim.
