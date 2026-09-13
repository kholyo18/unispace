# Device push preferences

Local implementation; build/tests/device checks deferred at user request. No deployment or live messages.

Existing SharedPreferences switches retain device scope. syncPushDevice verifies bearer revocation, UID, tenant, auth_time cutoff and account availability, then stores token/platform/strict boolean preferences under the caller's fcm_tokens. A stable SHA256 token ID replaces runtime hashCode IDs; same-token duplicates under this user are deleted transactionally (bounded at 400, otherwise fail). Registration does not prove ownership of a token beyond possession, and does not remove registrations under other accounts.

The application serializes sync requests and ignores obsolete queued work/status responses. It synchronizes on initial token save, token refresh, auth events, relevant local preference changes and app resume. The settings page identifies device scope, exposes status/retry, and explicitly warns when local settings are not confirmed remotely. Offline/background delivery can continue with the last server settings until sync succeeds. There is no background connectivity worker; retry occurs on the listed events or manually.

Push delivery rereads token preferences per batch. The master switch applies to every type; community covers new_post/like/like_comment/reply/comment/repost/follow/follow_request/follow_accepted, announcements maps to announcement and exams maps to exam_reminder. Unknown types follow the master switch. Existing registrations without preferences retain prior delivery until migrated; malformed preference maps fail closed. Duplicate live records for a token deny sending if any record disables its category.

Foreground delivery applies the same category map locally. Native iOS foreground presentation is disabled so it cannot bypass the local notification check. Existing local exam scheduling already consumes the local switches; this change does not cancel previously scheduled reminders or redefine announcement producers. In-app notification history is retained.

Still pending: logout/account-switch token ownership cleanup, session binding, authorization of notification source content before push, durable delivery retries and legacy-record cleanup across accounts. Sync on account switch registers the current account only; it does not revoke the previous account's token. Server preference checks and local checks do not retract messages already in transit. Review complete Firestore rules before deploying; no client token-write rule was opened here.

Final checks: toggle master/community and keep other device unchanged; all category values; legacy/malformed prefs; offline failure/status/manual retry/resume; rapid toggles and token refresh; auth switch mid-sync; duplicate legacy IDs; revoked session; foreground Android/iOS suppression and allowed display; background delivery after sync; prior suites and build. Deploy syncPushDevice and updated push handler before the client.
