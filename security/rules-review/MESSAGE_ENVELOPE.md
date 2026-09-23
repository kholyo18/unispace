# Message update envelope — review candidate, no deployment

Base: `ab806dc09deabf16194107984f192de132d82b06` after #207.
The pre-change root Rules blob is `4eed49551c76e24301796bd602ca041cc8a33dab`.
The reviewed chat screen blob is `2958c1000fe590242b5dca828e051a528a5ead99`.

## Outcome

Author update permission is now a field allowlist: text, editedAt, and the three existing participant-owned interaction containers. Changing text requires a string. A changed editedAt must be the current server request time. The existing interaction validation is still required for both authors and peers. Adding, changing or deleting a media reference, creation time, message type, reply attribution or an unknown field through update is denied, including a mixed batch.

The current Flutter edit writes text and a server editedAt. Reactions, stars, receipt additions, author deletion and text-only legacy updates remain allowed. Unchanged malformed legacy envelope fields do not block otherwise legitimate text edits. No extra Rules document reads were added.

This is an UPDATE integrity boundary, not a complete message schema or media confidentiality design. Create permissions are unchanged. A legacy text-only update may still omit an edit marker. Author deletion remains possible; delete-and-recreate of a document ID, complete creation validation, per-chat unread/summary authority, all-route block/messaging policy and private-media publication remain separate work. No historical data is migrated.

## Executed local evidence

29 new client Rules cases against the unchanged, hash-verified base: 8 compatibility passes and 21 assertion failures for the intended permissive behavior, no cancellations/skips or setup failures. After the change, 125 cases pass: the same 29 plus 96 existing chat/activity/interaction cases, with no failures/cancellations/skips. The 21 failures are test scenarios, not 21 independent vulnerabilities.

Tests use Auth emulator-issued IDs and actual Firestore client REST requests. Admin only seeds/inspects synthetic fixtures. All requests are restricted to loopback and demo-unispace-security; no production credentials, user data or FCM sends are involved. Local Node 22, pinned retained dependency cache and Firebase CLI 15.18.0. Local source is a scoped reconstruction; the complete current main is tested by remote CI before merge. Remote results are recorded in the PR after execution, not assumed here.

The root and review Rules files remain identical. Production Firebase configuration, Storage rules, backend handlers, Flutter source, dependencies and native files are unchanged. No Firebase deployment, Android/iOS build or physical-device result is claimed by this backend/Rules slice. The original whole-app release blockers remain open.

## Owner handoff

Do not deploy the candidate Rules before reconciling live Rules, deployed Functions, supported client versions and migration needs. A separate read-only Cloud Shell evidence collector and device-test checklist are provided to the owner; they do not deploy or repair production automatically.
