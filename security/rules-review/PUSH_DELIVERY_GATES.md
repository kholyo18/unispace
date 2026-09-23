# Generic push delivery gates (no deployment)

Base: `e3fa989367f77c05d38af9cc0eafba1c124d2580` after #203.

## Scope and observable behavior

This is a defensive correction to the existing generic notification dispatcher and its foreground preference filter. It does not create a chat-notification producer, a per-chat authorization service, or a Firebase deployment.

1. `pushAllowed` and the actual Flutter `PushPreferencesService.allows` reject unsupported/blank notification types instead of silently enabling them. Reviewed kinds remain `new_post`, `like`, `like_comment`, `reply`, `comment`, `repost`, `follow`, `follow_request`, `follow_accepted`, `announcement`, and `exam_reminder`, with their existing category switches. The helper's legacy null-preference behavior is preserved ONLY for those recognized kinds; the dispatcher still independently requires a canonical session-bound registration.
2. Before each multicast batch, a non-self actor must exist and be enabled in Firebase Auth as well as satisfy the existing Firestore availability/block checks. `auth/user-not-found` suppresses delivery; other lookup errors propagate before FCM. Self-actor reuses the already performed recipient Auth lookup. Actorless system notifications retain their existing behavior.
3. Unknown `chat`, `message`, `chat_message`, and `dm_message` kinds cannot fall through this generic route. This is denial of an unreviewed path, NOT a completed implementation of chat notification muting. The reviewed configured entrypoint (`functions/index.js`) exposes `pushOnNotification` for `users/{userId}/notifications/{notifId}`; no chat-message creation trigger was found in this source review. This says nothing about manually deployed functions outside the repository.

## Verification and evidence boundaries

New tests execute 30 backend preference cases, 18 production-handler integration cases, 2 static Flutter wiring guards, and 25 Flutter preference-service cases. Auth and Firestore integration use credential-free loopback emulators and the actual registration/dispatch handlers. `sendEachForMulticast` is captured rather than sent. One explicit fault-injection case overrides the actor Auth lookup to exercise service-error propagation; other Auth/Firestore operations use the real emulators. NO real device or FCM send is performed. The new Flutter tests call the actual preference service without starting its network synchronization. Static wiring guards are not UI execution tests.

The final scoped local run passed 89 backend checks (50 new including the 2 static guards, plus 39 inherited push checks) and 76 Flutter tests (25 new plus 51 inherited chat preference/mute tests). Scoped Dart analysis reported no issues. These are selected suites, not a whole-repository certification.

Against the original three production files, the initial backend run reported 48 cases: 16 pass and 32 expected behavioral failures. Flutter baseline reported 13 pass and 12 expected unsupported-type failures. Positive compatibility cases remain enabled. The 501-token tests prove [500, 1] batching for unchanged valid records and suppression of the second batch when actor/type eligibility changes after the first call; they do not recall the first call.

One initial post-change 87-case run reported 86 pass / 1 failure during fixture device registration (`unauthenticated`), before the tested delivery gate. A 100-fixture diagnostic did not reproduce the underlying token-verification failure. A subsequent unchanged production-code run passed all 87. The final fixture also explicitly verifies the genuine emulator token before invoking registration, with NO retry, stubbed verification, changed credentials policy, or suppressed failure. The original failure remains retained and its root cause is unresolved; successful later runs do not erase it. Keep this review caveat visible.

Local verification reconstructs scoped source from retained repository snapshots and reviewed patches because direct outbound Git access is unavailable. The three production baselines are hash-verified against the live main's production subtrees. The local snapshot lacks #201's separate preferences-rule delta/test, some CI-only runtime workflows, and tracked generated localization in the local Git index; no full-current-repository test total is claimed locally. This PR changes none of those files, and remote CI uses the complete current main tree.

Local Flutter 3.44.9 / Dart 3.12.2 uses the retained offline package cache and locked `dart pub get --offline --enforce-lockfile` with FLUTTER_ROOT. Both behavioral baseline/current runs use `--no-test-assets`. A separate standard-assets attempt fails before tests because the retained package cache lacks the dependency asset `assets/lucide.ttf`; the application's own font assets are present. The failure is retained, not patched with a substitute asset. Remote CI uses freshly resolved dependencies and standard assets and must verify this layer. No SDK/font files are part of the deliverable.

## Compatibility, rollout, and remaining limits

Unknown/custom types previously delivered through the permissive default will now be denied. A future kind needs an explicit authorization/category contract and tests before being added; do not restore a permissive fallback. Generic fields such as `message` or a copied `actorName` do not constitute chat membership or mute authorization. This patch does not authenticate missing actor IDs for recognized actor-based kinds, validate the complete notification schema, or replace trusted notification producers.

Foreground filtering is NOT background suppression. Notification payloads may be rendered by the operating system in background/terminated states; server checks must precede FCM. Already-dispatched notifications and state changes after the last check can race delivery. The existing possible missing-recipient foreground/open compatibility path, stale payload opening, payload-size limits, retries/idempotency, full chat-message authorization/mute gating, and device tests remain separate open work. No live notifications, token records, data, IAM, or credentials were modified. No Rules, dependency manifests, application main file, UI layout, or Stage 7 source files were changed. No deployment was performed.

Primary references:
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- https://firebase.google.com/docs/auth/admin/manage-users
