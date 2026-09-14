# Transitional short-lived media downloads

readPostMediaDownload authorizes the post through the existing reader, matches the exact requested URL against projected image/video/poll/repost media and accepts only the configured Firebase bucket's community_posts objects. It reads object metadata, creates a five-minute V4 signed read URL bound to its generation and rechecks post access/membership before returning it. No arbitrary bucket/path signing. Signing requires the deployed service identity's signing permission; verify IAM in deployment preparation. Uses two existing content-read quota units per call.

The explicit save-to-gallery path uses this callable for Firebase-hosted media, with no fallback to the old token URL on failure, and keeps existing pre/post-download authorization checks. Non-Firebase external URLs retain their existing authorized-download path; no signed access claim for them. Display players/images and stored URLs remain unchanged. No token rotation/deletion or Storage policy deployment.

This is not complete private media delivery. Existing long-lived Firebase URLs still work until migrated/revoked. A signed URL is a bearer URL valid for up to five minutes; it does not immediately revoke on block/privacy/session changes. Downloaded/cached files cannot be remotely withdrawn. Signing/byte retrieval are not atomic with Firestore permissions. Media caches remain keyed by download URL, so repeated signed URLs can duplicate cache entries.

Deferred: IAM signing, all supported media/repost shapes, foreign bucket and mismatched URL, revoked/private/blocked/deleted access, generation replacement, expiry, lost responses, quota, actual gallery save and external source parity. Deploy callable before client. No runtime tests/deployment performed. Next: design display refresh/cache handling and migrate stored token URLs with a reviewed rollback plan before revoking existing tokens.

## Full-screen pager images (incremental migration)

The currently selected Firebase image in _PostPagerPage now requests a signed URL through AuthorizedPostImage. Neighboring Firebase images no longer prefetch using stored token URLs in this pager. Switching away clears the URL; returning obtains fresh authorization. Failed signing or image fetching shows an explicit retry which requests a new URL, without token fallback. The enclosing authorized pager retains account/lifecycle/privacy invalidation. Image bytes already displayed do not need periodic URL renewal; this does not promise immediate remote revocation. Cache remains keyed by the signed URL and is not purged by expiry. External/local images retain their existing paths.

Scope excludes inline feed images, other viewers, video playback and their prefetch paths. Existing tokens remain valid. No cloud changes or tests performed. Deferred checks: switching images/posts/accounts, background/resume, delayed response after navigation, retry after expiry/denial, zoom/swipe, IAM, cache and quota behavior. Deploy callable before this client. Video migration must preserve playback position and handle range requests across expiry before rollout.

## Full-screen pager Firebase videos

The selected Firebase video now obtains a signed URL, downloads to the existing cache and plays the local file. Firebase video neighbors do not prefetch. Authorization and current video membership are checked again after download. Failed signing/download/initialization offers explicit retry with a new URL; there is no fallback to the stored token URL. Concurrent initialization for the same index is coalesced. Account, selection, post and mounted guards prevent installing a stale controller; uninstalled controllers are disposed. Returning to an already initialized Firebase video preserves its local position within the current pager page.

No timed controller replacement is needed for file playback after URL expiry. A failed or expired download restarts through explicit retry, without partial download resume. Streaming fallback for Firebase media is intentionally removed, so a cache/download failure no longer plays via a token URL. External and local video paths retain their existing behavior. Inline videos and other viewers remain outside this phase; old tokens and cached bytes remain accessible. Remote revocation is not immediate. Enclosing pager lifecycle/access invalidation still applies.

Deferred runtime checks: large/slow downloads, expired signatures, retry, rapid swipes, account/background changes, video initialization failure, file codecs, playback position, quota and IAM. No tests, build or deployment performed in this phase.

## Poll image navigation authorization

The post card's poll-image tap now rereads the authorized post and requires the exact current image slide URL before opening the existing viewer. A shared opening guard prevents duplicate navigation; account, post, block, moderation and profile revisions discard stale results. Failure stays on the card with an error. This is an entry check only: SimpleFullscreenImageViewer still uses the stored URL and has no continuous authorization. It does not complete poll media delivery migration.

Feed-card signed media migration remains pending request batching/rate-budget design: issuing two content-read quota units per image would compete with feed/profile reads during scrolling. Deferred tests include removed slide, private/blocked/deleted post, auth/revision changes while loading, rapid taps, and ordinary image/poll rendering parity. Source review only; no tests or deployment.

