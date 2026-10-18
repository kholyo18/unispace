import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_group_service.dart';
import 'package:UniSpace/l10n/chat_group_strings.dart';

void main() {
  const id = 'group_abcdefghijklmnopqrst';
  String? session;
  late List<Map<String, dynamic>> calls;
  late ChatGroupService service;
  setUp(() {
    session = 'alice:signed-session:123';
    calls = [];
    service = ChatGroupService.forTesting(
        sessionIdentity: () async => session,
        call: (name, data) async {
          calls.add({'function': name, ...data});
          return {
            'chatId': id,
            'status': data['action'] == 'reject' ? 'rejected' : 'open'
          };
        });
  });
  test('create trims name and sends the stable ID and intended invitations',
      () async {
    expect(
        await service
            .create(groupId: id, name: '  Friends  ', memberIds: ['bob']),
        id);
    expect(calls.first, {
      'function': 'createChatGroup',
      'name': 'Friends',
      'groupId': id,
      'memberIds': <String>[]
    });
    expect(calls.last['action'], 'invite');
    expect(calls.last['memberId'], 'bob');
  });
  test('retry uses the same group ID and payload', () async {
    await service.create(groupId: id, name: 'Friends', memberIds: ['bob']);
    await service.create(groupId: id, name: 'Friends', memberIds: ['bob']);
    expect(calls[0], calls[2]);
    expect(calls[1], calls[3]);
  });
  test('signed out never invokes a group mutation', () async {
    session = null;
    await expectLater(
        service.manage(chatId: id, action: 'leave'),
        throwsA(isA<FirebaseFunctionsException>()
            .having((e) => e.code, 'code', 'unauthenticated')));
    expect(calls, isEmpty);
  });
  test('same-account replacement session rejects late response', () async {
    final pending = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    service = ChatGroupService.forTesting(
        sessionIdentity: () async => session,
        call: (_, __) {
          started.complete();
          return pending.future;
        });
    final result = service.respond(chatId: id, accept: true);
    await started.future;
    session = 'alice:new-signed-session:456';
    pending.complete({'chatId': id, 'status': 'open'});
    await expectLater(
        result,
        throwsA(isA<FirebaseFunctionsException>()
            .having((e) => e.code, 'code', 'unauthenticated')));
  });
  test('mismatched group confirmation cannot open a different group', () async {
    service = ChatGroupService.forTesting(
        sessionIdentity: () async => session,
        call: (_, __) async => {'chatId': 'other', 'status': 'open'});
    await expectLater(
        service.create(groupId: id, name: 'Friends', memberIds: []),
        throwsA(isA<FirebaseFunctionsException>()
            .having((e) => e.code, 'code', 'data-loss')));
  });
  test('declining an invitation explicitly sends reject', () async {
    await service.respond(chatId: id, accept: false);
    expect(calls.single['action'], 'reject');
    expect(calls.single['chatId'], id);
  });
  test('rename and member role actions have narrow payloads', () async {
    await service.manage(chatId: id, action: 'rename', name: ' New ');
    expect(calls.single['action'], 'rename');
    expect(calls.single['name'], 'New');
    calls.clear();
    await service.manage(chatId: id, action: 'promote', memberId: 'bob');
    expect(calls.single['memberId'], 'bob');
    expect(calls.single['action'], 'promote');
  });
  test(
      'invalid name or duplicate membership reject before transport',
      () async {
    for (final args in [
      ('', <String>[]),
      ('x' * 81, <String>[]),
      ('Friends', ['bob', 'bob'])
    ]) {
      await expectLater(
          service.create(groupId: id, name: args.$1, memberIds: args.$2),
          throwsA(isA<FirebaseFunctionsException>()));
    }
    expect(calls, isEmpty);
  });
  test(
      'caller list mutation while authorization is pending cannot change submission',
      () async {
    final members = ['bob'];
    final identity = Completer<String?>();
    service = ChatGroupService.forTesting(
        sessionIdentity: () => identity.future,
        call: (_, data) async {
          calls.add(data);
          return {'chatId': id, 'status': 'open'};
        });
    final result =
        service.create(groupId: id, name: 'Friends', memberIds: members);
    members.add('mallory');
    identity.complete(session);
    await result;
    expect(calls.first['memberIds'], isEmpty);
    expect(calls.last['memberId'], 'bob');
  });

  test(
      'failed invitations stop progress; retry preserves group ID and never reports false success',
      () async {
    var fail = true;
    final progress = <int>[];
    service = ChatGroupService.forTesting(
        sessionIdentity: () async => session,
        call: (name, data) async {
          calls.add({'function': name, ...data});
          if (data['memberId'] == 'carol' && fail)
            throw FirebaseFunctionsException(code: 'resource-exhausted', message: 'Rate limited');
          return {'chatId': id, 'status': 'open'};
        });
    Future<String> submit() => service.create(
        groupId: id,
        name: 'Friends',
        memberIds: ['bob', 'carol'],
        onProgress: (sent, total) => progress.add(sent));
    await expectLater(submit(), throwsA(isA<FirebaseFunctionsException>()));
    expect(progress, [0, 1]);
    fail = false;
    expect(await submit(), id);
    expect(progress, [0, 1, 0, 1, 2]);
    expect(
        calls
            .where((c) => c['function'] == 'createChatGroup')
            .map((c) => c['groupId'])
            .toSet(),
        {id});
  });
  test(
      'account switch from progress callback cannot invite as replacement account',
      () async {
    await expectLater(
        service.create(
            groupId: id,
            name: 'Friends',
            memberIds: ['bob'],
            onProgress: (_, __) => session = 'other:sid:999'),
        throwsA(isA<FirebaseFunctionsException>()));
    expect(calls.length, 1);
  });
  test('session replacement between create capture and request sends nothing', () async {
    var reads = 0;
    service = ChatGroupService.forTesting(
      sessionIdentity: () async => ++reads == 1 ? 'alice:original:123' : 'alice:replacement:456',
      call: (_, data) async { calls.add(data); return {'chatId': id, 'status': 'open'}; });
    await expectLater(service.create(groupId: id, name: 'Friends', memberIds: ['bob']),
      throwsA(isA<FirebaseFunctionsException>().having((e) => e.code, 'code', 'unauthenticated')));
    expect(calls, isEmpty);
  });
  test('group invitation URI is parsed narrowly and only requests admission', () async {
    service = ChatGroupService.forTesting(sessionIdentity: () async => session, call: (name, data) async {
      calls.add({'function': name, ...data}); return {'chatId': id, 'status': 'pending'};
    });
    final token = 'a' * 64;
    expect(await service.requestJoin('unispace://group/join?groupId=$id&token=$token'), 'pending');
    expect(calls.single, {'function': 'requestGroupJoin', 'chatId': id, 'token': token});
    for (final uri in ['https://example.com/?groupId=$id&token=$token', 'unispace://group/join?groupId=$id&token=short', 'unispace://group/join?groupId=bad/id&token=$token']) {
      await expectLater(service.requestJoin(uri), throwsA(isA<FirebaseFunctionsException>()));
    }
    expect(calls.length, 1);
  });
  test('access and join review use dedicated server-owned APIs', () async {
    service = ChatGroupService.forTesting(sessionIdentity: () async => session, call: (name, data) async {
      calls.add({'function': name, ...data});
      if (name == 'listGroupJoinRequests') return {'chatId': id, 'requests': [{'uid':'bob', 'name':'Bob'}]};
      return {'chatId': id, 'status': 'approved', 'adminsOnly': true};
    });
    await service.access(chatId: id, action: 'setMessaging', adminsOnly: true);
    expect(calls.last, {'function':'manageGroupAccess','chatId':id,'action':'setMessaging','adminsOnly':true});
    expect((await service.joinRequests(id)).single['uid'], 'bob');
    await service.reviewJoin(chatId: id, requesterId: 'bob', approve: true);
    expect(calls.last, {'function':'reviewGroupJoinRequest','chatId':id,'requesterId':'bob','approve':true});
  });
  test('every group string supports Arabic French and English', () {
    for (final key in ChatGroupStrings.values.keys) {
      expect(ChatGroupStrings.text('en', key), key);
      expect(ChatGroupStrings.text('ar', key).trim(), isNotEmpty);
      expect(ChatGroupStrings.text('fr', key).trim(), isNotEmpty);
      expect(ChatGroupStrings.text('ar', key), isNot(key));
    }
  });
  test(
      'group form rejects another account immediately and after returning to original',
      () {
    String? uid = 'alice';
    final guard = ChatGroupOwnerGuard(currentUid: () => uid);
    expect(guard.isCurrent, isTrue);
    uid = 'bob';
    expect(guard.requireCurrent, throwsA(isA<FirebaseFunctionsException>()));
    guard.observe(uid);
    uid = 'alice';
    expect(guard.isCurrent, isFalse);
  });
  test('signed out form can never acquire a later signed in owner', () {
    String? uid;
    final guard = ChatGroupOwnerGuard(currentUid: () => uid);
    uid = 'alice';
    expect(guard.requireCurrent, throwsA(isA<FirebaseFunctionsException>()));
  });
}
