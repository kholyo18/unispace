import 'package:cloud_firestore/cloud_firestore.dart';

String? signedSessionId(Map<String, dynamic>? claims) {
  final value = claims?['sid'];
  return value is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(value) ? value : null;
}

/// Activity writes deliberately cannot change security decisions or create sessions.
Map<String, dynamic> sessionHeartbeat() => {
  'lastSeenAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
};

/// Returns null for revoked records: only a new authenticated session may replace one.
Map<String, dynamic>? sessionInitialization({
  required Map<String, dynamic>? existing,
  required String sessionId,
  required String deviceId,
  required Map<String, dynamic> metadata,
}) {
  if (existing?['isRevoked'] == true) return null;
  if (signedSessionId({'sid': sessionId}) != null) {
    if (existing == null || existing['authSessionVersion'] != 1 ||
        existing['sessionId'] != sessionId || existing['isRevoked'] != false) return null;
    // The server owns identity and security; the client updates display/activity only.
    return {
      for (final key in ['model', 'platform', 'manufacturer', 'osVersion', 'appVersion', 'buildNumber', 'locale'])
        if (metadata.containsKey(key)) key: metadata[key],
      'deviceId': existing['deviceId'] ?? deviceId,
      'alias': existing['alias'] ?? metadata['model'],
      ...sessionHeartbeat(),
    };
  }
  return {
    ...metadata,
    'sessionId': sessionId,
    'deviceId': existing?['deviceId'] ?? deviceId,
    'alias': existing?['alias'] ?? metadata['model'],
    'isTrusted': existing?['isTrusted'] ?? false,
    'isRevoked': false,
    'revokedAt': null,
    'revokeReason': null,
    'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
    ...sessionHeartbeat(),
  };
}