## Poll Firebase image viewer delivery

After the existing entry authorization, Firebase-hosted poll images open _AuthorizedPollImageViewer. It provides the existing simple viewer an optional imageBuilder using AuthorizedPostImage; callers without the builder retain existing rendering. Zoom, swipe-close and controls remain in the original viewer. Local block/moderation/profile revisions replace the image state and request fresh signed authorization. Background/inactive clears the child image, resume requests a new URL, and account change replaces it with an unavailable message. Subscriptions and lifecycle observers are disposed on close. No raw-token fallback on signing/fetch failure.

External poll image URLs still use the original viewer after the entry check. Card previews and other viewers remain pending. No remote immediate revocation, token rotation, cache purge or deployment. Deferred runtime checks: zoom/close, lifecycle transitions, auth changes, local revisions during signing, expiry/retry, and all existing simple-viewer callers. Source review only.

## Bounded media-link batch

readPostMediaBatch accepts postId plus 1-10 distinct URLs (4096 chars each). The shared handler checks all exact media memberships against the authorized post before signing, signs sequentially, then rechecks access and all memberships before returning any links. Failure rejects the whole batch. Single-link response remains compatible. Each batch uses two existing content-read quota units, not two per item. Metadata and signing work still scales per file. No cross-post batch or quota increase.

AuthorizedPostImage now uses PostMediaLinks, grouping same-user/same-post requests in one event-loop turn, deduplicating URLs and splitting groups into sequential chunks of ten. It validates complete response membership and expiry before resolving callers, rejects account changes and stores no completed links. Existing widget generation guards still discard stale results. Requests arriving in later turns are separate: there is no guarantee that all images on a page combine, and no batching across posts. Gallery/video callers keep the single-link endpoint.

Card images still require their separate rendering/prefetch migration. This infrastructure alone does not protect card previews or solve feed-wide quota pressure. Deploy the batch callable before the updated image client. Deferred tests: 0/11/duplicate/malformed URLs, mixed allowed/disallowed files, revoked access during signing, incomplete responses, split batches, errors, account changes and single-link compatibility. No tests or deployment performed.

## Card image delivery

_PostCard._buildImageSlide passes the post ID for Firebase images into _AutoSizeImage. Both dimension lookup and rendered image use the resolved signed URL; the original URL remains the identity used for navigation. PostMediaLinks batches requests made in the same turn. The card's own image prefetch skips Firebase post and poll images. Other global prefetch paths still require inventory/migration.

The image clears and reauthorizes on source/post/account changes, local block/moderation/profile revisions, and app resume. Background clears displayed protected images. Generation guards reject stale signing and dimension callbacks. Errors offer retry. Existing sizing/fit/tap behavior is retained; external/local images keep their original source. Completed signed URLs are not stored outside widget state, though downloaded images remain cached. No immediate remote revocation or token rotation.

This does not finish all card media: video and other prefetch consumers remain. Offscreen constructed cards can still request authorization, and across-post quota pressure remains a rollout concern. Deferred tests: scrolling and quota, dimensions/fit, deleted/private/blocked posts, image changes/reordering, account/lifecycle/revision races, retry and external/local parity. Source review only, no tests or deployment.

## Feed image prefetch

The feed-level _precacheImages helper now skips Firebase URLs for both post images and poll slides. Its initial-load, pagination and new-post callers retain external-image prefetch. Firebase card rendering continues through the signed-image path. Source search of explicit precacheImage calls in main.dart confirms the feed, card and authorized pager prefetch loops all exclude Firebase URLs. This is not proof that all other image/network consumers are migrated. No token revocation, cache deletion, tests or deployment. Deferred: scrolling/placeholder behavior, external-image prefetch parity and request quotas. Card video remains a separate pending migration.

## Card video initial delivery

Post/poll Firebase video cards pass a post ID to _VideoSlideWidget, request a signed URL through PostMediaLinks when visibility triggers initialization, download the file, then recheck post access and exact video membership before installing the controller. Account and local block/profile/moderation revisions invalidate in-flight work. Errors offer retry without token fallback. File playback does not require timed URL renewal. Firebase poll video pre-initialization through its old token URL is skipped. Comment/external/local callers retain their existing source path.

The initializer now disposes an uninstalled controller on failure and releases its existing initialization gate exactly once after acquisition (the prior disposed-during-download branch released twice). New post/path keys avoid retaining a controller when the card source changes.

