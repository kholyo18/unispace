import 'package:cloud_firestore/cloud_firestore.dart';

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
