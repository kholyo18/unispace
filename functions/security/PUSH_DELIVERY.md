# Push delivery correction

Local source change. Automated/device tests deferred at user request; no deployment or real notifications sent.

The previous trigger filtered blank/non-string token values but indexed cleanup against the unfiltered snapshot. An invalid token response could therefore delete a different device document. The new handler keeps token-to-document mappings, deduplicates identical tokens per invocation and sends batches of at most 500 (Firebase Admin sendEachForMulticast limit: https://firebase.google.com/docs/cloud-messaging/send/admin-sdk). Invalid-registration cleanup transactionally checks the stored token still equals the failed token before deleting; refreshed/reassigned records survive. Non-token failures are counted without logging tokens or message content and do not delete registrations.

Before each batch, the handler rereads the notification (skip removed/read/recreated), recipient profile and Firebase Auth availability, actor profile and both block directions. Token records are reread before dispatch. These are best-effort checks, not atomic with FCM: deletion, blocking or registration changes can race delivery. The current message schema and Android channel remain unchanged.

No automatic retry policy was enabled. Whole-call failures still propagate; partial non-token failures are logged, without durable per-device retries. Event redelivery or a crash after a successful FCM call can still duplicate pushes. Notification receipts from publication guarantee one database record, not one device delivery. No delivery receipts or exactly-once claims.

Still pending: device-local preference synchronization, foreground suppression, token ownership across logout/account switches and token hashCode IDs, session revocation binding, source-content authorization immediately before push, payload size bounds, and durable retry design. Actor Firebase Auth disabled status is not independently fetched; actor database availability is checked. Existing token query loads all records before batching. These limitations must be addressed before claiming complete push privacy.

Final verification cases: malformed token before valid token; duplicate tokens; 0/1/500/501 tokens; token refresh or deletion during send; stale-token cleanup; partial/transient failures; deleted/read/recreated notification; recipient disabled/deleted/frozen; actor blocked in both directions; normal all-type notifications; Android/iOS foreground/background/open; prior suites and deployed staging flow.
