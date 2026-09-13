# Compact notification block checks

Local implementation; automated/build/device tests deferred by user request.

The community notification header retains its 30-document stream and a strict block-list future rather than creating new loads during each rebuild. Loading waits for both results; failures show retry instead of treating unavailable block data as an empty set. The full screen and header share a loader for blocked_accounts/blocked_users/blocked_by that propagates errors and checks the account after asynchronous reads. Auth changes reset the keyed stream, and local block revisions reload it.

The overlay rechecks blocks on opening and local block revisions. It hides rows while checking, offers retry on failure, ignores stale results and hides the original account's rows after an account switch. Its source remains a snapshot, not a live notification subscription. Dismissed IDs remain excluded after rechecks, and clear-all acts on the currently filtered overlay rows. Old account callbacks cannot dismiss new-account notifications. Opening uses the navigator context that survives closing the overlay, avoiding the old disposed-overlay context after an awaited content read.

Limits: remote block changes are observed by this row filter only on refresh/reopen/local revision; identity widgets have their own periodic authorization. Stored metadata and generic historical event rows still exist. Other uses of the legacy permissive loadBlockedUserIds helper are unchanged. Overlay initial notification documents can become stale while open, and full server-projected history remains future work.

Final cases: slow/failed block queries on header/overlay; retry; local block/unblock; account switch while loading/open; 30-item limit; filtering/clear-all excludes hidden rows; dismissed rows stay dismissed after recheck; overlay open-to-content navigation; normal read/dismiss/expand; UI sizing and build/regression tests.
