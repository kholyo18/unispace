# Authorized moderation inbox

readModerationInbox verifies the bearer and the same server roster as moderation actions. Transaction rechecks account state and session cutoff before returning reports. Pages contain 50 reports of the requested status ordered by document ID, with explicit projection and timestamp transport. Four server aggregation counts are separate snapshots from the report page. Maximum response 6 MiB; oversized legacy pages fail explicitly.

Client replaces both direct inbox streams with refresh and load-more, decodes timestamps for existing cards, clears on auth changes/errors, rejects stale responses and reloads after moderation. Search and severity/date sorting cover loaded rows, labelled explicitly; pages use ID order, not global severity order. Counts omit legacy reports without status, as server equality queries do. Live updates require refresh.

Deploy callable before client. Complete Firestore rules still must deny unauthorized report reads/writes. Moderator target preview screen still reads live target documents directly and requires the next migration; this phase secures only inbox data and stored report snapshots. Existing client roster is still a visibility hint. No deployment or runtime tests. Deferred: role/cutoff denial, status filters, cursors, account switch, counts, timestamp decode, oversized documents, paging/search and action refresh.
