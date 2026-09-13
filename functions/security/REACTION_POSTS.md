# Own reaction lists

readOwnReactionPosts accepts only reaction (like/dislike) and a feed-style cursor. UID comes only from the verified caller. It queries the corresponding voter array and projects each post through current audience/block/moderation/original-content checks. Pages scan 25 records, may return zero visible posts with a continuation cursor, and share the 6 MiB response cap. Reaction rate limits are isolated at 60/minute. Existing feed/search/single-post contracts remain unchanged.

Client lists are paginated with explicit refresh, replacing direct live Firestore streams. Auth, local block, profile and follow changes refresh the active widget. Post actions refresh it too. Remote changes require refreshing; no instant revocation guarantee. Old-generation/account results are ignored; failures show retry, with no raw-content fallback.

Before enabling this client deploy the callable and merge the two indexes in reaction-indexes.json into the complete deployed index inventory. The JSON is an index specification only, not a replacement deployment configuration. Do not delete existing indexes or deploy incomplete rules. No deployment performed.

Deferred checks: private/follower/block/disabled/deleted cases, other-user input rejection, equal timestamp pagination, empty pages, both reaction types, account switches, rapid filter changes, error/retry, layout, parser compatibility, latency/read cost and required index availability. Only source review and whitespace checks were performed.
