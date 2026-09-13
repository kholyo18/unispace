# Original-post follower notifications

Local implementation, not deployed. Automated/device tests deferred at user request.

Initial publishOwnPost now creates follower notification documents within the same Firestore transaction as publication and its receipt. The client no longer selects recipients or writes these notifications. An acknowledged retry exits before fan-out and does not recreate a dismissed notification or reset read state. A failed commit creates neither the published post nor its notifications. No external messaging is performed within the transaction.

Recipient selection retains the existing limit of 40 follower documents, using document IDs from the author's authoritative followers collection. It excludes self, missing/disabled/deleted/frozen Firestore profiles and all three block collections in both directions. Transaction query and document reads guard follow/block changes through commit. It does not backfill skipped recipients or notify followers beyond the first 40; a durable paginated outbox is separate future work. Firebase Auth disabled state is not separately queried for recipients; these checks concern Firestore account state.

Documents retain new_post type, post_{postId} ID, server actor identity, read:false and server timestamps. The message is generic and omits post title/body/media to reduce stale content exposure after privacy changes. Opening still requires the authorized content path. Already delivered notifications are not retracted on later unfollow/block/deletion.

The existing pushOnNotification trigger remains responsible for device delivery. This change guarantees atomic creation of stored notifications, not exactly-once FCM delivery. Trigger retries, token batching/cleanup, latest recipient authorization and push preference enforcement remain pending. Current notification switches in app_settings.dart are SharedPreferences-only; no server preference is invented or assumed. Syncing their intended device/account scope is a separate change.

Pending final checks: zero/one/40/more followers; forged uid in follower payload ignored; both block directions; unavailable profiles; follow/block changes during transaction; publication rollback; duplicate publication does not recreate dismissed/read notifications; generic message; client absence of direct fan-out; device push/open behavior; existing suites/build. Requires complete reviewed rules and callable deployment before client release; partial root rules must not be deployed alone.
