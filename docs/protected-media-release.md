# Protected media release procedure

This procedure prepares Android build 2. Do not enforce the minimum version or revoke legacy tokens until the new client has passed device and live-storage acceptance tests. The version gate is compatibility control, not binary attestation; authorization remains server-side.

## Phase 1: additive backend

Deploy the new readReleasePolicy, readProtectedMedia, prepareProtectedUpload, finalizeProtectedUpload and cleanupProtectedUploadStaging functions, updated create/edit post/comment validators, and reviewed Firestore rules. Keep releasePolicy/android absent or enabled:false during testing. Existing storage.rules is the transitional grant-based configuration, not the final cutover rules.

Verify the deployed function service account can sign V4 URLs and perform generation-conditional Storage copies/metadata updates. Use an isolated test account and disposable objects. Do not grant broad IAM roles as a workaround without reviewing the exact missing permission.

## Phase 2: safe client acceptance

Install build 2 on an actual Android device. Verify login/session initialization, signup avatar, profile and cover updates, chat wallpaper, image/video/audio/document upload, publication, playback, thumbnails, cache return, cancellation, account switching, sign-out, private accounts, blocking, revoked sessions and removed group members. Verify view-once remains separate and inaccessible through readProtectedMedia. Test upload progress and retry on a slow connection.

Test a disposable legacy token on real Storage: capture object generation and metageneration; remove firebaseStorageDownloadTokens with both flat preconditions; confirm the old URL fails, the object remains, and authorized signed delivery still succeeds. The local Storage emulator retains its separate downloadTokens list on this metadata mutation, so its token-revocation case currently fails and cannot serve as live-cutover evidence. Do not suppress that failure or treat the migration as production-verified.

Verify the newly uploaded final object has no permanent download token. Confirm unauthorized users cannot obtain signed URLs. Record tested build, live checks, and release artifact hashes before proceeding.

## Phase 3: publish and enforce

Publish the tested client to the intended distribution channel first. Confirm its download/update link is available to users. Set releasePolicy/android enabled:true and minimumBuild:2 only after that. New clients show the update screen; old clients lack that UI and may receive app-update-required errors. The old app cannot be retroactively given a new update screen.

After independently confirming build 2 is the tested release, record protectedMediaVerifiedBuild:2 in the server-owned policy document. Do not set this merely because a build compiled.

## Phase 4: deny old client Storage access

Deploy Storage using firebase.protected-media-release.json explicitly. This config points to storage.protected.rules, denying direct reads, listings, creates and updates while retaining authorized owner deletion. Verify live denial and signed delivery before setting storageCutoverVerified:true. Do not accidentally redeploy transitional storage.rules after cutover.

## Phase 5: revoke old capabilities

Run functions/scripts/revoke-legacy-media-tokens.cjs in dry-run mode first with the explicit production project and bucket. Review scope and counts. Apply only with --apply and --verified-build 2 after every prior gate is satisfied. The tool checks the server policy markers, processes bounded pages, preserves file bytes and checkpoints progress. Repeat bounded runs until complete, then dry-run again to verify no tokens remain. Keep the enabled minimum version in place.

If a generation condition fails, investigate the replacement and retry; never remove the condition. Never restore old tokens to roll back. Roll forward a broken new client/backend while retaining privacy enforcement.

## Local scope

No production policy activation, Storage cutover, token revocation, public release, or Git push is part of local preparation. Device and live GCS tests remain release prerequisites.