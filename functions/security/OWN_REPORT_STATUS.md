# Own report existence

readOwnReportStatus accepts type, targetId and parentId (required for comment, null otherwise). It validates revoked-token-aware bearer identity and checks account/cutoff transactionally. The legacy report ID is derived from authenticated UID; stored reporter/type/target/parent must match. Only a boolean is returned. Current target visibility is not required: the caller can check their own historical report after content deletion or blocking. No target data is returned.

Client migrates all three callers, includes comment parent, rejects malformed responses/account switches, and handles errors without treating them as absence. The server applies a separate 120/minute per-user check quota. Submission deduplication remains authoritative; existence check is not a reservation.

Deploy callable before client. Reconcile rules to deny direct report access and protect communityReportStatusLimits. No deployment or runtime tests. Deferred: each type, missing/existing reports, forged identity/parent, legacy mismatch, revoked/disabled account, quota, malformed response, offline UI and account switch.
