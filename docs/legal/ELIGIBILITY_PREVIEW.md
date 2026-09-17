# UniSpace — eligibility backend preview (stage after PR #163)

**REVIEW BRANCH / SERVER SLICE ONLY / NOT DEPLOYED / NOT RELEASE-READY**

Prepared against `kholyo18/unispace` commit
`c3743733ab292e479ea02d8f50eef7bea1fb2d1c`, the reviewed head of draft PR #163.
This stage does not change Flutter screens, the old consent endpoints, account
activation, signup, Firestore/Storage root rules, the published policy or live data.
Originally delivered as a local ZIP/patch. This review branch imports that package
without changing its JavaScript logic or tests. The repository import does not
deploy the feature, enable a policy or change live user data.

## Product contract retained

The project's selected rule is minimum age 18. From 18 to under 19, personal
acceptance AND verified legal-representative acceptance are required. At 19, fresh
independent personal acceptance is required, even for unchanged documents. These
are project requirements, not a declaration that this electronic process establishes
legal capacity, identity or compliance. General consent never grants AI training or
marketing permission.

## Implemented slice

Three new authenticated callable names are registered by one appended `require`
in the existing Functions entry point:

- `readLegalEligibilityStatus`: current server decision, published documents and
  account-bound request contexts. It does not mutate state.
- `declareLegalBirthDate`: explicitly confirmed Gregorian date declaration;
  server-generated revision and server timestamp; repeated identical submissions
  are idempotent. Client overwrites are refused. It does not activate an account.
- `acceptEligibleLegalDocuments`: version-, account-, declaration- and age-phase-
  bound personal acceptance. It records a receipt, not a representative's authority.

`createEligibilityConsentHandlers(...).assertInTransaction(tx, request)` is a
server-only integration seam for future protected mutations. It checks actual
request authentication, the revocation cutoff, account state, policy, declaration,
receipt and representative approval inside the caller's Firestore transaction,
before any writes. It denies when not configured or not ready. **No existing
application mutation, upload or signup function calls it yet.**

A successful status response or acceptance response is never a reusable permission
token. A future mutation must recheck in its own transaction; the tests demonstrate
that stale ready responses do not authorize subsequent guarded writes.

## Decision states

| State | Personal acceptance | V2 transaction guard |
| --- | --- | --- |
| `not_configured` | Not accepted | Deny, including absent/disabled policy |
| `birth_date_required` | Not accepted | Deny |
| `under_minimum_age` | Refused | Deny even with a representative record |
| `personal_consent_required` | Required in represented phase | Deny |
| `representative_required` | Personal receipt already present | Deny |
| `independent_consent_required` | Required at/after 19 | Deny |
| `ready` | Valid current-phase receipt present | Allow only this checked integration seam |

V2 reports `canProceed:false` when configuration is absent or disabled. The older
V1 endpoint's feature-off pass-through behavior is unchanged; do not confuse the
contracts or treat V1 acceptance as V2 eligibility. Both must remain unavailable
for production activation until the routing/enforcement migration is complete.

## Date handling and verification limits

Age is based on a Gregorian date and the server's calendar date in
`Africa/Algiers`, not the phone clock, device timezone or days divided by 365.
Inputs use exact `YYYY-MM-DD` ASCII form; invalid/future dates are rejected.
The preview conservatively uses March 1 for February 29 anniversaries in non-leap
years. This is a documented engineering convention requiring legal/operational
review before release, not a claimed rule of Algerian law.

The declaration is **self-declared**, NOT identity verification. It is stored in a
separate intended server-only collection, never imported from editable profile
fields. The client API cannot change it to reverse a prior age decision. A real,
reviewed correction process, appeal route and associated retention controls remain
to be implemented; do not reject legitimate correction requests indefinitely.
A future correction must mint a new declaration revision and invalidate linked
approvals. Creating new accounts or lying about a date is not solved by this module.

No actual guardian/representative was verified. No emails or invitations were sent.
No authority-check provider or reviewer interface was implemented. The backend
only validates the contract of an approval produced by a future trusted review
workflow. Without that record, a represented user remains blocked in V2.

## Intended protected storage

```
legalEligibilityDeclarations/{uid}
legalRepresentativeApprovals/{uid}
legalEligibilityReceipts/{uid}/receipts/{acceptanceContext}
legalPolicyVersions/{fingerprint}          # existing shared publication archive
legalPolicy/current                       # existing Admin-managed publication
```

The declaration stores the date, UID, server revision/time, rules version and
explicit accuracy confirmation. The date is not returned by status and is not
copied into consent receipts. Derived dates and declaration hashes are still
personal data; no anonymity is claimed.

