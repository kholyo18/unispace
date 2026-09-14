# Author identity synchronization

syncOwnPostIdentity uses authenticated UID, current account/cutoff and owner query in each 200-post transaction. Input is a cursor and a field selector: photo reads profileImageUrl; displayName reads displayName; fullName joins firstName/lastName. Values are never supplied by the client. Only changed authorName/authorPhotoUrl fields and updatedAt are written. Existing profile editor paths retain their distinct name semantics.

Client no longer reads/batch-writes posts for identity propagation. Paginated helper checks current UID and cursor progress. Partial failures require retry; no background completion. Interleaved edits are not one atomic job. Does not authenticate arbitrary stored photo URLs or change profile-write rules.

Rules candidate now denies all direct post mutations. Direct post read is still retained pending migration of privacy account data export. Deploy syncOwnPostIdentity before compatible client/rules. No live deployment or runtime tests. Deferred: photo/name editors, full-name path, blank/malformed values, paging, concurrent edit, revoked/disabled session, account switch, partial failure and export compatibility.
