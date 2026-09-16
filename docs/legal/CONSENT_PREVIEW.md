# UniSpace — staged Arabic legal consent

**Review only. Do not merge or deploy as a production consent system.**
This slice records explicit acceptance of versioned documents and previews a gate;
it does not establish account eligibility, application-wide enforcement, or legal compliance.
No production policy, database configuration, rules, account data, or deployment was changed.

## Included

- `AuthSecurityCheck` retains its MFA/security check and wraps its protected child
  only when `UNISPACE_LEGAL_CONSENT_PREVIEW` is explicitly compiled as true. Default
  builds do not instantiate the consent client or call the new functions.
- Arabic RTL UI, three unchecked choices, individually selectable document text,
  versions/operator/publication date, retry and sign-out, and a selectable support
  address available without acceptance. Terms and community are separate choices;
  the privacy choice is an acknowledgment, not optional-processing consent.
- Status is re-read after acceptance and after resuming; previous-account responses
  and changed-document acceptances do not open the protected child. There is no
  local-preferences acceptance shortcut. Opening/scrolling a document proves nothing.
- `readLegalConsentStatus` and `acceptLegalDocuments` are registered in the existing
  CommonJS entry point, in `europe-west1`. These endpoints do not wrap any other API.
- Exact bodies and document metadata are archived; per-user receipts use server
  timestamps and are idempotent. No IP, device, message, identity scan or training
  permission is added to the receipt. No training or advertising code is enabled.

## Source and decisions retained

The user's `UniSpace_Legal_Package_AR.html`, editorial version 1.0 prepared
16 September 2026, remains a review draft, not a published policy. Its section
“الموافقات ومسار الأهلية وضوابط التنفيذ” supplies the privacy acknowledgment and
separation of optional training. The combined terms/community acknowledgment is
split into two independently unchecked controls without changing its subjects.
Support remains `unispace.0.1.0@gmail.com`; this UI only exposes the address and
neither sends mail nor claims a deletion request has completed. No operator name,
registration, address or guardian identity has been invented or seeded.

## Server contract and storage

`legalPolicy/current` is an Admin-managed document. Missing or `{enabled:false}`
means the staged feature is OFF, not that anyone accepted. A malformed enabled
configuration fails closed. The active object requires:

- `enabled:true`, `status:"published"`, `language:"ar"`;
- a nonempty, real `operatorName` (max 300 UTF-16 units);
- a valid UTC ISO `publishedAt`, not in the future;
- exactly three documents with ids `terms`, `community`, `privacy`; each includes
  `version` (1–80 ASCII letters/digits/dot/underscore/hyphen), `title` and exact
  nonempty plain-text `body`. The canonical publication is bounded to 128 KiB UTF-8.

Hashes are computed by the server, not trusted from client/config fields. Body,
title, version, operator or publication-date changes affect the fingerprint.
This is one Arabic publication, not completed EN/FR localization.

`readLegalConsentStatus` requires a verified authenticated caller and an empty
object. When enabled it returns that caller's UID, current publication, whether
acceptance is required and an account-bound `acceptanceContext`.

`acceptLegalDocuments` accepts ONLY `fingerprint`, `acceptanceContext`,
`termsAccepted:true`, `communityAccepted:true`, `privacyAcknowledged:true`.
The context is a public UID/fingerprint binding, not a secret or proof of reading.
UIDs, times, document bodies, guardian approval and AI permissions are not accepted
from the request. Authentication rechecks revoked tokens, the protected revocation
cutoff and unavailable account states. A missing user profile is allowed for a
new Auth account; that is NOT an eligibility or account-activation approval.

The transaction rechecks the current policy and performs all reads before writes:

```
legalPolicyVersions/{fingerprint}              exact publication + archivedAt
legalConsentRecords/{uid}/receipts/{fingerprint} immutable receipt + acceptedAt
legalConsentRecords/{uid}                       latestFingerprint + updatedAt
```

Receipt metadata includes schema version, authenticated UID, fingerprint, language,
per-document id/version/hash, the three decisions and `source:explicit_in_app`.
An existing valid receipt is acknowledged without rewriting its time. Corrupt
receipts or missing/mismatched archives fail closed and need operator review.
No client can repair them. The parent summary is not used to authorize acceptance.
Historical receipts remain; no blanket indefinite-retention policy is implied.

