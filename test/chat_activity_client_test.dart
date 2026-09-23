import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_activity_client.dart';

void main() {
  const uid = 'viewer.with.dot';
  late String? currentUid;
  late String? session;
  late Object timestamp;
  late Object deletion;
  late List<Map<String, dynamic>> writes;
  late ChatActivityClient client;
  late Future<void> Function(Map<String, dynamic>) writer;
  setUp(() {
    currentUid = uid;
    session = 'session-1';
    timestamp = Object();
    deletion = Object();
    writes = [];
    writer = (data) async { writes.add(data); };
    client = ChatActivityClient(
      expectedUid: uid,
      currentUid: () => currentUid,
      sessionKey: () => session,
      merge: (data) => writer(data),
      serverTimestamp: () => timestamp,
      deleteField: () => deletion,
    );
  });
  tearDown(() => client.dispose());

  test('read payload is nested and contains only caller and unread reset', () async {
    expect(await client.markRead(), isTrue);
    expect(writes.single, {
      'lastReadAt': {uid: same(timestamp)},
      'unread': {uid: 0},
    });
    expect(writes.single.keys.any((key) => key.contains('.')), isFalse);
  });
  test('typing start uses server timestamp under the exact UID segment', () async {
    expect(await client.setTyping(true), isTrue);
    expect(writes.single, {'typing': {uid: same(timestamp)}});
  });
  test('typing stop deletes only caller leaf, never the parent', () async {
    expect(await client.setTyping(false), isTrue);
    expect(writes.single, {'typing': {uid: same(deletion)}});
  });
  test('read and typing writes never rewrite peer or message metadata', () async {
    await client.markRead(); await client.setTyping(true); await client.setTyping(false);
    for (final data in writes) {
      expect(data.keys.every((key) => ['lastReadAt', 'unread', 'typing'].contains(key)), isTrue);
      for (final value in data.values) { expect((value as Map).keys, [uid]); }
    }
  });
  test('each read acknowledgement obtains a fresh timestamp sentinel', () async {
    await client.markRead(); final first = timestamp;
    timestamp = Object(); await client.markRead();
    expect((writes.first['lastReadAt'] as Map)[uid], same(first));
    expect((writes.last['lastReadAt'] as Map)[uid], same(timestamp));
  });
  test('wrong account suppresses all writes', () async {
    currentUid = 'other';
    expect(await client.markRead(), isFalse); expect(await client.setTyping(true), isFalse);
    expect(writes, isEmpty);
  });
  test('logout suppresses a queued stop-typing operation', () async {
    currentUid = null; session = null;
    expect(await client.setTyping(false), isFalse); expect(writes, isEmpty);
  });
  test('a new login with the same UID invalidates the old session scope', () async {
    session = 'session-2';
    expect(await client.markRead(), isFalse); expect(writes, isEmpty);
  });
  test('missing initial session stays invalid rather than adopting later login', () async {
    client.dispose(); session = null;
    client = ChatActivityClient(expectedUid: uid,currentUid: () => currentUid,
      sessionKey: () => session,merge: writer,serverTimestamp: () => timestamp,deleteField: () => deletion);
    session = 'session-2';
    expect(await client.markRead(), isFalse); expect(writes, isEmpty);
  });
  test('empty initial UID cannot publish activity', () async {
    client.dispose(); currentUid = '';
    client = ChatActivityClient(expectedUid: '', currentUid: () => currentUid,
      sessionKey: () => session, merge: writer, serverTimestamp: () => timestamp, deleteField: () => deletion);
    expect(await client.setTyping(true), isFalse); expect(writes, isEmpty);
  });
  test('disposing closes pending and future UI work', () async {
    client.dispose(); client.dispose();
    expect(client.isCurrent, isFalse); expect(await client.markRead(), isFalse);
    expect(await client.setTyping(false), isFalse); expect(writes, isEmpty);
  });
  test('network errors propagate instead of claiming successful acknowledgement', () async {
    writer = (_) => Future<void>.error(StateError('fixture failure'));
    await expectLater(client.markRead(), throwsStateError);
  });
  test('account change in flight prevents stale success, not recall of sent data', () async {
    final done = Completer<void>();
    writer = (data) { writes.add(data); return done.future; };
    final pending = client.markRead();
    currentUid = 'other'; session = 'session-2'; done.complete();
    expect(await pending, isFalse); expect(writes, hasLength(1));
    expect((writes.single['lastReadAt'] as Map).keys, [uid]);
  });
  test('dispose in flight prevents stale success', () async {
    final done = Completer<void>(); writer = (_) => done.future;
    final pending = client.setTyping(true); client.dispose(); done.complete();
    expect(await pending, isFalse);
  });
  test('concurrent caller operations keep separate nested payloads', () async {
    await Future.wait([client.markRead(),client.setTyping(true)]);
    expect(writes, hasLength(2)); expect(writes[0].containsKey('typing'), isFalse);
    expect(writes[1].containsKey('lastReadAt'), isFalse);
  });
  final now = DateTime.utc(2026, 9, 23, 12);
  test('fresh typing deadline lasts four seconds', () {
    expect(ChatActivityClient.typingRemaining(now, now), const Duration(seconds: 4));
  });
  test('typing deadline subtracts actual elapsed time', () {
    expect(ChatActivityClient.typingRemaining(now.subtract(const Duration(milliseconds: 1250)), now),
      const Duration(milliseconds: 2750));
  });
  test('expired or exactly four-second-old typing is off', () {
    for (final seconds in [4, 5, 100]) {
      expect(ChatActivityClient.typingRemaining(now.subtract(Duration(seconds: seconds)), now), Duration.zero);
    }
  });
  test('absent or future typing must not leave the indicator on', () {
    expect(ChatActivityClient.typingRemaining(null, now), Duration.zero);
    expect(ChatActivityClient.typingRemaining(now.add(const Duration(seconds: 1)), now), Duration.zero);
  });
}