Remaining: after initialization, ongoing lifecycle/revocation handling and the shared fullscreen controller path still need migration. This change secures initial delivery, not immediate revocation of already downloaded bytes. Deferred tests: visibility loading, slow download/access change, retry, codecs, mute/play/fullscreen, gate contention, comments parity. No tests or deployment.

## Card video lifecycle and fullscreen entry

Protected card videos now pause/mute and hide on account changes, local block/profile/moderation revisions, and background/inactive transitions. In-flight initialization is invalidated by generation. Resume leaves an explicit retry which obtains fresh authorization. Visibility cannot restart suspended playback. Fullscreen entry rereads post access and exact video membership; repeated taps are guarded. Invalidation schedules removal of this video's route only, and stale navigation continuations do not touch the old controller. Existing fullscreen gestures/controls remain. A queued fullscreen startup checks mounted before seeking/playing.

Remote changes without a local revision are still not immediately detected while playing. Cached bytes remain. Tests of controller lifetime, route removal, rapid retry, background/fullscreen, account changes and external/comment compatibility remain deferred; source checks only, no deployment.

## Comment image entry authorization

Comment actions now carry the parent post ID through root and nested-thread constructors. _CommentMedia receives that ID and the comment ID. Image taps reread the authorized post, find exactly one currently projected comment (including replies), and require the same image URL and non-video type before opening. Duplicate taps are guarded, and account/post/comment/URL/local revision changes discard the result. Hidden or blocked comments absent from server projection cannot open through a stale tile.

This is an entry check only. Inline comment images/videos and the existing fullscreen viewer still use their old delivery paths. Signed comment media needs an explicit comment-aware backend contract; post media authorization alone is insufficient. Deferred: nested replies, removed/hidden/blocked authors, duplicate IDs, changed media, rapid taps and navigation races. No runtime tests or deployment.

## Comment signed media endpoint and image opening

readCommentMediaDownload accepts postId/commentId/url and uses the shared signer in comment mode. It finds one unique comment in the authorized post projection, validates nested and replyToId ancestors (rejecting missing/duplicate/cyclic ancestors), requires image/video/gif and the exact URL, and restricts the object to the configured bucket's community_posts/postId/comments/authorId/commentId/ prefix. Access and membership are rechecked before return. Single/batch post endpoints retain their existing response shapes. Two content-read quota units per request.

Firebase comment image opening now requests this signed URL before navigating, without token fallback. External images retain the preceding entry check. Legacy Firebase attachments outside the canonical uploader path fail closed; inventory/migration is required before rollout. Inline comment images/videos remain pending. The fullscreen viewer receives a single short-lived link; expiry retry currently requires closing/reopening, and lifecycle/revision invalidation within that viewer remains pending. No token rotation or immediate remote revocation. Deploy endpoint before client.

Deferred: nested/flat ancestors, duplicate/cycle cases, hidden or blocked parent/author, wrong URL/bucket/object owner, replaced media, permission changes during signing, expiry and old endpoint regression. No tests or deployment performed.

## Comment image previews and viewer refresh

AuthorizedPostImage accepts an optional comment ID and uses readCommentMediaDownload in that case, keeping post batching unchanged. The lifecycle-aware image wrapper is reused for Firebase comment previews and fullscreen. Both use signed links, explicit retry, account invalidation, local revisions and background/resume clearing. Preview uses a bounded 220px cover layout; fullscreen uses the existing simple image viewer's zoom/swipe/close behavior. Original URL remains identity only in these rendering paths. External images retain the previous viewer and preview. Comment videos remain pending.

Opening retains the comment entry check; the viewer now resolves its own link and retries in place instead of receiving a one-off signature. Signed requests for comments are not batched. Remote revocation and cached-byte deletion are not implemented. Deferred runtime checks: image/GIF sizing, gestures, retries, account/lifecycle/revisions, denied parent comments and quota. No tests or deployment.

## Comment video delivery and playback

Firebase comment videos now pass post/comment IDs into the existing protected video card. It requests readCommentMediaDownload and requires mediaType=video, downloads the file, then calls again to recheck the exact comment and its ancestors before installing the controller. Fullscreen entry repeats that comment-aware check. The endpoint adds the current mediaType to comment responses; post response shapes are unchanged, and image clients ignore the additive field.

Existing protected-video lifecycle behavior now applies to these comment videos: local account/privacy/block/moderation changes and background suspend playback, invalidate pending work and close the tracked fullscreen route; retry obtains fresh authorization. External comment videos remain on the previous path. No token fallback or remote immediate revocation.

