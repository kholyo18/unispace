/// Server-authoritative revocation. Never accepts a target account in payloads.
class SessionRevocationClient {
  SessionRevocationClient(
      {required this.uid,
      required this.currentUid,
      required this.readSignedSession,
      required this.call});
  final String uid;
  final String? Function() currentUid;
  final Future<String?> Function() readSignedSession;
  final Future<Object?> Function(String name, Map<String, Object?> data) call;

  Future<void> revoke(
      {String? sessionId, String? keepSessionId, bool all = false}) async {
    if (uid.isEmpty || currentUid() != uid) {
      throw StateError('Session account changed.');
    }
    final active = await readSignedSession();
    if (currentUid() != uid || active == null || active.isEmpty) {
      throw StateError('Current signed session is unavailable.');
    }
    if (keepSessionId != null && keepSessionId != active) {
      throw StateError('Current session changed.');
    }
    if (!all &&
        keepSessionId == null &&
        (sessionId == null ||
            !RegExp(r'^[a-zA-Z0-9_-]{1,200}$').hasMatch(sessionId))) {
      throw ArgumentError.value(sessionId, 'sessionId');
    }
    final mode = keepSessionId == null ? 'single' : 'others';
    final result = await call(
        all ? 'revokeAllUserSessions' : 'revokeDeviceSessions',
        all
            ? {}
            : {'mode': mode, if (mode == 'single') 'sessionId': sessionId});
    if (result is! Map ||
        result['revoked'] != true ||
        (!all &&
            (result['mode'] != mode || result['currentSessionId'] != active))) {
      throw StateError('The server did not confirm revocation.');
    }
  }
}


