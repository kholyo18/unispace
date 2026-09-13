# Current authorized original-content previews

Local change; tests and device verification remain deferred.

_RepostEmbedCard now fetches readAuthorizedPost before rendering either post or comment quotes. It no longer uses cached quote text/media when IDs are missing, the original is absent or a request fails. Comment quotes must locate the requested comment in the authorized current response. The original post's text/media/polls and current comment fields are used. A neutral unavailable/retry state replaces failures. The name/photo widgets consume returned data instead of reading full user profiles.

Changing target post/comment/kind, account switches and local block changes invalidate prior content. Generation checks discard stale responses. Tapping and returning from the destination recheck access. Navigation preserves initialCommentId and the independent CommentsScreen gate. The global _openPostById deep-link path also replaces its raw read with readAuthorizedPost.

This covers the shared embed card and one deep-link path. The search quote renderer already consumes the server search projection; other quote composer/media/card routes and raw feed downloads still require review. Server-authorized data remains a snapshot; remote privacy changes do not instantly recall already displayed data. Reopening/refreshing enforces a new check. Added reads share the callable quota and may increase latency. Nested/legacy comment ancestry enforcement is only as strong as the current authorized projection and still needs final testing. Publishing and complete live rules remain separate tasks.

Final checks pending: deleted/private/blocked original; denied or offline read never reveals saved snapshot; updated text/media; comment deleted/hidden; missing IDs; post/comment target swaps while loading; account and block changes; retry; quote polls/video thumbnails; tap and deep-link selected comment; existing suite/device flows. Deploy readAuthorizedPost before client.
