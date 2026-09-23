# Chat mute consistency — application repair, not a push rollout

Baseline: main `763255912be15d0a870c394c3855d97a44e5ec3f` (PR #202).

## Observable contract

Both the chat-list action and details use the same owner-specific mute decision.
A strict boolean true in either recognized representation, `muted[uid]` or
`muted_UID`, preserves an existing mute. Neither representation has trustworthy
ordering metadata, so false must not silently override the other's true.
An explicit new mute/unmute writes both representations in ONE document merge,
setting both to the requested boolean. This reconciles that owner's decision
without a bulk migration, dropping peer preferences, or changing Rules.

Unknown literal dotted fields such as `muted.uid` are not imported. Malformed
containers are tolerated by the reader but are NOT repaired in stored data.
The unchanged Rules reject writes through malformed stored canonical containers;
a denied atomic write must not leave only the legacy field changed.

The list binds the owner UID from its rendered chat entry and captures the local
viewer session BEFORE waiting for the popup selection. Account/session change,
logout, or a disposed context cancels the action. The writer then applies the
same queued-session checks as the detail client and is disposed in finally.
Failures show a generic message only in the same live context/session. There is
no optimistic saved-success announcement or raw backend error display.

## Scope and preserved boundaries

No Rules, Functions source, dependencies, manifests, lockfiles, native platform
files, existing live documents, IAM, credentials, or Firebase deployment change.
Pin/delete behavior is retained; the same menu-owner check also prevents a stale
popup from acting under a later account. Nickname/theme/activity integrations
from #199–#202 remain intact. The unpublished Stage 7 private-media draft is NOT
included, retried, or overwritten by this work.

## Evidence and limits

The new Flutter tests exercise the real production client and snapshot reader.
Three targeted behavior regressions fail against the immutable pre-fix client.
Three static checks characterize the prior list/menu wiring; these are source
contracts, NOT executed widget interactions. Existing preference tests retain all
assertions, with mute payload expectations extended to the second atomic field.

The existing Dart exporter produces the actual updated client payloads. The
Auth/Firestore emulator suite applies them through authenticated client REST
writes, checks both values, peer preservation, legacy-only/conflicting state,
peer impersonation, peer-field injections and atomic rejection on malformed
stored containers. Admin is used only for synthetic fixtures and inspection.
These tests do not replace physical-device FlutterFire transport testing.

This repair does NOT establish end-to-end push muting. It does not add a direct
chat message notification trigger or change FCM delivery. Server-side chat
notification authorization/mute gating, foreground/background handling and real
device verification remain separate work; a persisted UI option is not proof
that the operating system will suppress a previously submitted notification.

With old clients still installed, a one-field write can reintroduce conflicts;
conservative true-wins reading intentionally retains mute until an explicit
new-client operation reconciles both. Server-acknowledged state can also differ
from a pending/offline snapshot. Session guards cannot recall dispatched writes
or prevent later activity from another authenticated device. Preferences remain
readable by both chat participants: this is integrity, not confidentiality.
