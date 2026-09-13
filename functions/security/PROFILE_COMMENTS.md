# Authorized profile comments

readProfileComments accepts a target user ID, verifies the viewer and target visibility, and uses the existing authorized post projection. Indexed comment IDs are hints only: returned comments must actually belong to the target and survive original-post, audience, block and moderation checks. The client no longer reads authored_comments or community_posts for this loader and does not fall back on errors.

Compatibility bounds: latest 80 index entries; only when the index is empty, scan at most 8 pages of 80 posts for legacy comments. At most 80 hits, 6 MiB response, 120-second timeout, separate 60/minute request quota. An incomplete nonempty index still omits older unindexed comments, as before. The bounded legacy scan may be costly; measure before release. Post projection and profile checks are separate snapshots, not an atomic revocation guarantee.

Both profile consumers clear stale results on reload and show retry on error. Pending results are guarded by load generation/account and local block revision. Already rendered content still depends on existing profile refresh behavior.

Deploy the callable before enabling this client. No deployment or automated/runtime tests performed. Deferred: index/legacy cases, forged index author IDs, deleted/hidden replies and ancestors, private/follower/block accounts, concurrent account switches, error UI, timeouts/read cost and model parsing.
