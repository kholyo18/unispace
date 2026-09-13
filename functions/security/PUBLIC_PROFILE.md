# Limited public-profile read boundary

Local implementation; no deployment has been performed.

`readPublicProfile` verifies the caller's ID token including revocation, checks the
protected auth cutoff, and reads the profile, target-owned follower relationship,
and both blocking directions in a Firestore transaction. Disabled, deleted,
frozen, missing and blocked targets return no profile data. Legacy UID-based
blocked_users entries are also recognized; arbitrary email/name entries are not
identity-resolved by this endpoint.

The response is constructed from an explicit list. Security settings, recovery
material, phone number, internal academic maps and unknown fields are never copied.
A private non-follower gets basic identity only. Email, academic details, social
links, presence and counts follow their privacy settings. Mutual-only counts are
conservatively withheld until a reciprocal-relationship check is added.

UserProfileScreen now loads visitor profile metadata and avatar through this
boundary. The owner can still read their own document. Visitor presence refreshes
every 30 seconds while the stream is subscribed; this is not instantaneous privacy
revocation. Errors close the profile view instead of falling back to a full user
document. Hidden metadata is cleared on later authorized responses.

This is separation at the response boundary, not a physical database migration.
Existing user records remain unchanged. Other app surfaces such as search, author
avatars outside this screen, follow-list pages, and chat still need a separately
scoped migration. Posts/comments are not served by this endpoint and their direct
query permissions must be audited independently. This change does not establish
repository-wide data privacy.

Before release:

- Deploy the callable together with the client that uses it. There is deliberately
  no unsafe client fallback if the function is missing.
- Reconcile the complete deployed Firestore policy. Keep full users documents
  owner-only and prevent visitors from forging target-owned followers entries.
  The local rules deny these writes; do not widen them to make follows work.
  Accepted-follow mutations need an authorized server path or a verified rule
  policy. A viewer-owned following document is not sufficient authorization here.
- Test a real staging account pair: private/public transitions, follow approval
  and removal, blocking, email consent changes, background/resume and network loss.
- Review the request cost and abuse controls for periodic authorized reads.

Local tests use real emulator Firestore transactions with mocked Admin Auth.
They do not prove the deployed rules, actual tokens or device behavior.
