# Push token account binding and logout

Local implementation; automated/device tests deferred by user request. No deployment.

syncPushDevice now transactionally binds the token hash in server-only pushTokenOwners to the authenticated UID/auth_time. Rebinding to another account records the old account's auth_time cutoff for this token. Per-token per-user revocations reject delayed registrations from the detached session even after another account binds the token. Same-second reauthentication can still share auth_time and be rejected; signing in again later resolves that boundary. Possession of a token remains the registration proof; app attestation is not added here.

detachPushDevice accepts only token, verifies the session and removes matching own token records without deleting a newer auth_time registration. It revokes this user's session for the token and clears its binding only if still owned by this user/session. Cleanup never deletes another account's binding. Existing limit of 400 duplicate records remains.

The common signOutFully drains pending push synchronization, suppresses new registration for the signing-out user, attempts server detachment and FCM deleteToken, then signs out. The two previously direct sign-out paths now use it. Cleanup failures do not prevent logout; offline/revoked-auth cleanup can remain unconfirmed. A new account's successful registration rebinds the token, so stored copies under the previous account are excluded from delivery even if they remain in its collection.

Push dispatch consults the binding and authRevocations before each batch. Legacy tokens with no binding retain prior compatibility until migrated. Payloads include recipientId; foreground display and notification taps reject a mismatched account. Native background notifications already delivered/in transit cannot be retracted by this guard. Auth state changes without the common logout path do not guarantee immediate token deletion; successful re-registration provides the ownership boundary.

Limitations: reads are not atomic with FCM delivery; offline logout may leave a valid registration; legacy tokens without binding and legacy payloads without recipientId need migration; per-session document revocation is not yet bound to push (global cutoff is); old rotated tokens are not all enumerated; durable cleanup/retries and registry retention are separate work. No claim of complete offline logout privacy. Detachment can add up to a pending sync plus bounded network waits to logout.

Final verification: logout online/offline; direct OTP/recovery paths; account A to B on same token; delayed A sync after detach/rebind; stale detach after newer login; revoked global auth cutoff; token refresh during logout; same-second reauth; server registry access denial; recipient mismatch display/tap; two devices same account; normal push; build, regression suites and device tests. Deploy both callables, push handler and complete rules before the client.
