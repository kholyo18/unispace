# Shared notification identity loading

Local implementation; tests/build/device measurements deferred by user request.

Notification names and avatars now acquire a shared entry keyed by actor ID for currently mounted widgets. Duplicate appearances of one actor share the in-flight request, current authorized projection and one 30-second refresh timer. Ordinary timer refresh skips while a request is pending. The last consumer releases the entry, cancels its timer and disposes its notifier; there is no persistent or off-screen cache beyond mounted consumers. The pool owns one auth listener and one local block listener while nonempty.

Auth-account changes and block revisions clear every entry and request fresh authorization. Generation and UID checks reject stale responses; released entries ignore late responses. Errors remain neutral and never fall back to old names/photos. Periodic refresh still clears the prior projection, preserving the earlier privacy behavior; refresh flicker is not claimed fixed. Invalidations may intentionally overlap an older request so they do not wait for stale authorization.

This reduces duplicated calls for repeated actors; it is not server batching across distinct users or an off-screen/lifecycle scheduler. Memory scales with distinct actors referenced by mounted widgets. Raw notification subscription/pagination and history projection remain separate work. Network savings and UI performance are not benchmarked yet.

Final checks: same actor name/avatar/multiple rows share one initial request; one consumer disposed leaves remaining active; last consumer cancels timer and ignores late response; actor change; auth switch and block while pending; request failure; refresh overlap; scrolling/route retention and mounted entries; Arabic layout unchanged; request-count measurement, build and regression tests.