Rechecking currently reuses signing and discards the second URL (extra metadata/signing work). Initial load costs four existing content-read quota units; fullscreen entry costs two more. This must be included in quota/load testing before rollout. Deferred: comment/ancestor denial, type changes, slow download, account/lifecycle, retry, fullscreen, external compatibility and service deployment order. No tests or deployment performed.

## Access-only comment video rechecks

verifyCommentMediaAccess uses the same comment signer factory in a server-selected access-only mode. It preserves authenticated post reading, unique comment/ancestor checks, exact media membership, configured-bucket and canonical object-path validation, then returns authorized/postId/commentId/source/mediaType without Storage metadata access or signing. The mode is not controlled by request data. Invalid mixed modes fail at factory construction.

Video initialization still requests one signed link. Its post-download check and fullscreen entry now use access-only responses, checking identity and video type before continuing. Existing generation/account/revision guards remain. Initial download now uses three content-read quota units instead of four; fullscreen entry uses one instead of two. No quota increase and no cached authorization. This check verifies Firestore authorization to already downloaded bytes, not current Storage object existence/generation. It does not make access atomic with playback or revoke cached bytes. Deploy new callable before client.

Deferred tests: same denial cases as signing, malformed/mismatched response, no signing/metadata during access-only calls, account/revision races, quota accounting and old endpoint regression. No runtime tests or deployment.

## Remaining-source inventory and feed video prefetch

Source review found _prefetchFirstVideos still downloaded the first post/poll video using its stored URL during initial feed load and pagination. It now skips Firebase URLs, leaving first-external-video behavior unchanged. The protected card's visibility-triggered download handles Firebase video delivery.

Confirmed pending entry: _PostCardState._openPostMediaFullscreen falls back to FullscreenMediaViewer when the post cannot enter FullscreenPostPager. The fallback still uses original image URLs and video cache/network sources despite its preceding post authorization. This must be migrated before old tokens can be revoked. Existing media previews in editing/picking and standalone image/video viewers need call-site tracing and compatibility review; raw network calls alone do not establish that they are public content readers. LiveAuthorPhoto is profile media and is outside the community-post media path policy. No claim of repository-wide migration completeness.

Deferred runtime checks: initial/paginated feed video loading, no legacy Firebase prefetch, external prefetch, fallback controls/gestures and quota. No tests, deployment, token revocation or cache deletion.

## Single-post fullscreen fallback migration

_PostCardState._openPostMediaFullscreen now opens FullscreenPostPager with a single freshly authorized post when no swipeable feed entry exists. It preserves the selected media index and passes the same menu/change/block callbacks. The shared pager supplies post metadata, image zoom, video controls, comments, voting and tags. This intentionally standardizes the fallback on the pager's interaction behavior, including its close control, rather than maintaining separate legacy fullscreen logic.

This entry now inherits active-page authorization, signed Firebase image/video delivery, lifecycle invalidation and retry. FullscreenMediaViewer's old class remains untouched; a source search should find only its constructor declaration in main.dart, but this is not proof that every other standalone viewer or editor is migrated. No token rotation, tests or deployment. Deferred checks: profile/standalone card entry, posts containing both polls and ordinary media, selected index, menu hide/delete/block, return updates, comments/tags/votes, close and zoom gestures, and parity with multi-post entry.

## Download selection previews

_DownloadMediaSheet receives the freshly authorized post ID. Its Firebase image thumbnails now render through the lifecycle-aware authorized image wrapper and batched post-link resolver. Selection keeps original media identities; save-to-gallery authorization remains unchanged. Video thumbnails remain static icons without fetching video. External/local previews retain existing sources. Local revisions, account changes and background/resume invalidate signed thumbnails through the wrapper.

This closes the raw image path in download selection, not editing previews. Deferred: multi-selection, small-grid loading/error layout, deny/retry, repost and poll images, account/lifecycle, quotas and gallery-save parity. No tests or deployment.

## Existing editor image previews

CreatePostScreen's _existingImageUrls previews now use the authorized image wrapper for Firebase URLs with the editing post ID. Original URLs remain in the edit payload and selection/removal arrays; signed URLs are presentation-only. Local newly picked images and external images keep their original paths. Existing videos render static icons in this editor, without fetching their URL. Missing post ID fails authorization instead of falling back to a token URL. Lifecycle/revision invalidation and retry are inherited. No change to edit saving or upload behavior.

