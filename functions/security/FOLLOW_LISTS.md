# Authorized follower lists

Local implementation; runtime and automated verification deferred by user request.

readFollowList checks verified caller revocation, owner availability, blocks in both directions, private-account access and the requested list's everyone/followers/mutual/none audience on every page. Only owner-side accepted follower documents prove access, including both directions for mutual. Unknown audiences deny access. Owners may read their own lists.

Returns identity-only rows with viewer-relative accepted/pending state; excludes blocked, frozen, deleted and disabled accounts. Following mirrors need a corresponding authoritative follower record. Search discovery opt-out does not hide memberships in an otherwise permitted list. The client no longer fetches full member documents for names or avatars, and changing tabs makes a new authorized request. Pending requests are displayed separately from accepted follows.

Pages scan 50 memberships ordered by document ID, with a numeric offset so hidden member IDs are not exposed as cursors. The current bound is offset 10000 (10050 scanned memberships); a notice appears at the bound. Loaded rows are sorted newest first locally; this is not global chronological pagination. Numeric offsets can skip or repeat rows during membership changes; client deduplicates and provides refresh. Offset scans become costly on large lists; an opaque cursor/index migration is a separate follow-up. Search covers loaded rows only. List snapshots refresh on opening, tab change, explicit refresh, local block changes and follow actions, rather than a Firestore live stream. Previously delivered data cannot be recalled by the server. Auth and Firestore state are not atomic.

Deploy callable before client; keep foreign collection list reads and all relationship writes denied. Existing root rules are partial and must be merged into the complete production policy, never blindly deployed.

Final checks pending: all four audiences on both tabs; private/public and self; forged mirror; mutual one-way vs two-way; owner/member disabled/frozen; block in both directions; revoked token; pagination with filtered-only pages; concurrent membership changes; pending/cancel/accept states; tab/request races; errors clearing cached rows; avatar/name no full-document reads; device flow and existing security suites.
