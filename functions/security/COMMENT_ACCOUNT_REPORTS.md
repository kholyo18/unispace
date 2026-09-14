# Comment and account report submission

Client submissions now call submitCommentReport or submitAccountReport. Only target IDs, reason and details (maximum 10000 characters) are accepted; owner identity, snapshots, severity, timestamps and history are server-derived. Client method retains legacy optional arguments for caller compatibility but does not transmit them.

Comment submission uses authorized post preflight, then transaction checks for primary post availability/privacy, revocation, account availability and blocks. It resolves one unambiguous comment and checks nested and legacy flat ancestors for removed/hidden state, disabled authors and both-way blocks, retaining current comment vote access semantics. Account submission uses authorized profile preflight and transaction rechecks of account state, cutoff, followers and blocks; private profiles remain reportable using only projected visible fields. Self reports are rejected on the server.

Both writers keep legacy IDs and reject mismatching existing identities (including comment parent). Duplicate reports leave existing moderation state/history unchanged. New reports and the shared 60-new-reports/minute per-user quota commit together. Comment and account reports do not affect post report counters. Firebase Auth and repost-original authorization remain preflight snapshots. No legacy report or count backfill.

Deploy both callables before the client. Firestore rules must later prohibit client report writes and protect communityReportLimits. Existing own-report existence reads and moderator reads/actions remain direct Firestore paths pending migration; they are not secured by this change. No deployment or runtime testing performed.

Deferred tests: comment nesting/flat ancestry, duplicate or missing IDs, hidden/removed ancestors, changed parent, blocked/disabled authors, self reports, private profile fields, concurrent duplicates, existing moderation status, quota boundary, forged fields, callable errors, UI reporting and hide/block follow-up flows.
