# Arabic eligibility UI — review-only integration

Built on PR #164, commit `b4495553f0101e0ec4ffd4086b2d5c502ff4aace`.
This change connects an Arabic Flutter preview to the existing V2 eligibility
callables. It is NOT a deployment, identity-verification service, legal opinion,
or completion of all registration/content-authorization work.

## Scope and compatibility

Four new Dart implementation files, three test/support files, this document and
four additive lines in `lib/ui/auth/auth_security_check.dart`. No edits to ARB or
generated localization, manifests/lockfiles, legal policy text, backend handlers,
Firebase configuration, security rules, existing signup or account data.
The existing `LegalPolicy`/`LegalDocument` parser is reused.

The new `UNISPACE_LEGAL_ELIGIBILITY_PREVIEW` compile-time flag defaults to false.
When explicitly enabled in a development build, V2 wraps the protected child of
`AuthSecurityCheck` AFTER the existing security/MFA challenge decision. If both
preview flags are true, V2 takes precedence; it never falls back to V1 on error or
missing configuration. With default flags, existing behavior is unchanged and no
eligibility client is instantiated. No build or server setting was enabled here.

This is an integration into that specific protected-child seam, not a review or
replacement of all navigation, deep-link, signup and reactivation routes.

## User-visible flow

- Missing declaration: read the available documents, enter day/month/year and
  explicitly confirm accuracy. Fields start empty; no default adult date or date
  imported from an editable profile. Changing a field clears its confirmation.
- Western, Arabic-Indic and Persian digits are normalized. The client validates
  Gregorian syntax (including leap-day validity) but does NOT calculate age or
  decide whether a birth date is in the future using the phone clock. The server
  remains responsible for its `Africa/Algiers` date and eligibility decisions.
- The immutable-declaration correction requirement is explained before saving.
  No in-app bypass or automatic overwrite is provided. Support contact is exposed;
  this change does not claim that a reviewed correction workflow already exists.
- Under the selected product minimum: no acceptance button and no protected child.
- Represented phase: own unchecked terms/community choices and privacy
  acknowledgment, followed by the server-confirmed representative-required state
  when appropriate. Personal acceptance is NOT representative approval.
- Independent phase: fresh personal choices, including after a transition to 19
  whenever the server reports renewed acceptance as required.
- Representative-required: explain that no current reviewed approval was confirmed;
  manual status refresh, support and sign-out remain available. No invitation is
  sent, no actual reviewer/representative is fabricated, and no turnaround is promised.
- Only a valid V2 `ready` response for the current account releases the child.
  A successful mutation acknowledgment alone never releases it; status is read again.
- Disabled/missing configuration, errors, unknown states, inconsistent booleans,
  malformed documents and account changes remain closed in this V2 preview.
- Full document text is selectable. Opening it never checks a box or records a
  decision. Draft UI marker and support address remain available; no AI-training,
  marketing or paid-service permission is requested.

## Client/server contract

`CallableLegalEligibilityClient` has an injected transport seam for tests.
`FirebaseLegalEligibilityClient` binds it to `FirebaseAuth`, Functions in
`europe-west1`, and the existing `AuthSessionService.signOutFully` flow.

Only these endpoints are used:

| Endpoint | Payload |
| --- | --- |
| `readLegalEligibilityStatus` | Empty object |
| `declareLegalBirthDate` | `birthDate`, server `declarationContext`, `accuracyConfirmed:true` |
| `acceptEligibleLegalDocuments` | `fingerprint`, server `acceptanceContext`, `termsAccepted:true`, `communityAccepted:true`, `privacyAcknowledged:true` |

No client UID/time/guardian decision or editable-profile value is sent as authority.
UID is checked before and after requests and in responses. V2 write responses do
not return a fingerprint; they are parsed using the actual V2 contract, not V1.
The status parser checks `schemaVersion:2`, rules version, timezone, the permitted
phase/state combinations and all decision booleans before exposing `canProceed`.

An account-bound generation discards late reads/writes from old views and accounts.
Choices and transient birth input are cleared on status refresh, client/account
change and background suspension. Resuming reads status again. Nothing is written
to SharedPreferences or Firestore by this client, and no birth input is logged.
Timeouts do not cancel server writes: uncertain writes hide the editor/choices until
another status read, rather than announcing success or retrying a different date.
There is no automatic repeated mutation or continuous status polling.

## Verification — 17 September 2026

Prepared contract/service tests in `test/legal/legal_eligibility_contract_test.dart`
and widget tests in `test/widgets/legal_eligibility_gate_test.dart`, with synthetic
in-memory fixtures in `test/support/legal_eligibility_fixtures.dart`.
They cover payloads, strict state parsing, all status phases, malformed responses,
Arabic digits/calendar validation, explicit choices, stale responses, account
switching, timed-out writes, repeated status checks, sign-out, lifecycle refresh,
RTL/narrow/large-text layout and the default-off integration.

**These Dart/Flutter tests have NOT executed.** Flutter and Dart are absent in this
execution environment; attempts to obtain an SDK were unavailable due to network
access. Consequently compilation, analysis, formatter output, widget rendering and
runtime behavior are UNVERIFIED. No Node tests from earlier stages are represented
as fresh Flutter evidence. No Firebase Emulator/device test was performed.

The pinned base integration file was checked by Git blob hash. Local diff/whitespace
and patch-application checks are separate structural checks, not compilation or
proof of behavior. The full repository could not be cloned in this runtime; source
inspection used the connected GitHub actions, and local files are a scoped subset.

Required checks in a configured Flutter project (without preview flags for tests):

```sh
flutter test test/legal/legal_eligibility_contract_test.dart test/widgets/legal_eligibility_gate_test.dart
flutter test test/widgets/legal_consent_gate_test.dart test/widgets/privacy_policy_screen_test.dart
flutter analyze lib/features/legal lib/ui/auth/auth_security_check.dart test/legal test/widgets/legal_eligibility_gate_test.dart test/support/legal_eligibility_fixtures.dart
```

Use the repository's existing dependency/localization generation workflow as needed;
do not modify generated localization by hand or deploy Firebase as a test shortcut.

## Remaining release gates

Run the checks above, then exercise actual V2 Functions/Auth in an isolated test
project and on a device, including backgrounding, rejected/corrected dates, missing
policy, changed publication, representative revocation, and transition to 19.
Complete real representative authority verification, legitimate correction/review,
and public pre-login document/rights access. Replace the legacy privacy wording
only with approved text reflecting actual processing; operator identity remains
required. No new legal interpretation or age-policy change is made here.

Protect all applicable backend writes, direct database/storage access and all signup,
reactivation and routing paths using the server checks from #164. Foreground status
is not continuously streamed and a UI check is NOT an authorization boundary.
Account activation before this seam is not changed by the preview.
Complete rule/IAM, retention/deletion/backup, abuse and full regression testing.
Do not mark this PR production-ready or merge/deploy automatically.

Primary API references:
- https://firebase.google.com/docs/functions/callable
- https://api.flutter.dev/flutter/widgets/PopScope-class.html
