import 'chat_group_link.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef GroupCallable = Future<Map<String, dynamic>> Function(
    String name, Map<String, dynamic> data);

/// The server remains authoritative for membership, invitation consent and roles.
class ChatGroupService {
  ChatGroupService({FirebaseFunctions? functions, FirebaseAuth? auth})
      : _identity = (() async {
          final instance = auth ?? FirebaseAuth.instance;
          final user = instance.currentUser;
          if (user == null) return null;
          final token = await user.getIdTokenResult();
          if (instance.currentUser?.uid != user.uid) return null;
          final sid = token.claims?['sid'];
          final time = token.claims?['auth_time'];
          if (sid is! String ||
              !RegExp(r'^[a-f0-9]{64}$').hasMatch(sid) ||
              time is! num ||
              time <= 0) {
            return null;
          }
          return '${user.uid}:$sid:$time';
        }),
        _call = ((name, data) async => (await (functions ??
                    FirebaseFunctions.instanceFor(region: 'europe-west1'))
                .httpsCallable(name)
                .call<Map<String, dynamic>>(data))
            .data);

  ChatGroupService.forTesting(
      {required GroupCallable call,
      required Future<String?> Function() sessionIdentity})
      : _call = call,
        _identity = sessionIdentity;
  final GroupCallable _call;
  final Future<String?> Function() _identity;

  Future<Map<String, dynamic>> _request(
      String name, Map<String, dynamic> data, {String? expectedSession}) async {
    final session = await _identity();
    if (session == null || session.isEmpty ||
        (expectedSession != null && session != expectedSession)) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'Sign in again.');
    }
    final response = await _call(name, data);
    if (await _identity() != session) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'The session changed.');
    }
    return response;
  }

  String _confirmed(
      Map<String, dynamic> data, String chatId, String expectedStatus) {
    if (data['chatId'] != chatId || data['status'] != expectedStatus) {
      throw FirebaseFunctionsException(
          code: 'data-loss', message: 'Invalid group confirmation.');
    }
    return chatId;
  }

  Future<String> create(
      {required String groupId,
      required String name,
      required List<String> memberIds,
      void Function(int sent, int total)? onProgress}) async {
    if (name.trim().isEmpty ||
        name.trim().length > 80 ||
        memberIds.toSet().length != memberIds.length) {
      throw FirebaseFunctionsException(
          code: 'invalid-argument', message: 'Invalid group details.');
    }
    // Snapshot before awaiting: caller edits cannot change the submission.
    final invited = List<String>.unmodifiable(memberIds);
    final session = await _identity();
    if (session == null || session.isEmpty) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'Sign in again.');
    }
    Future<void> checkOwner() async {
      if (await _identity() != session) {
        throw FirebaseFunctionsException(
            code: 'unauthenticated', message: 'The session changed.');
      }
    }

    _confirmed(
        await _request('createChatGroup', {
          'groupId': groupId,
          'name': name.trim(),
          'memberIds': <String>[],
        }, expectedSession: session),
        groupId,
        'open');
    await checkOwner();
    onProgress?.call(0, invited.length);
    for (var index = 0; index < invited.length; index++) {
      await checkOwner();
      await _request('manageChatGroup', {
        'chatId': groupId, 'action': 'invite', 'memberId': invited[index],
      }, expectedSession: session);
      await checkOwner();
      onProgress?.call(index + 1, invited.length);
    }
    return groupId;
  }

  Future<void> manage(
      {required String chatId,
      required String action,
      String? memberId,
      String? name}) async {
    if (!const ['invite', 'rename', 'promote', 'demote', 'remove', 'leave']
        .contains(action)) {
      throw FirebaseFunctionsException(
          code: 'invalid-argument', message: 'Invalid group action.');
    }
    await _request('manageChatGroup', {
      'chatId': chatId,
      'action': action,
      if (memberId != null) 'memberId': memberId,
      if (name != null) 'name': name.trim()
    });
  }

  Future<Map<String, dynamic>> access({required String chatId, required String action, bool? adminsOnly}) =>
      _request('manageGroupAccess', {'chatId': chatId, 'action': action, if (adminsOnly != null) 'adminsOnly': adminsOnly});

  Future<List<Map<String, dynamic>>> joinRequests(String chatId) async {
    final result = await _request('listGroupJoinRequests', {'chatId': chatId});
    final rows = result['requests'];
    if (result['chatId'] != chatId || rows is! List) {
      throw FirebaseFunctionsException(code: 'data-loss', message: 'Invalid join requests.');
    }
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> reviewJoin({required String chatId, required String requesterId, required bool approve}) async {
    final result = await _request('reviewGroupJoinRequest', {'chatId': chatId, 'requesterId': requesterId, 'approve': approve});
    _confirmed(result, chatId, approve ? 'approved' : 'rejected');
  }

  Future<String> requestJoin(String link) async {
    final uri = Uri.tryParse(link.trim());
    final chatId = uri?.queryParameters['groupId'], token = uri?.queryParameters['token'];
    if (uri == null || !isChatGroupJoinLink(uri)) {
      throw FirebaseFunctionsException(code: 'invalid-argument', message: 'Invalid group link.');
    }
    final result = await _request('requestGroupJoin', {'chatId': chatId, 'token': token});
    if (result['chatId'] != chatId || !['pending', 'open'].contains(result['status'])) {
      throw FirebaseFunctionsException(code: 'data-loss', message: 'Invalid join confirmation.');
    }
    return result['status'] as String;
  }

  Future<String> respond(
          {required String chatId, required bool accept}) async =>
      _confirmed(
          await _request('respondGroupInvite',
              {'chatId': chatId, 'action': accept ? 'accept' : 'reject'}),
          chatId,
          accept ? 'open' : 'rejected');
}

/// A form must not submit selections captured under a different account.
class ChatGroupOwnerGuard {
  ChatGroupOwnerGuard({required this.currentUid}) : ownerUid = currentUid();
  final String? Function() currentUid;
  final String? ownerUid;
  bool _invalidated = false;
  bool get isCurrent =>
      !_invalidated && ownerUid != null && currentUid() == ownerUid;
  void observe(String? uid) {
    if (uid != ownerUid) _invalidated = true;
  }

  void requireCurrent() {
    if (!isCurrent) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'The group form owner changed.');
    }
  }
}
