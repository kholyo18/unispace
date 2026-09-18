# Account deletion operations

This document describes the production deletion path implemented by UniSpace. It is an operational runbook, not a privacy-policy substitute.

## In-app request

`requestAccountDeletion`:

1. Accepts only the authenticated Firebase UID. A client-supplied UID is rejected.
2. Writes `account_deletion_requests/{uid}` with a 30-day maximum operational window.
3. Marks `users/{uid}` as deleted/unavailable immediately.
4. Revokes existing sessions.
5. Deletes the Firebase Authentication user so a fresh login cannot recreate access while the data purge is queued.

The Firestore request is deliberately retained after the Auth user is gone so the scheduled server worker can finish an idempotent purge.

## Scheduled purge

`processAccountDeletions` runs every 15 minutes in `europe-west1`, with one active instance.

For each request it creates a random tombstone identifier and uses a lease. A timed-out invocation can therefore be retried without allowing two workers to process the same request concurrently.

The purge currently covers:

- the user's Firestore profile tree and Storage `users/{uid}/` prefix;
- username reservations, known rate-limit documents, publication/deletion receipts, and message requests;
- follow, follower, request, and block mirrors that belong to other accounts;
- posts owned by the deleted account and their Storage prefix;
- comments made on other people's posts: the deleted comment is removed, its media is deleted, and surviving replies are promoted/rewired instead of being deleted;
- the deleted UID in post votes and poll responses;
- chats: the member becomes a non-identifying tombstone, messages authored by that account are reduced to a deletion placeholder, that account's message media is deleted, and its reactions/star state/reply snapshots are removed while the other participant's messages remain;
- aggregate notifications where the deleted account was an actor;
- push-token ownership links;
- Firebase Authentication, idempotently, if it still exists.

## Retention

- Completed deletion-request audit rows: up to 30 days after completion.
- Security revocation records: up to 90 days.
- Reports/moderation evidence involving the deleted account: pseudonymized and scheduled for deletion within 180 days.
- A moderation row with `legalHold == true` or a future `legalHoldUntil` is not removed by the normal 180-day cleanup. Legal holds must be server/admin controlled and removed when the specific obligation ends.

Do not use a legal hold as a general-purpose archive flag.

## External web request

The public resource is sourced from `deletion-site/delete-account.html`. Firebase Hosting is configured with `public: "deletion-site"` and `cleanUrls: true`.

After merge and Firebase Hosting deployment, verify the exact public HTTPS address before entering it in Google Play Console. Do not enter a repository URL or a local file path.

The external page starts the request through the support email. When a user cannot sign in, support must:

1. Verify ownership proportionately. Never request a password, OTP, recovery key, or an unnecessary full identity document.
2. Resolve the Firebase UID from the verified account before deleting the Auth record.
3. Create `account_deletion_requests/{uid}` server-side with at least:
   - `uid`
   - `status: "pending"`
   - `requestedAt` server timestamp
   - `deleteBy` no later than 30 days from the verified request
   - `requestedFrom: "external_support"`
4. Mark the profile unavailable and remove/disable the Firebase Auth account immediately where operational tooling permits.
5. Let `processAccountDeletions` perform the same idempotent purge used for in-app requests.
6. Record only the minimum support evidence needed for the request and apply the disclosed support retention rule.

The client application must never receive an admin function that accepts an arbitrary UID for deletion.

## Firestore collection-group index prerequisite

The worker uses filtered collection-group queries. Firestore does not maintain filtered collection-group indexes by default, so production must have these three single-field collection-group indexes before enabling the scheduled worker:

- `notifications.actorId`: ascending, collection-group scope.
- `notifications.actorIds`: array-contains, collection-group scope.
- `revocations.expiresAt`: ascending, collection-group scope.

Export/reconcile the project's existing production index configuration before adding these entries. Do not replace an existing production index file with a deletion-only file, because unrelated application indexes may already exist outside this repository snapshot.

## Deployment and verification

Backend:

```sh
firebase deploy --only functions:requestAccountDeletion,functions:processAccountDeletions
```

External deletion page:

```sh
firebase deploy --only hosting
```

After deployment:

- open the public `/delete-account` page over HTTPS;
- confirm the support mail action works;
- submit a test account deletion;
- confirm Auth access is removed;
- confirm the request transitions `pending -> processing -> completed`;
- confirm owned Storage objects and Firestore profile data are gone;
- confirm another participant's chat messages/replies remain intact while the deleted account is anonymized;
- confirm expired 30/90/180-day records are removed and active legal holds are not.
