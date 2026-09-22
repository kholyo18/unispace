# Stage 3: raw profile read isolation

Base: `ae3e09f2dabf7f59d7dbae3bc8b6d7a7f796e6b3`, after the explicitly requested merge of #193.
This is a source/rules review candidate, not a deployment or a complete cloud security approval.

## Contract and migration

`users/{uid}` is a private raw document. Only an active owner can get it. Client listing,
filtered queries and aggregations of the root users collection are denied. Public profile,
search and relationship browsing use the already-existing authorized callables. No raw
profile copy, bulk data rewrite or live data mutation is required by this slice.

The remaining other-user accessors in `lib/main.dart` now use `PublicProfileService`:
AuthorProfiles.ensure, isUserPrivate, canCommentOnAuthor, isPeerUnavailable and
loadUnavailableUserIds. The last helper was not called in the reviewed source, but its
raw directory query was migrated to prevent later reuse of an unsafe path. Batches
perform at most five concurrent projected reads, deduplicate IDs and abort permissions
on session replacement; this is bounded concurrency, not a server-side bulk endpoint.
Private reduced profiles remain available accounts; canViewContent=false must not be
confused with an unavailable account. Failed availability/comment checks fail closed.

Retained direct-owner readers were traced through the full lib tree: authenticated
bootstrap/MFA/status stream, own profile/photo/cover settings, own notification identity,
hidden-word settings, owner-only profile branch, own follow enrichment, own chat-drawer
avatar, UserProfileService, security drawer and PrivacySettingsRepository. Subcollection
access is a separate policy and is not made safe merely by protecting its parent.

The old `/users/{userId}/{fileName}` rule was an odd-segment Storage-style path that
cannot select a Firestore document; it was removed as misleading dead policy, not
claimed as a new exploit. No Storage rule was changed.

## Client session boundary

The injectable PublicProfileReader is used by the real PublicProfileService. It rejects
invalid identifiers, missing authentication, malformed projections, and responses that
cross a viewer-session boundary. The service tracks authentication transitions in process
memory; the session key is NOT a credential or a server authorization mechanism.
Watchers cannot silently rebind to a later login. The server still authorizes every read.
Author identity caches are scoped to viewer session and local block/follow revisions;
old in-flight requests cannot populate a replacement scope. The profile screen guards
both owner snapshots and asynchronous loads against account switching. Cleared last-seen
values no longer leave a stale timestamp in memory.

This does not retract previously delivered profile/media data, clear all app/browser/image
caches, or guarantee immediate global invalidation after another device changes privacy.
Projected presence watches keep their existing 30-second refresh cadence.

## Server checks

readPublicProfile keeps its existing API, allowlisted field projection and block checks.
Malformed server-owned revocation cutoffs now fail closed, consistently with the rules.
New integration cases use Auth-emulator-issued tokens for REST requests; the production
handler is also exercised with the real Admin Auth/Firestore emulator clients. The handler
is invoked directly, not through the Functions HTTP emulator or a deployed callable URL.

## Verification

New CI reproduces exactly seven named raw-read regression failures against the immutable
pre-fix rules, then verifies current rules and client contracts. All existing backend tests
are also run by the inherited full-backend job. Flutter tests execute the production reader
logic with injected network/session boundaries plus the existing privacy and photo-widget
tests. Source-string checks alone are not treated as Flutter runtime evidence.

Fresh run results belong in the PR/evidence package; adding this document does not imply
those runs have already passed. Android analysis/build and physical-device checks remain
separate evidence categories.

## Rollout prerequisites and remaining work

Before any live rules deployment, re-fetch current releases and reconcile unrelated rules.
Confirm readPublicProfile, searchPeople, readFollowList and the previous callable migrations
are deployed and functioning; ship a compatible client or enforce an explicit upgrade policy.
Old clients that read other raw profiles will be denied. Keep the candidate warning intact.

Still open: profile/account-status write ownership, per-device token-bound revocation,
server-enforced messaging policy, notification integrity, legacy follower provenance,
Storage/token-URL authorization, dependency advisories, cloud IAM/App Check settings,
complete app cache retention and two-account physical-device/end-to-end testing.
