# Messaging UI and groups — 2026-10-08

## Implemented in the working checkout

- The compose button opens either an authorized people search or group creation. Search is debounced and rejects stale responses and selection after an account switch.
- Inbox adds a Groups filter, group identity, last-message time, mute indication and readable unread counts. Existing direct chats, requests, archive and pins remain available.
- Group creation uses a stable request ID; invitees join only after accepting. Capacity is 32 accepted plus pending members. The UI explains that acceptance gives access to existing group history.
- Group details support rename, invite, promote/demote administrators, remove members, cancel pending invitations and leave. The last administrator must appoint another when other members remain.
- Group threads show sender names, day separators and the current group name/member count. Delivery/read ticks require receipts from every other current member, not just the first participant. Returning from group details or media acknowledges visible messages.
- Removed members lose Firestore message access; the thread clears displayed messages when access is denied. Client account/session guards prevent stale uploads being submitted under another account. Double-tap text sending is locked before its asynchronous preflight.
- Message notifications open the correct direct/group conversation and display a generic localized description without private message content. All newly introduced UI labels support Arabic, English and French.
- Group authorization, membership mutations, atomic unread fanout, upload grants and notifications are implemented server-side. Direct conversations retain their existing callable contract.

## Fresh client verification

- 126 integrated Flutter tests passed, including existing chat activity/preferences/outbox/media regressions, group service/owner guards, AR/EN/FR dialogs, small-screen keyboard layout, people search and in-app notification descriptions.
- Targeted Dart analysis found no errors. Existing warnings/style notices remain in the legacy large chat/notification files; the newly added group/picker files analyzed cleanly.
- Android debug build succeeded. APK: `build/app/outputs/flutter-apk/app-debug.apk`, 274029189 bytes; SHA256 `8A19021BF477DC007223E1A1EE0522EE9485D93F6C8B680228B0223102E55CE3`.
- ADB reported no connected device. Actual two-account phone workflows, push receipt and native uploads were not exercised.

## Fresh server verification

- Root ran the integrated Node suite with `--test-concurrency=1` against local Auth/Firestore emulators: **133 passed, 0 failed**, including 23 direct/group integration tests, upload grants/policy, chat client contracts, push gates, locale and session policy.
- Tests cover pending membership denial, acceptance, roles, last-admin protection, cancellation when an inviter loses their role, frozen/revoked sessions, forged client membership writes, blocked/removed recipient fanout, idempotent creation and concurrent acceptance/sending.
- Earlier emulator runs intermittently returned gRPC code 3 (`Transaction is invalid or closed`) in concurrent tests while Android compilation was active. No production retry workaround or test suppression was added. The final focused 23-test run and root's 133-test run passed after compilation ended; emulator reliability under resource contention remains a verification limitation.
- Syntax checks passed for the changed server modules and function entrypoint. Total final integrated evidence: **259 tests** (126 Flutter + 133 Node).

## Release boundary

These changes are local and were not deployed or installed. The earlier messaging release dependencies remain unresolved: production session/relationship rules differ from the hardened local policy. Chat Storage reads also need a separately verified membership authorization design within the Storage cross-service read budget; existing bearer download URLs are not revoked by removing a member. Do not release group attachments or describe them as revocable/private merely because upload grants and Firestore membership tests pass.

The inbox still reads all matching conversation documents before display pagination, media caching is not durable, and message search covers loaded history. Calls, disappearing messages and end-to-end encryption are outside this change.
