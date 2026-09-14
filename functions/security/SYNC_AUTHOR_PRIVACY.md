# Post privacy metadata synchronization

syncOwnPostPrivacy accepts only a document-ID cursor. Verified bearer UID owns the queried posts. In each 200-post transaction, account availability/session cutoff and current saved privacy settings are rechecked, and only changed authorPrivate/authorAppearInSearch/authorHideLikeCounts fields are updated. No user ID or privacy value supplied by the client is trusted. The client iterates bounded pages with UID and advancing-cursor checks. Existing helper signatures remain compatible.

Privacy must already be persisted before synchronization. Values can change across pages; this is not one atomic job. Current content access continues to use the live profile policy, not these denormalized flags. Failures can leave partially synchronized flags; retry from the start converges without overwriting content. No background completion or new retry UI added. Profile name/photo propagation remains a separate direct path.

Deploy callable before client. Existing direct post permissions are not closed yet. Deferred tests: each flag, empty/multiple pages, concurrent privacy edit/post deletion, cutoff, account switch, invalid cursor, failed page and retry. No deployment/runtime tests performed.
