# Atomic like-notification aggregates

Local implementation; tests/device verification deferred by user request.

Post and comment vote transactions now read and update the notification aggregate in the same commit as the vote. No separate client notification request remains for these paths. Actor identity/name/photo come from the verified caller and server profile. Self-likes do not notify. Repeating the same desired vote leaves the notification unchanged, including read state and timestamp. Unlike/dislike removes the actor, removes stale actors absent from the current upvote set, deletes an empty aggregate, and otherwise preserves read state/timestamp. A new like marks the aggregate unread. Up to 30 recent stored actors are retained, matching the previous UI semantics; count is the displayed aggregate size, not total likes.

Legacy IDs/schema are retained. A conflicting postId at a legacy document ID uses a deterministic hashed fallback to avoid overwriting another post's notification. Existing data is not bulk migrated. Cached names of other actors are retained; deleted/blocked-account cleanup beyond current voter membership is a separate task. A retry after committed vote and lost response does not duplicate the database notification.

The existing pushOnNotification trigger remains onDocumentCreated: initial aggregate creation can send a device push; updates to an existing aggregate do not generate a new push. Delivery remains asynchronous, potentially retried, and is not exactly-once. A notification already delivered to a device cannot be recalled by database retraction. No live rules were changed: complete notification write rules, old client compatibility and other notification producers still need review before claiming all notification writes are server-owned.

Final checks pending: new/second/multiple likes; same-state retry; self-like; unlike last/non-leading/leading actor; switch to dislike; 30-actor cap; concurrent votes; transaction failure; legacy collision; read/timestamp preservation; user-facing Arabic text; trigger behavior and existing security suites. Deploy updated vote functions and helper before client.
