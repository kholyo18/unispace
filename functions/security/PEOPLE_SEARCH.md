# Private account discovery

Local implementation; not deployed or tested yet. Runtime and automated checks are deferred at the user's request.

searchPeople requires a verified, non-revoked signed-in caller and enforces 20 requests per minute per UID in a server-only document. It returns at most 8 identity projections (id, name, username, photoUrl). It checks both directions of blocking, search consent, frozen/deleted profile state and disabled Auth accounts. It returns no contact, security or academic fields. Email and phone matching require explicit consent and an exact stored-value match. Phone formatting is not normalized.

The existing bounded document-ID scan is retained: up to 960 profiles per request. This is not a complete or scalable directory index; the UI reports potentially incomplete results. Migrate to an indexed search directory separately. Per-account throttling is not protection against many-account abuse. Auth status and Firestore changes are not atomic; returned results are snapshots and opening a profile rechecks access.

Deploy the callable before its client. Keep full user documents private and peopleSearchLimits inaccessible to clients. The root Firestore rules are partial; merge with the actual complete policy, do not blindly replace production rules. Posts/comments search is unchanged and requires its own authorization review.

Pending final verification: exact opt-in email/phone matching; Arabic names and stop words; hidden/frozen/disabled accounts; both block directions and legacy mirrors; revoked sessions; throttle reset and concurrent requests; absence of extra fields; query races and clear-search; error notice while posts remain usable; no full-document avatar read; existing security suites and two-account device flow.