A representative approval must be bound to the same subject, declaration revision,
publication and rules version, identify distinct representative/reviewer accounts,
reference a review, record authority verification and explicit document decisions,
have valid ordered server timestamps and be unexpired and not revoked. Acceptance
before age 18 is not valid for this represented-phase contract. A bare email,
boolean in `users`, or user-supplied approval cannot establish it. There is
**no public callable that creates, verifies or grants representative approval**.
Test approval objects are fictitious in-memory fixtures only; never seed them into
any live project or use them in place of an actual verification process.

Personal V2 receipts contain schema version, UID, policy fingerprint, declaration
revision, age phase, rules version, document id/version/hash metadata, explicit
choices, source and server acceptance time. At 19 the phase changes and yields a
new context/receipt key, so earlier represented-phase receipts cannot satisfy new
independent acceptance. V1 receipts are ignored, not deleted or silently migrated.
The exact publication archive is reused only after its content is checked.
Receipts are idempotent; retries do not rewrite the original acceptance time.

## Security and release blockers

The supplied `.rules` file is a fragment, not a deployable policy. Firestore allows
can overlap; an explicit false does not override another matching allow. Reconcile
and emulator-test the complete deployed rules, and least-privilege Admin IAM,
before calling these collections server-only in production. No security-rule
emulator test was executed here. Admin SDK access is not constrained by this
fragment.

Still required before release:

1. Actual representative identity/authority/consent verification, secure review and
   revocation controls, corrections/appeals, minimized evidence handling and access
   auditing. These are not solved by checking the shape of an Admin-created record.
2. Flutter date/notice/waiting/renewal UI, all Google/email/new/existing-account and
   reactivation paths, support and rights access on refusal, public pre-login
   documents and accessibility/localization/device verification.
3. Transactional enforcement on all protected mutations and compatible authorization
   on uploads, direct Firestore/Storage access and account activation. V2 endpoints
   alone do not protect the existing application. The old endpoint remains intact.
4. Approved operator identity and actual policy wording; legal review of the chosen
   calendar convention and capacity/representation process; provider/data-transfer
   review. A valid document parser does not validate legal adequacy.
5. Actual declaration/approval/receipt deletion and retention, backup handling and
   shorter applicable deadlines; data-subject correction and deletion workflows.
6. Real Node 24/Firebase Auth/Functions/Firestore Emulator and staging-device tests,
   contention, IAM/rules, App Check/abuse/rate-limit design and no sensitive payload
   logging. No rate limiter or App Check enforcement was added by this slice.

## Verification and repository import

Fresh recheck on 17 September 2026: 147 Node unit tests pass on Node v22.16.0.
The same 147 tests also passed with process timezones UTC, America/Los_Angeles
and Asia/Tokyo (three reruns, not 441 distinct tests). They exercise the actual new modules and
the unchanged policy module fetched from the pinned repository; its Git blob hash
was independently verified as `63079dcf84f7290e0adca4fde406a48133d645cf`.

The test collaborator is a serialized in-memory transaction fake with read-before-
write enforcement, staged atomic commits, simulated conflicts and callback retries.
It is not Firestore and does not prove real contention/rules/authentication behavior.
The registration test uses explicit dependency stubs, not a Firebase runtime load.
The suite includes a regression rejecting a representative approval recorded
before the subject turned 18.

The local source snapshot is a reconstructed subset, not a full repository clone.
Base index.js was matched to Git blob 1dedd2dedf75b37592d1dfbe2062df2cd421ae9a.
The seven-file package passed reverse-patch verification before this documentation
update; index.js changes by only the three appended registration lines.
All imported JavaScript files passed node --check.

Reproduce from this review branch:

```sh
node --check functions/legal/eligibility.js
node --check functions/legal/eligibility-consent.js
node --check functions/legal/register-eligibility.js
node --check functions/index.js
node --test functions/test/legal-eligibility.test.cjs
```

The project declares Node 24; rerun on that version in the development environment.
Flutter/Dart, Firebase Emulator, actual identity verification, live deployment and
the complete app regression suite were not run. No production credentials were
used, no Firebase records were written and no policies were enabled.

## Technical references

Official references consulted for the callable and transaction boundaries:

- https://firebase.google.com/docs/functions/callable
- https://firebase.google.com/docs/functions/callable-reference
- https://firebase.google.com/docs/firestore/manage-data/transactions
- https://firebase.google.com/docs/firestore/transaction-data-contention
