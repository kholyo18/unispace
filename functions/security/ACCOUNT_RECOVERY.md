# TOTP account recovery

This change is local and is not deployed. It adds `generateTotpRecoveryKey` and
`recoverTotpAccount` in the configured CommonJS Functions entry point.

## Configuration and verification before release

- Set the server parameter `RECOVERY_AUTH_API_KEY` to an Identity Toolkit API key
  for this same Firebase project. Do not use a key from another project. The key
  must permit the server's Identity Toolkit requests. Both functions refuse to
  operate when the parameter is empty, including refusing to issue unusable keys.
- Verify native Firebase TOTP enrollment is enabled. Issuance requires a recent
  (five minutes) Firebase sign-in with the TOTP second-factor claim and a verified
  email. Only accounts whose enrolled factors are all TOTP are supported.
- Test password and Google recovery against a dedicated staging Firebase project,
  including an actual lost response after factor removal. Auth and Identity Toolkit
  are mocked in the local tests; Firestore transactions and rules use the emulator.
- Google recovery is exposed on native clients. The current web UI exposes
  password recovery only; add a proper web Google credential flow before enabling
  that option on web. Provider configurations requiring reCAPTCHA Enterprise are
  not supported by this server adapter and fail closed.
- Merge the three protected collections (`mfaRecovery`, `mfaRecoveryAttempts`,
  `authRevocations`) and the authentication cutoff check into the complete deployed
  rules. The repository root rules are not a complete policy for all app features;
  do not overwrite production rules without reconciling them first. The cutoff must
  protect every applicable data/service boundary to immediately deny old ID tokens.
- Keep credentials, keys, Identity Toolkit request/response bodies and callable
  bodies out of application, proxy, and request logging. Configure monitoring and
  broader abuse controls for the public recovery endpoint before public release.

## Contract

The server creates one 128-bit random recovery key, returns it once, and persists
only its SHA-256 hash in a server-only collection. Creating another key invalidates
the earlier key. Old client-generated backup codes are never accepted. The key is
bound to the TOTP enrollment IDs present at issuance, not to a client profile flag.

Recovery requires this key AND a first-factor authentication performed by the
server against Identity Toolkit. Google sign-in has account auto-creation disabled.
Server MFA enrollment IDs (and localId, when returned) bind that proof to the Admin
user record. Caller-supplied UIDs and pending credentials are not accepted.

Ten attempts per normalized email are permitted per 15 minutes, counted before
credential verification. The limit is transactional and persists failed attempts.
This per-account limit may temporarily deny recovery after malicious attempts; it
does not replace infrastructure abuse protection or App Check.

The recovery transaction claims a 120-second lease. Functions have a 60-second
timeout. It revokes sessions, publishes a protected cutoff, removes the matching
TOTP factors, revokes again, then marks completion. No custom token is issued.
The user signs in normally and must re-enroll TOTP and create a new key. Legacy
email-based verification flags are preserved, not silently disabled.

If a stage fails, the operation stays resumable with the same key and first factor.
An active lease rejects concurrent operations. A completed operation acknowledges
retries for ten minutes without repeating mutations, then rejects the key. Recent
native MFA can replace a key from an interrupted operation after its lease expires.

Firebase Auth and Firestore cannot participate in one atomic transaction. The
handler rechecks the enrolled factors immediately before removal and refuses a
changed set. There is still a narrow concurrent enrollment window between that
read and Admin's replacement of the factor list; review this limitation and test
multi-device behavior before release. No security parity with major social
platforms is claimed by these local changes.

## Local checks

Run the Firestore emulator with project `demo-unispace-security` and config
`firebase.security-test.json`, executing:

    node --test --test-concurrency=1 functions/test/session-security.test.cjs functions/test/mfa-recovery.test.cjs

Flutter checks:

    flutter test --no-pub test/security_sessions_test.dart test/mfa_safety_test.dart test/account_recovery_test.dart

References: https://firebase.google.com/docs/auth/admin/manage-mfa-users and
https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/accounts/signInWithPassword
and https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/accounts/signInWithIdp.
