# Notification actor presentation

Local source changes; automated/build/device tests deferred by user request.

All four identified notification name surfaces and single/stacked avatars now use readPublicProfile through PublicProfileService. The renderer never uses stored sender/actorPhotoUrl as an identity fallback or reads full user documents through LiveAuthorPhoto. Loading, denied access, missing UID and network failure show neutral identity. Stacked actors are checked separately. Private profiles still expose their permitted basic identity, according to the existing projection.

Each mounted identity widget reloads on actor change, local block revision and auth-account change, and every 30 seconds. Previous identity is cleared before requests and stale async responses are ignored. Timers/listeners are disposed with the widget. This uses independent name/avatar requests and is not a batched identity subscription; visible-list request volume and refresh flicker need device measurement. Remote block/disable changes can remain visible until the next refresh. Profile destination initialName/photo seeds no longer come from stored notifications.

Historical event rows/counts and stored metadata remain, including generic plural like counts. This is rendering protection, not a server-projected notification list or deletion of old identity snapshots. Non-content notification message bodies and chat-specific routes remain separate work. In-flight image/network caches and already delivered messages cannot be retracted here.

Final checks: four name surfaces; all stacked avatars; blocked/disabled/deleted actor; network failure; unblocking; private basic identity; account switch/stale responses; long RTL names; avatar layout and accessibility; refresh cost/flicker; read/dismiss/open unchanged; build and prior tests. Callable must be deployed before release.
