# Messaging upgrade — 2026-10-08

## Implemented locally
- Server-owned conversation opening, idempotent message sending, requests, edit/delete and atomic previews/unread counters. Signed-session, block and audience checks; durable receipts prevent duplicate or resurrected messages after retries.
- Complete request accept/reject routing, sender/request limits, server-owned message notifications and current mute/privacy checks.
- Text/media outbox with retry; memory-only drafts and outbox survive navigation and are isolated by signed SID/auth time. They are cleared on sign-out; they do not survive process termination.
- Read/typing preferences enforced in client and local rules. Receipt updates require visible foreground conversation near latest message; duplicate read/typing writes reduced. Separate delivery icon.
- Initial message history limited to40; load40 additional messages as requested. The expanded realtime query includes loaded history. This is not a cursor-based fixed-size subscription.
- All/unread/archive inbox filters, archive actions, local deletion versus deletion for everyone, localized search normalization, unread separator and jump-to-latest.
- Media viewers extracted to a module: video tiles no longer open network players; fullscreen loading has timeout, retry, playback controls and lifecycle cleanup. Images retain zoom and shared Flutter memory cache.
- Upload progress/cancel and independent retry of each selected failing source; failed post-upload message sends reuse outbox IDs.
- Notification route now includes chatId. New notification bodies intentionally omit private message text.

## Fresh verification
- 98 Dart/Flutter tests passed (93 activity/preferences/mute/outbox/draft/viewer/translation tests plus5 notification display tests).
- 78 Node tests passed (12 real Auth/Firestore emulator messaging tests, client source contracts, push gates/locales/session policy).
- Targeted analyzer: no errors after final receipt-icon correction; legacy warnings/style findings remain in the large chat page.
- Final Android debug APK built successfully (exit0, latest root UI and notification changes included). No device installation or two-device verification has been performed. Do not treat this APK as a production rollout: matching callables/rules are not deployed.

## Release is blocked; not deployed
The exported production rules differ from the local hardened rules. A chat-only merge compiles and passes its targeted tests, but inherited permissions still allow owners to reactivate revoked session rows and clients to create follower edges. Both were reproduced locally against the exported/merged policy, not by changing live user data.

Review artifacts: C:/Users/user/unispace/guide_work/chat_release.rules, chat_release.rules.proof.json, chat_release.NOT_RELEASE_READY.md. The proof verifies unrelated live rules remain byte-for-byte unchanged. Do not deploy this candidate alone. Verify and migrate the session/relationship dependencies and roll out the matching signed-session client together with chat callables/rules.

## Remaining proposed improvements
- Cursor-based inbox pagination with a dedicated pin index. Current inbox still reads all matching chat documents before display pagination to preserve older pinned chats.
- Persistent authorized media disk cache and generated thumbnails; current video tile is a play placeholder for legacy messages without thumbnails. No claim of persistent media cache.
- Search across unloaded history and navigation from a result to its exact history context. Current UI states that search covers loaded messages and permits loading older ones.
- Durable encrypted pending messages across app termination; current cache/drafts are memory only.
- Device tests for offline/reconnect, fast route changes, keyboards/small screens, native upload cancellation, signed-session replacement and actual push delivery.
- Group UI and server support are now implemented locally; see messaging-groups-ui-2026-10-08.md for the new verification and release boundaries. Calls, disappearing messages and end-to-end encryption remain outside scope.

