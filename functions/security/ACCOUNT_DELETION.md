# Account deletion implementation status

## Current implemented scope

- `requestAccountDeletion` is an authenticated callable in `europe-west1`.
- The callable never accepts a target UID from the client; it uses the authenticated UID.
- Bearer verification checks revocation, UID/auth_time, and tenant.
- Requests are stored at `accountDeletionRequests/{uid}` through the Admin SDK.
- Active requests are idempotent; a repeated request returns the current active state.
- The in-app Privacy screen exposes download-my-data, account-deletion request, retention policy, and privacy policy.
- `legal/account-deletion.html` is source for the required external deletion resource, but it is not a public URL until separately hosted.

## Not implemented yet

This change does **not** delete the Firebase Authentication user or recursively erase Firestore/Storage data.
A full deletion processor still needs a reviewed data map and tests covering, at minimum:

- `users/{uid}` and its private/subcollections;
- authored community posts, comments, reposts, poll responses, and media;
- relationship/saved/hidden/block data where the user is owner or counterparty;
- direct-message threads/messages and attachments;
- notifications, sessions, device tokens, recovery/security records;
- support and moderation records subject to the approved retention exceptions;
- Storage objects that are not located under a simple UID prefix.

Deleting only Firebase Authentication is insufficient because Firebase does not automatically erase all related Firestore/Storage data.

## Approved operational retention targets

- ordinary account/content removal: up to 30 days from a verified deletion request;
- support records: up to 180 days after closure;
- moderation/report records: up to 180 days after closure or last appeal;
- ordinary security logs: up to 90 days;
- legal disputes/obligations: only as needed for the specific purpose.

These targets are documented for implementation and review. They are not proof that automated lifecycle jobs are deployed.
