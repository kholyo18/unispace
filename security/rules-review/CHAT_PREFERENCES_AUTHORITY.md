# Participant-owned chat preferences — review candidate

## Scope and baseline

Independent security continuation from main `649013837dab865e3509579f404be8ece9bb6b0b`
(#199 and #200 retained). Five changed files: the two synchronized Rules copies,
one real-emulator test file, one verification workflow and this document.
No Flutter source, dependency manifest/lock, live data, Functions registration or
Firebase deployment is changed. This is NOT the unpublished Stage 7 media patch.

## Defect and implemented boundary

The pre-fix `/chats/{chatId}` update predicate authorized any current member to
alter the other participant's personal settings. The normal Flutter chat list
uses `pinned_<uid>`, `muted_<uid>` and `deletedBy_<uid>`; the last flag filters a
conversation out of that member's list. The detail reader uses UID-keyed maps:
`muted`, `clearedAt`, `nicknames`, `theme`, `autoTranslate`, `autoTranslateLang`.
The clear cutoff filters messages in that participant's view, not the server
history. Mutating another member's canonical theme could also inject malformed
values into that member's reader.

New Rules allow only changes to the authenticated caller's entry in those six
maps. Parent replacement, deletion and mixed legitimate/forged writes cannot
remove or modify a peer or third-party entry. New chats cannot prepopulate other
identities' entries. The caller may remove their own preference; no message or
chat document is deleted by this operation.

Basic changed-value validation: mute/automatic-translation values are booleans;
nickname/language values are strings (empty allowed); a theme is a map; a new
clear-history cutoff must be a timestamp resolving to `request.time`. Own clear
cutoffs may be removed; this is a personal view preference, not a monotonic read
receipt. Unchanged legacy peer values are preserved, not silently repaired.

For the three existing flat flags, only the flag belonging to the current caller
may change or be removed; changed values must be booleans. The other current
member's flag cannot be initialized, changed or removed, even through a full
replacement. Unknown flat field suffixes are not an exhaustive schema allowlist;
they are not consumed for either current member. Membership remains immutable.

Flat flag ownership requires an unambiguous two-member direct chat. Create and
update now require two distinct nonempty string member IDs including the caller.
Malformed/duplicate/group-shaped legacy membership is not automatically repaired;
client updates fail closed. Valid two-member deletion-tombstone records remain
compatible. Read predicates and message predicates are otherwise unchanged.

## Compatibility and deliberately separate work

- Preserve #199 interactions and #200 read/typing enforcement, session revocation,
  suspension checks, legitimate direct-chat bootstrap and existing summary/unread
  operations. Unread and summary authorship are NOT secured by this slice.
- Do not infer confidentiality from ownership: the full chat document is readable
  by its members, including nickname/theme fields. The UI's local-display wording
  does not make those values secret. Confidential preferences need separate
  per-user documents plus a reviewed client migration.
- The existing detail writers using literal dotted keys in `set(..., merge:true)`
  are NOT repaired or bulk-migrated here. They do not gain authority over the
  canonical maps. The flat chat-list flags retain their existing valid format.
  Separate mute representations are not reconciled. Old clients and legacy
  records still need migration/compatibility review before deployment.
- Basic types are not a complete theme schema, URL/media entitlement check, message
  schema, all-route messaging/block policy, or receipt/background/offline redesign.
- Stage 7 must be rebased to preserve #199, #200 and this guard; do not replace main
  with its old full Rules files. Its previously blocked publication was not retried
  through a different channel. Nothing in this change enables private media.

## Fresh verification contract

The new suite uses actual local Auth and Firestore emulators, fixed demo project
and client REST commits authorized with emulator-issued ID tokens. Admin only
creates synthetic accounts/fixtures and inspects persisted data. It never proves
client access. Credential configuration and non-loopback endpoints are refused.
UID fixtures begin with digits and contain dots/backticks; every REST field-path
segment is quoted/escaped. No malformed HTTP 400 response counts as permission
denial; negative assertions require HTTP 403 / PERMISSION_DENIED.

Exactly nine named regression cases first returned HTTP 200 under the immutable
pre-fix main Rules, then passed with the candidate. CI verifies the exact names,
counts, exit status, nine 200-vs-403 assertions and zero skipped cases. It does not
accept an arbitrary failing command as security evidence.

Coverage includes both members, nested merge/update/deletion, whole-map deletion,
create-time injection, basic types, server timestamps, concurrent preference
updates, changed and unchanged legacy state, malformed member lists, valid
deletion tombstones, revocation/suspension/removed membership, atomic batches and
a combined six-preference/three-flag/read/typing write at the real Rules limit.
The workflow also reruns inherited message/activity tests. The existing full
backend workflow runs this test file automatically.

Local and CI counts, source hashes, commands and exits are recorded in the delivery
evidence and PR description after execution. No previous or unpublished Stage 7
result is counted as verification of this change. Physical-device behavior,
production Rules/IAM/App Check, iOS and live media/delivery are not established.
Candidate Rules are NOT a production deployment approval.

Primary references consulted: Firebase's "Control access to specific fields"
and "Add data to Cloud Firestore" documentation (map diffs, document-level reads,
merge maps and nested field paths).
