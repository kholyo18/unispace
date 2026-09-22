# Message interaction authority — bounded continuation

Base main: `924cdbf61bee2301464a35213befcc2d51682dae`.
This independent five-file slice does not contain the unpublished Stage 7 private
media implementation. No Firebase deployment, live reads/writes, old-data repair,
dependency upgrade, application source or asset changes are included.

## Contract

Both message authors and other current members may change only their own nested
`reactions` and `starredBy` entry. Author ownership no longer bypasses this check.
Deleting/replacing a parent map cannot remove another participant's entry.
A reaction is a legacy string (1–32 characters) or 1–6 unique such strings. This
preserves the six current quick reactions and legacy string-to-list transitions.
A star is true or absent, matching the current Flutter toggle's true/delete path.
Other members may perform these actions without editing text or message identity.
New messages may omit these containers, or initialize only the sender's entries.

The existing message-level `readBy` list is append-only: a caller can add only its
own UID, without duplicates or removal/reordering of other identities. This does
not prove human attention, and does NOT protect the distinct chat-level
`lastReadAt` map used by today's UI for its seen indicator. That map, typing state,
unread counters, the full message schema and all-route messaging policy still
need separate review; no comprehensive receipt or message-integrity claim is made.

Only changed metadata containers are validated. This preserves legitimate author
text edits on old records with malformed but untouched metadata. Such malformed
containers cannot be client-repaired into a new shape by assuming ownership.
No historical values are removed. A trusted, reviewed migration remains separate.
Deleting a whole own message remains allowed by the existing policy; this also
removes its metadata. Stars remain in shared message documents, not a new private
bookmark store. Their visibility is unchanged.

## Client/source reconciliation

At the reviewed main commit, `lib/features/shell/chat_page.dart` blob
`7cb2dc3558dd370adff0e7c0e128640a8a0be71d` uses dotted `.update` operations for
`reactions.${_me.id}` and `starredBy.${_me.id}`, with FieldValue.delete for removal.
The emulator suite uses actual REST commit/update masks and array transforms,
including concurrent updates and atomic denial of a mixed valid/invalid batch.
It does not merely mock the rule decision. Admin SDK only seeds and inspects data.

## Execution evidence at implementation

- Eight specifically named tests fail against the immutable pre-fix rules, then
  pass with the candidate. Seven show overbroad authority; one shows the existing
  recipient-star action incorrectly denied. Exact names and counts are checked.
- Final local focused suite: 60 passed, 0 failed, 0 skipped on Node 24.21.0 with
  Firebase CLI 15.18.0, Java 21 and local Auth/Firestore emulators. 35 cases are new;
  25 are the existing chat boundary suite, not new coverage.
- First focused run: 58/59. Its nested-array fixture was rejected by Firestore's
  data model (HTTP 400), before Rules. Replaced it with a legal array containing a
  nested map so the unchanged HTTP-403 assertion actually tests Rules. Also added
  a distinct duplicate-reaction case. No failure expectation was relaxed.
- A local combined suite reached the pre-existing follow tests and exceeded the
  command deadline; it was terminated and is NOT counted as a full pass. Broader
  CI execution must be inspected separately before merge.

## Rollout boundaries

These are still candidate Rules, not verified live Rules. Coordinate old-client
behavior before deployment; clients that wrote other participants' metadata will
be denied intentionally. The pending local Stage 7 Rules patch must be rebased
onto this policy, preserving BOTH metadata ownership and private-media guards;
blindly applying its older full rule file would undo this fix.

Stage 7 source publication/Android/device verification, bearer-URL migration,
server-side message policy, per-device token binding, historical provenance,
dependency advisories, live IAM/App Check and staged rollout remain open.

Platform reference: Firebase, Control access to specific fields,
https://firebase.google.com/docs/firestore/security/rules-fields
