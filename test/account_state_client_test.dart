import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/ui/settings/account_state_client.dart';

void main() {
  late String? uid;
  late String? session;
  late List<Map<String, dynamic>> calls;
  late Map<String, dynamic> reply;
  late AccountStateClient client;
  final success = <String, dynamic>{'accountStatus': 'active', 'frozen': false, 'revision': 1, 'changed': true};
  setUp(() {
    uid = 'alice'; session = 'alice:1'; calls = []; reply = Map.of(success);
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (name, data) async { calls.add({'function': name, 'data': Map.of(data)}); return reply; });
  });
  for (final action in ['deactivate', 'reactivate', 'freeze', 'unfreeze']) {
    test('self action $action binds the expected caller without administrative fields', () async {
      await client.change('alice', action);
      expect(calls.single, {'function': 'setOwnAccountState', 'data': {'action': action, 'expectedUid': 'alice'}});
    });
  }
  test('unknown action is rejected before network access', () async {
    await expectLater(client.change('alice', 'suspend'), throwsArgumentError); expect(calls, isEmpty);
  });
  test('signed-out user cannot change account state', () async {
    uid = null; session = null; await expectLater(client.change('alice', 'freeze'), throwsStateError); expect(calls, isEmpty);
  });
  test('confirmation for another account cannot invoke state mutation', () async {
    uid = 'bob'; session = 'bob:2'; await expectLater(client.change('alice', 'freeze'), throwsStateError); expect(calls, isEmpty);
  });
  test('invalid account identifier is rejected without a request', () async {
    await expectLater(client.change('../alice', 'freeze'), throwsArgumentError); expect(calls, isEmpty);
  });
  test('in-flight state response cannot be applied to a replacement account', () async {
    final pending = Completer<Map<String, dynamic>>();
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session, invoke: (_, __) => pending.future);
    final result = client.change('alice', 'freeze'); uid = 'bob'; session = 'bob:2'; pending.complete(success);
    await expectLater(result, throwsStateError);
  });
  test('same account with a replacement session rejects old response', () async {
    final pending = Completer<Map<String, dynamic>>();
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session, invoke: (_, __) => pending.future);
    final result = client.change('alice', 'freeze'); session = 'alice:3'; pending.complete(success);
    await expectLater(result, throwsStateError);
  });
  test('invalid lifecycle response does not report success', () async {
    reply = {'accountStatus': 'active', 'frozen': 'false', 'revision': 0, 'changed': true};
    await expectLater(client.change('alice', 'freeze'), throwsStateError);
  });
  test('network failure is propagated without a direct-write fallback', () async {
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (_, __) async => throw StateError('offline'));
    await expectLater(client.change('alice', 'freeze'), throwsStateError);
  });
  test('deletion sends explicit confirmation to durable request endpoint only', () async {
    reply = {'status': 'pending', 'deletionWithinDays': 30}; await client.requestDeletion('alice');
    expect(calls.single, {'function': 'requestAccountDeletion', 'data': {'confirm': true, 'expectedUid': 'alice'}});
  });
  test('deletion confirmation cannot follow an account switch', () async {
    uid = 'bob'; session = 'bob:2'; await expectLater(client.requestDeletion('alice'), throwsStateError); expect(calls, isEmpty);
  });
  test('server-induced sign-out during deletion is accepted', () async {
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (_, __) async { uid = null; session = null; return {'status': 'pending', 'deletionWithinDays': 30}; });
    await client.requestDeletion('alice');
  });
  test('replacement login during deletion is never accepted as the old session', () async {
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (_, __) async { uid = 'bob'; session = 'bob:2'; return {'status': 'pending', 'deletionWithinDays': 30}; });
    await expectLater(client.requestDeletion('alice'), throwsStateError);
  });
  test('same UID new session during deletion is rejected', () async {
    client = AccountStateClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (_, __) async { session = 'alice:3'; return {'status': 'pending', 'deletionWithinDays': 30}; });
    await expectLater(client.requestDeletion('alice'), throwsStateError);
  });
  test('unconfirmed deletion response is an error', () async {
    reply = {'status': 'completed', 'deletionWithinDays': 30}; await expectLater(client.requestDeletion('alice'), throwsStateError);
  });
}