## Required before any production activation

1. Name the real operator and reconcile the actual published documents with the
   application's processing. Do not paste this test fixture or the review package
   as an effective policy. Replace/reconcile the old ARB privacy wording separately;
   this slice does not silently overwrite it.
2. Complete the user-selected minimum age 18, verified legal-representative flow
   for ages 18 to under 19, and renewed independent acceptance at 19. Do not treat
   an email, a client profile flag or this receipt as guardian/eligibility proof.
   Before-account-activation checks, Google/email signup, existing users, lifecycle
   reactivation and all route/deep-link paths require staging tests. This UI wraps
   the AuthSecurityCheck protected child only, not the entire application router.
3. Enforce eligibility and current consent on every protected server write,
   upload and direct database/storage boundary. A client build flag can be bypassed;
   it is not authorization. These two callables record decisions only. Policy
   changes while a foreground session stays open are not continuously streamed.
4. Reconcile the complete deployed Firestore policy. The accompanying rules file
   is a **fragment**, not a standalone deployment target. The existing repository
   root rules are themselves labeled an incomplete review candidate and are left
   unchanged in this slice. Remove any overlapping broad grants before asserting
   server-only protection of the three collections; verify ownership, read/write
   denial and revocation in real emulator tests. Admin access needs least-privilege
   IAM. Review abuse controls/App Check separately; no App Check enforcement or
   rate limiter was added to these endpoints.
5. Publish public documents/rights/deletion routes accessible before login and
   account creation. The authenticated in-app reader here is NOT that public site.
   The support address is only a manual contact route, not verified email delivery
   or automated deletion. Preserve support and rights access when consent is refused.
6. Implement receipt/archive retention, deletion and any justified retention holds,
   including backups. The package's proposed ordinary-account 30-day, support/report
   180-day and ordinary-security 90-day periods are not implemented by this feature
   and must not be represented as active. Handle any applicable shorter obligation.
7. Keep AI training off until per-lesson opt-in, rights/data checks, expiry and
   effective withdrawal exist. General consent never grants training. Review real
   provider regions/transfers; a Functions region is not proof all data stays there.
8. Run Flutter analysis/tests, Node 24, real Auth/Functions/Firestore emulator and
   staging-device tests. Confirm missing endpoint/offline states remain closed,
   revocation and disabled/frozen-account reactivation are safe, and receipt records
   cannot be forged via any other deployed API or rules match.

Use only a dedicated development/test Firebase project for technical preview.
Configure its complete rules and emulators first. The Flutter build flag is
`--dart-define=UNISPACE_LEGAL_CONSENT_PREVIEW=true`; do not enable it in production
or use it to substitute for the release gates above. No release command is run here.

## Verification record — 16 September 2026

Executed locally on **Node v22.16.0**, with no Firebase credentials:

```sh
node --check functions/legal/consent.js
node --check functions/index.js
node --test functions/test/legal-consent.test.cjs
```

Result: **55 unit tests passed, 0 failed**. Tests use a dependency-injected,
serialized in-memory transaction fake enforcing reads-before-writes and staged
atomic commit. They cover malformed policies, strict inputs, revoked/invalid
identities, unavailable accounts, explicit choices, stale versions, cross-account
requests, receipt/archival integrity, repeated requests and simulated commit failure.
The concurrent-request test uses that serialized fake, not real database contention.
These results are not Firebase Emulator, Node 24, production security-rule, real-token,
Flutter build or device-rendering results.

Added **13 Flutter widget tests**; **not executed** because Flutter/Dart are absent
from the working environment. They cover unchecked controls, readers, status reread,
retry/decline, stale responses/account changes, policy refresh, malformed state,
feature-off behavior, narrow RTL/large-text layout and the default security gate.
Run in the project's configured Flutter environment (without the preview flag):

```sh
flutter test test/widgets/legal_consent_gate_test.dart
flutter analyze lib/features/legal lib/ui/auth/auth_security_check.dart test/widgets/legal_consent_gate_test.dart
```

Use the project's existing dependency/localization generation workflow first when
needed. The full application's regression suite has not been executed.

Technical references consulted:
- https://firebase.google.com/docs/functions/callable
- https://firebase.google.com/docs/functions/callable-reference
- https://firebase.google.com/docs/firestore/manage-data/transactions