Source tracing also confirmed an additional active post video route: _buildAutoSizeVideoSlide -> _AutoSizeVideo is called for ordinary videoPaths, distinct from _VideoSlideWidget used for poll slides. Its downloader/fullscreen path still needs migration; earlier card-video work did not cover it. Editor repost embeds and poll-editor media need further tracing. Do not treat community media migration as complete.

Deferred tests: editor paging/reorder/removal, loading and failure layout, account/background changes, saved URLs staying original, local media parity and authorization quota. No tests or deployment.

## Ordinary post AutoSizeVideo migration

The active _buildAutoSizeVideoSlide route now passes a post ID for Firebase videos. _AutoSizeVideo requests a signed link on visible initialization, downloads locally and rechecks exact current post video membership before installing its controller. Existing aspect-ratio sizing, visibility threshold and single-video coordinator remain. Failed/uninstalled controllers are disposed and the initialization gate is released once. Protected errors offer retry.

Account/local privacy/block/moderation revisions and background suspend/hide playback, invalidate initialization and release the playback coordinator. Retry after resume reauthorizes. Fullscreen uses the existing authorized post-pager callback with a separate controller, avoiding the old shared-controller continuation for this protected path. External/local paths retain original delivery. Runtime verification of paging, timers, single-player behavior, retry, fullscreen and lifecycle is deferred. No tests or deployment.

Remaining release work is not limited to this path: finish tracing editor poll/repost previews and other viewers, reconcile Firestore/Storage policy with all live features, inventory legacy media paths/tokens, complete automated and two-account/device tests, then deploy services/client/rules in a compatible order. No claim of end-to-end security completion.

## Repost embed hero images

_RepostEmbedCard._mediaHero now renders Firebase images through the authorized image wrapper using the loaded original post ID. Comment reposts additionally supply the original comment ID, selecting comment/ancestor authorization. Missing identifiers fail closed. The source reload/navigation and text remain unchanged; external images retain their previous rendering and video heroes remain static placeholders. Wrapper lifecycle/local revisions and retry protect image delivery, including use in editing reposts.

This does not migrate _CommentRepostPreview used by the repost composer, share-card rendering, or all poll editor media. Text in the existing embed still follows its own refresh behavior. Deferred: post/comment repost images, hidden/blocked original authors/ancestors, editor embeds, missing source, aspect ratio/gestures, retries and quota. No tests or deployment.

## Repost composer comment preview

_CommentRepostPreview receives original post/comment IDs from _RepostComposePage. Its Firebase image/GIF preview uses the comment-aware authorized wrapper; external URLs and static video placeholders remain unchanged. The comment preview is no longer under an active IgnorePointer so its retry button works. The embedded post preview remains noninteractive. Composition text and submit/publish paths are unchanged. This does not reauthorize/redact the cached text itself or complete share-image rendering migration.

Deferred checks: deleted/hidden/blocked source or ancestor, missing ID, retry, image/GIF fit, lifecycle/account changes, draft preservation and publish parity. No runtime tests or deployment.

## System share image preparation

System sharing now rereads the authorized post, resolves its first Firebase image through the signed-link batch service, preloads that image before offscreen rendering, and builds the card/text from the same fresh snapshot. After rendering it rereads access and compares title/body/author/photo/first image before opening the OS share sheet. Account/post/local revisions cancel stale work; duplicate preparation is guarded. Signing/image failure cannot fall back to stale text; the existing text-only fallback for a null rendered file uses fresh data after the final check.

Profile photos remain on their existing source path. Already exported/shared files cannot be revoked, and access is not atomic with external sharing. Temporary share-file cleanup, renderer timing, and the separate copy-text action remain pending. Deferred tests: denied/deleted/changed post, slow images, signing failure, text-only posts, account/revision changes, image capture and OS sharing. No tests or deployment.

## Share menu copy-text authorization

The share menu's Copy text action rereads the authorized post and builds its payload from the fresh title/body/author. Post/account/local block/profile/moderation guards run before clipboard writing, with duplicate-call protection and an error on failed access. A stale tile cannot supply text after a denied read. Copy link remains an identifier-only operation; selection-based copying elsewhere is outside this change. Clipboard writes are not atomic with later privacy changes and copied content cannot be revoked. No clipboard action was executed during implementation. Deferred: denied/changed post, account/revision races, payload/link parity and OS clipboard failures. Source review only; no tests or deployment.
