# Own profile counts

readOwnProfileCounts accepts an empty object; ownership is always authenticated UID. It verifies the bearer with revocation checking, account state and cutoff before and after aggregates, with a 60/minute quota in profileCountsLimits. Returns only three numbers. No list of posts or followers is sent. Counts are separate snapshots, not one atomic snapshot.

Preserves existing semantics: posts means all documents whose authorId is the caller (including reposts/drafts/hidden posts if present), not visible originals. The _isSelf profile count loader now uses the callable and ignores stale/account-switched responses. Failures retain existing counts as before. Other-profile counts and author synchronization are separate work.

Deploy function before client; protect profileCountsLimits in the final rules (unmatched under current snapshots). Do not close all direct post queries yet: author metadata/privacy sync remains. No deployment, build or runtime tests. Deferred: owner identity, malformed payload/response, revoked/disabled session, quota, aggregate parity, failed refresh, rapid refresh and account switch.
