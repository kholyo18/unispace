# Notification history content snippets

Local implementation; tests/build/device validation deferred at user request.

NotificationItem.displayMessage now supplies generic content-event text to all four identified notification surfaces (social tile, compact stack, overlay and full list). Known post/comment event types never display stored snippets, including legacy documents. Unknown types carrying postId also receive a generic label. Non-content messages retain their existing text. Counts/IDs/read flags, ordering, dismissal and mark-read writes are unchanged; like aggregates retain a generic plural indication.

_openNotification now uses readAuthorizedPost instead of reading community_posts directly. It checks the current account after the asynchronous result and verifies a referenced comment exists in the authorized response before opening CommentsScreen. Unavailable comments and failed opens have explicit messages; network errors are not misreported as definite deletion. CommentsScreen continues its own authorization gate. Follow/profile/message routes were deliberately left outside this change.

This removes stale post/comment excerpts from rendered history but does not delete stored notification text or filter all inaccessible events out of the list. Sender names/photos, aggregate actors, raw notification document reads and already delivered messages remain separate privacy work. The user still sees a historical event and discovers content unavailability when opening it. Existing live-author avatar access and history pagination should be addressed separately rather than claiming a complete notification projection boundary.

Final checks: four surfaces with old comment/title snippets; new/unknown content types; unaffected non-content notification; single/aggregate likes; read/dismiss/order unchanged; removed/private/blocked post; deleted or hidden comment; account switch during open; network failure; normal navigation; build, prior suites and device regression.
