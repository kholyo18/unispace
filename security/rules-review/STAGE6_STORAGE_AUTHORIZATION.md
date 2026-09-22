# Stage 6 — bounded Storage upload authority

Review candidate only. Based on merged #196, commit
`f16a0d04ceae68a9ba138f44db0a6892eb193281`. No production deployment, data migration,
claim assignment, IAM change, package upgrade or token rotation is included.

## Scope and trust model

The 17 current Dart SDK upload sites (signup, profile, posts/poll edits, comments,
chat media/files and own wallpaper) now call StorageUploadService, which uses the
production injectable StorageUploadClient. The server prepareStorageUpload checks
the verified caller and exact path, content type and declared size. It checks
account/deletion state, post authorship/reservation, or comment visibility and
comment-audience/block relationships. Chat media issuance checks actual membership,
peer availability and messaging audience; personal wallpaper is not a message.
No direct-upload fallback is provided. File upload names in chat are random local
Firestore-generated IDs rather than millisecond collisions. This does not create
chat records or provide exactly-once delivery.

A server-only storageUploadGrants document binds a single bucket, object path, UID,
authentication time, size and MIME metadata for 30 minutes. Only profile images
and the caller's own chat wallpaper receive overwrite permission. Ordinary media
is create-only. Grant IDs and uploadedBy are attached as custom metadata; client
metadata cannot override the verified values. The client validates the response
and scopes in-flight results to its local viewer session. It does not automatically
retry or delete objects after an ambiguous failure.

The limits retain existing candidate/client contracts: profile/post images and
wallpaper 20 MiB; post videos 200 MiB; comments and chat image/video/audio 40 MiB;
ordinary chat files 20 MiB. This checks metadata and size, NOT image/video decoding,
virus scanning, or the truth of the supplied content type. Issuance is bounded to
60 grants per UID per minute. This is not a whole-application cost/abuse quota.

## Two-document Storage limit and lifecycle propagation

Firebase Storage Rules permit at most two unique cross-service Firestore reads.
The server-owned authRevocations record now also holds storageSchema,
storageAllowed and storageUntil. prepareStorageUpload updates that projection
transactionally after checking the real profile/canonical lifecycle/deletion and
revocation records. The projection expires after one hour. This leaves one
cross-service read for either the exact upload grant or the post/chat read/delete
check. Client access to both grants and authRevocations remains denied.

Every actual lifecycle transition invalidates Storage access in the SAME
transaction. Administrative reinstatement does not grant it again; a fresh
successful upload preparation is required. Durable deletion invalidates access
before external Auth operations. Existing revoke-all/recovery overwrite the
revocation record and therefore drop the Storage authorization; the cutoff also
invalidates old grant authentication. Out-of-band Auth disable is rechecked on
new issuance, not polled by Storage Rules: existing SDK authorization can remain
usable until its one-hour deadline or normal token expiry unless the cutoff is
explicitly raised. All live writers must be reconciled before rollout.

## SDK reads and deletes

Raw SDK metadata/reads are owner-only for profile, post and comment media. Existing
application post viewers use the authorized media callable; image URL consumers
are not silently rewritten in this slice. Chat SDK reads check current membership.
Lists/prefix enumeration are denied. Existing direct getDownloadURL calls after
uploads remain owner-compatible under the freshly issued access projection.
Read-only SDK callers outside the inventoried code are NOT automatically migrated.
Chat deletion requires current membership and reliable uploadedBy metadata; legacy
objects without it need server cleanup. Post deletion after its parent disappears
still needs the existing server-side cleanup rather than client authorization.

## Deliberate limits — NOT a private-media sign-off

1. Firebase bearer download tokens are long-lived shareable credentials. Tightening
   SDK Rules DOES NOT revoke them. Existing AND newly produced token URLs remain a
   release blocker for strict private media. A dedicated test records that a known
   token still downloads without authenticated SDK access; this is not counted as
   proof of confidentiality. Do not rotate tokens or remove getDownloadURL until
   publication validators and all rendering/caching consumers are migrated together.
2. A grant is a bounded upload reservation. Membership, privacy or block changes
   after issuance do not cancel that one exact upload for the remaining 30 minutes.
   The existing message/publication/comment authorization must still approve its
   eventual attachment. Unpublished/orphan object cleanup and shorter reservation
   product limits need review. These grants do not authorize reading other media.
3. Expired grants are removed by the existing scheduled cleanup worker; account
   purge also removes grants owned by that UID and preserves others. This is grant
   metadata cleanup, NOT deletion of all orphan file bytes.
4. No per-device token revocation, byte scanning, cloud IAM/App Check review, live
   Storage policy reconciliation, OS/device delivery or E2E sign-off is implied.

## Deployment order and verification

Production firebase.json is deliberately unchanged: only the new
firebase.storage-security-test.json points to the Storage candidate. Deploy and
verify prepareStorageUpload plus lifecycle/deletion changes and the compatible
client BEFORE selecting any candidate Storage policy. Review historical inactive
accounts and current rules from production. Old direct-upload clients will fail.
Do not publish all root candidate policies as an unreviewed replacement.

Tests use explicit demo projects and loopback Auth/Firestore/Storage emulators,
real production authorization handlers, client multipart/resumable Storage requests,
and injected Dart transport/storage boundaries. Admin SDK only seeds fixtures in
raw-access tests. The baseline is the archived 2026-09-14 Storage policy, not a
statement about what is deployed today. Actual emulator/build results are recorded
in the PR after reading logs; static source tests are not device/runtime proof.

Primary references: Firebase Security Rules behavior (two-document cross-service
limit), Firebase StorageReference Android/Swift API (long-lived shareable download
URLs), and Firebase Emulator Suite Storage connection documentation.

## Verification-discovered correction: Storage content overwrite semantics

The first stage-6 candidate incorrectly assumed `allow update: if false` rejected
content replacement. Its actual emulator run passed 75 of 76 checks: re-uploading
an existing post returned 200 when the test required 403. Firebase's official
Storage core-syntax guide defines create as file-content writes and update as
pre-existing metadata updates. This was a candidate policy defect, not an inferred
emulator-only defect, and the failing assertion was retained.

The revised content-write conditions explicitly require resource == null for
ordinary post/comment/chat objects, with only own profile/wallpaper replacements
permitted under an explicit overwrite-capable grant. Additional tests use fresh
grants with different same-length bytes, verify original bytes remain unchanged,
and exercise metadata-only identity reassignment. Four named regressions run
against the immutable first candidate before running the revised policy. They are
not a claim about currently deployed live Rules. Source: Firebase Storage Security
Rules core-syntax, Granular operations section.
