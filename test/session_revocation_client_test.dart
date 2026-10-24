import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/session_revocation_client.dart';

void main() {
  test(
      'single and others use exact server payloads, preserving signed current device',
      () async {
    final calls = <(String, Map<String, Object?>)>[];
    final client = SessionRevocationClient(
        uid: 'a',
        currentUid: () => 'a',
        readSignedSession: () async => 'current',
        call: (name, data) async {
          calls.add((name, data));
          return {
            'revoked': true,
            'mode': data['mode'],
            'currentSessionId': 'current'
          };
        });
    await client.revoke(sessionId: 'target');
    await client.revoke(keepSessionId: 'current');
    expect(calls.map((entry) => entry.$1), ['revokeDeviceSessions', 'revokeDeviceSessions']);
    expect(calls[0].$2, {'mode': 'single', 'sessionId': 'target'});
    expect(calls[1].$2, {'mode': 'others'});
  });
  test('all invokes full revoke endpoint with no account input', () async {
    final client = SessionRevocationClient(
        uid: 'a',
        currentUid: () => 'a',
        readSignedSession: () async => 'current',
        call: (name, data) async {
          expect(name, 'revokeAllUserSessions');
          expect(data, isEmpty);
          return {'revoked': true};
        });
    await client.revoke(all: true);
  });
  test('changed account during token retrieval cannot issue revocation',
      () async {
    var uid = 'a';
    final client = SessionRevocationClient(
        uid: 'a',
        currentUid: () => uid,
        readSignedSession: () async {
          uid = 'b';
          return 'current';
        },
        call: (_, __) async => fail('must not call server'));
    await expectLater(client.revoke(sessionId: 'target'), throwsStateError);
  });
  test('stale current device and missing signed SID cannot issue others',
      () async {
    String? sid = 'new-device';
    final client = SessionRevocationClient(
        uid: 'a',
        currentUid: () => 'a',
        readSignedSession: () async => sid,
        call: (_, __) async => fail('must not call server'));
    await expectLater(
        client.revoke(keepSessionId: 'old-device'), throwsStateError);
    sid = null;
    await expectLater(
        client.revoke(keepSessionId: 'old-device'), throwsStateError);
  });
  test('missing confirmation and backend failures never report success',
      () async {
    var deny = false;
    final client = SessionRevocationClient(
        uid: 'a',
        currentUid: () => 'a',
        readSignedSession: () async => 'current',
        call: (_, __) async {
          if (deny) throw StateError('permission-denied');
          return {
            'revoked': true,
            'mode': 'others',
            'currentSessionId': 'wrong'
          };
        });
    await expectLater(
        client.revoke(keepSessionId: 'current'), throwsStateError);
    deny = true;
    await expectLater(
        client.revoke(keepSessionId: 'current'), throwsStateError);
  });
}

