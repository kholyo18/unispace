# Remaining access migration — source audit, 2026-09-13

Scope: inspected local Firebase deployment configuration, rules, remaining community-post/notification references in lib/main.dart, and privacy synchronization helpers. This is a targeted source inventory, not an exhaustive validated security scan. No runtime tests or live rule reads/deployments were performed. All recent implementation phases remain local and unverified at runtime.

## Confirmed configuration gaps

- firebase.json points to firestore.rules. That file covers selected user/session/follow/recovery/support paths, but has no community_posts or users/{uid}/notifications policy. Unmatched operations are denied by this local policy; this does NOT prove what production currently permits. Deploying it as the complete app policy would break still-direct app operations.
- No Storage rules file or storage rules target was found in the repository configuration. The new comment media path must be checked against actual deployed Storage rules, including owner-only upload, content/size constraints and overwrite prevention.
- The owner-user rule allows arbitrary update/delete of one's whole users document. Server code relies on accountStatus and other profile fields. Separate voluntary privacy/freeze settings from administrator-controlled status/roles before defining field-level writes; do not treat an editable profile field as authoritative moderation state.

## Inventory and priority

| Priority | Path / code anchor | Observation | Required migration |
| --- | --- | --- | --- |
| P0 | firebase.json; firestore.rules | Local partial policy is configured as deploy target | Obtain/read the complete deployed Firestore and Storage policies, reconcile with client contract, then stage explicit rules; no blind replacement |
| Fixed in this slice | lib/main.dart: _applyVote, called by _toggleLike/_toggleDislike in media presentation | A third vote path still directly read/wrote voter arrays after card migration | Now calls setPostVote, uses committed result and blocks overlapping submissions per UID/post; runtime proof deferred |
| P1 | lib/main.dart: original-post _load / _fromSnapshot(widget.data) | Missing ID/document or read error falls back to cached repost content | Fail closed and use authorized current original-post/comment data before rendering; cover all quote variants |
| P1 | lib/main.dart: _postsRef / _baseQuery; profile _likedPostsStream / _dislikedPostsStream; saved/hidden content loads | Feeds and several lists still directly query full post documents | Authorized projections/query strategy and fresh content checks, including private authors and embeds |
| P1 | lib/main.dart: _openPostById, _openTarget, _openRepostedComment, media routes | Some routes fetch full documents before reaching CommentsScreen's new gate | Remove pre-gate raw reads; preserve deep links and selected comment navigation |
| P1 | lib/main.dart: _postsRef publishing/deleting; repost .add calls | Publishing, editing, deleting, repost snapshots still have direct client writes | Author/ownership enforcement, protected fields, current original references and transactional counts on server |
| P1 | lib/main.dart: moderator _action/_restore and kModeratorIds | Client batches update moderation state; moderator visibility uses a client ID list | Server-controlled role authorization on every moderation action; no reliance on UI membership check |
| P1 | lib/main.dart: pushNotification / pushNotificationFromMe / notifyFollowersOfNewPost | Other notification types still write to recipients directly | Inventory producers; move notifications tied to events to server, then limit client notification writes to owner's allowed read/delete actions |
| P1 | lib/ui/settings/privacy/privacy_account_overview_tab.dart: syncAuthorPrivateOnPosts / syncAuthorSearchFlagOnPosts / syncAuthorHideLikesOnPosts; main.dart duplicate private sync | Client batches update denormalized author flags | Treat live profile policy as authoritative; server synchronization or tightly scoped owner-only field updates |
| P2 | authorized-post and mutation handlers | Primary Firestore checks coexist with preflight Auth/original-post checks; snapshots and lost-response cases remain | Define concurrency guarantees; test revoke/block/delete races, stable retries and draft handling |
| P2 | content-search-page.js / follow-lists.js | Bounded scans, offsets, per-author calls and legacy embedded arrays | Measure latency/read cost at final verification; indexed/paginated design where needed |

## Order of work

1. Remove cached-original fallback and remaining pre-gate content reads using readAuthorizedPost.
2. Migrate remaining publishing/edit/delete/repost and moderation writes with explicit ownership/role contracts.
3. Reconcile the complete deployed Firestore/Storage policy with all current callers, including private per-user subcollections and notifications. Read-only retrieval is sufficient; no rule deployment is part of this audit.
4. Check failure/retry/media cleanup and old-client compatibility.
5. Run deferred analysis/build, callable/rules/storage tests and two-account device scenarios. Resolve failures before release claims.
6. Review the full diff, then separately push to the correct repository and stage/deploy only the verified functions/rules/client sequence when requested.

## Evidence limits

Observed direct client writes are migration gaps; exploitability in production cannot be established without the deployed rules. The source audit does not certify global confidentiality or readiness to deploy. Existing local tests cover earlier phases only and have not been rerun for the accumulated changes. diff --check is only a whitespace check, not a compiler or security test.
