# Storage candidate — ownership slice

Based on the published fachub-c631c.firebasestorage.app rules retrieved 2026-09-14. Not wired into firebase.json, not compiled/tested or deployed.

Changes: post images/videos require the authenticated author of an existing Firestore post (including reservation). Comment uploads require the UID in the path and an existing post. Chat objects require membership; chat wallpapers additionally bind filename to current UID. Account image writes stay owner-only. All authenticated rules add authRevocations cutoff checks. New objects have nonzero size/type limits. Existing post/comment/chat media overwrites are denied, except profile images and own chat wallpaper which current UI replaces intentionally.

Proposed limits: profile/post images and wallpaper 20 MiB; post videos 200 MiB; comment media 40 MiB; chat images/video/audio 40 MiB (published limit retained); chat files 20 MiB (existing UI cap). Profile/post/comment limits are provisional new product limits and require UX alignment. MIME metadata is a constraint, not validation of actual file bytes. Comment putData and profile putFile currently omit explicit MIME metadata; verify extension inference or add correct metadata before deployment.

Compatibility: post paths images/image_N.jpg and videos/video_N.ext can repeat on retry; create-only may reject a retry after a previous successful upload. Design object retry/overwrite handling before deployment. Ownership checks cannot delete post media after the Firestore post is deleted: deletion cleanup needs a server job/receipt policy. Chat files and own wallpaper were present in code but denied by the published folder allowlist; candidate adds them with limits. Media paths without uploader metadata cannot safely authorize legacy chat deletions or overwrites, so these are denied pending migration.

Privacy limitations: post/profile/comment SDK reads remain available to authenticated users in this ownership slice. Existing Firebase download-token URLs can be used outside these authenticated SDK rules, so these changes do not revoke shared URLs or enforce private-content delivery. A token/delivery strategy plus current post/block/privacy and chat access policy is still required. Comment upload checks do not enforce full canComment/privacy/block authorization (createComment does); a malicious user could still create orphan objects under their own path on an existing inaccessible post. Upload reservations/quotas and cleanup need separate handling.

Cross-service firestore.get/exists uses the default database and may require Firebase Storage service-agent permissions; verify access-call limits and setup. Each rule uses at most two distinct cross-service documents (revocation and post/chat). Session cutoff is not an immediate Firebase Auth disabled-state check.

Deferred: compile/emulator tests; owner/nonowner uploads; stolen UID paths; revoked sessions; chat member/nonmember; every MIME/size boundary; profile/signup photos; post reservation/edit/retry/delete; comment media; wallpapers/files; retained download URLs; cross-service permissions and two-account app tests.

## Filename follow-up

New-post upload filenames now contain random per-helper-invocation IDs; edit uploads consistently use the per-edit random ID. This supersedes the earlier fixed-name/timestamp collision note. One SDK task still uses its original path, so resumable upload behavior under create-only rules needs final testing. Orphan cleanup and download-token privacy remain unresolved; no deployment.
