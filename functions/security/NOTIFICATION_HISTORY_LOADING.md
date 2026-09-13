# Bounded live notification history

Local implementation. Automated/build/device checks deferred at user request.

The full notification screen now retains its query stream across local filter rebuilds. Load older increases the live window by 80 up to 400 records, retaining one listener rather than mixing an independently changing live head with stale cursor pages. This is an expanding bounded window, not unlimited cursor pagination; increasing the limit can re-read existing records. The UI explicitly states the 400-record ceiling. More remains available when a filter or blocked-user removal makes the currently loaded list empty. Classification applies to loaded records.

The blocked-user future is loaded once per refresh/account/block revision; waiting/errors do not default to an empty block list. Retry refreshes both sources. Account changes reset the window and StreamBuilder identity, and waiting snapshots are not shown from the prior query. Existing direct owner notification reads, raw stored metadata and compact notification surfaces remain outside this change.

Mark-read now clearly says read latest N and applies the same bounded limit, rather than claiming to read the whole history while only changing 80. This operation still queries at click time, so arrivals between display and click may change that latest window. Existing read/delete implementations and temporal grouping remain. Missing createdAt records remain outside the ordered query, as before. No historical backfill or migration.

Final checks: 0/79/80/81/400/401 notifications; empty filtered page with more; rapid filter changes do not recreate query; more/refresh/loading/error/retry; block-list errors fail closed; account switch; concurrent arrivals/dismissal and read latest N; temporal grouping; Firestore read-cost measurement; build and device regression. Beyond-400 archive access requires a separate cursor/archive design if needed.
