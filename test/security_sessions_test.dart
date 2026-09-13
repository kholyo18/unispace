import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/session_record.dart';
import 'package:UniSpace/ui/settings/session_service.dart';

void main() {
  group('Session lifecycle invariants', () {
    final metadata = <String, dynamic>{'model': 'Test device', 'platform': 'android'};

    test('activity cannot change revocation, trust, or identity', () {
      final record = <String, dynamic>{
        'sessionId': 'session-a', 'isRevoked': true,
        'revokedAt': Timestamp.fromMillisecondsSinceEpoch(1000),
        'revokeReason': 'manual', 'isTrusted': true, 'alias': 'My phone',
      };
      final updated = {...record, ...sessionHeartbeat()};
      for (final key in record.keys) {
        expect(updated[key], record[key], reason: '$key must survive a heartbeat');
      }
      expect(updated['lastSeenAt'], isNotNull);
    });

    test('reopening a revoked session cannot reactivate it', () {
      final record = sessionInitialization(
        existing: {'isRevoked': true}, sessionId: 'old-session',
        deviceId: 'installation', metadata: metadata,
      );
      expect(record, isNull);
    });

    test('refreshing an existing session preserves user choices and login time', () {
      final createdAt = Timestamp.fromMillisecondsSinceEpoch(1000);
      final record = sessionInitialization(
        existing: {'isRevoked': false, 'alias': 'My tablet', 'isTrusted': true,
          'createdAt': createdAt, 'deviceId': 'original-installation'},
        sessionId: 'session-a', deviceId: 'new-installation', metadata: metadata,
      )!;
      expect(record['alias'], 'My tablet');
      expect(record['isTrusted'], isTrue);
      expect(record['createdAt'], createdAt);
      expect(record['deviceId'], 'original-installation');
      expect(record['model'], 'Test device');
    });

    test('a fresh session starts untrusted and active with an installation id', () {
      final record = sessionInitialization(existing: null, sessionId: 'session-new',
        deviceId: 'installation-a', metadata: metadata)!;
      expect(record['sessionId'], 'session-new');
      expect(record['deviceId'], 'installation-a');
      expect(record['isTrusted'], isFalse);
      expect(record['isRevoked'], isFalse);
      expect(record['createdAt'], isNotNull);
    });
  });

  group('Session display compatibility', () {
    test('legacy records retain device name, last activity and trust', () {
      final seen = Timestamp.fromMillisecondsSinceEpoch(1000);
      final session = SessionModel.fromMap('legacy', {
        'deviceName': 'Old phone', 'lastActiveAt': seen, 'trusted': true,
      });
      expect(session.id, 'legacy');
      expect(session.alias, 'Old phone');
      expect(session.lastSeenAt, seen);
      expect(session.isTrusted, isTrue);
    });

    test('canonical trust overrides a legacy trusted flag', () {
      final session = SessionModel.fromMap('a', {'isTrusted': false, 'trusted': true});
      expect(session.isTrusted, isFalse);
    });

    test('a revoked session is never displayed as online', () {
      final session = SessionModel.fromMap('a', {
        'isRevoked': true, 'lastSeenAt': Timestamp.now(),
      });
      expect(session.isOnline, isFalse);
    });

    test('a stale or future activity time is not online', () {
      for (final offset in [const Duration(days: -1), const Duration(days: 1)]) {
        final session = SessionModel.fromMap('a', {
          'lastSeenAt': Timestamp.fromDate(DateTime.now().add(offset)),
        });
        expect(session.isOnline, isFalse);
      }
    });

    test('recent activity on an active session is online', () {
      final session = SessionModel.fromMap('a', {
        'lastSeenAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 10))),
      });
      expect(session.isOnline, isTrue);
    });
  });
}
