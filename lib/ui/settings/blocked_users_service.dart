import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSpace/main.dart' show blockAccount, unblockAccount;
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.identifier,
    required this.createdAt,
  });

  final String id;
  final String identifier;
  final DateTime? createdAt;

  factory BlockedUser.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return BlockedUser(
      id: snapshot.id,
      identifier: (data['targetName'] ?? data['identifier'] ?? snapshot.id).toString(),
      createdAt: ((data['blockedAt'] ?? data['createdAt']) as Timestamp?)?.toDate(),
    );
  }
}

class BlockedUsersService {
  BlockedUsersService._();

  static final BlockedUsersService instance = BlockedUsersService._();

  Stream<List<BlockedUser>> streamBlockedUsers() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }
    final snapshots = <String, List<BlockedUser>>{};
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    late StreamController<List<BlockedUser>> controller;
    controller = StreamController<List<BlockedUser>>(
      onListen: () {
        for (final collection in ['blocked_users', 'blocked_accounts']) {
          subscriptions.add(FirebaseFirestore.instance.collection('users')
              .doc(user.uid).collection(collection).snapshots().listen((snapshot) {
            if (controller.isClosed) return;
            if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
              controller.add(const []);
              return;
            }
            snapshots[collection] = snapshot.docs.map(BlockedUser.fromSnapshot).toList();
            final byId = <String, BlockedUser>{};
            for (final source in ['blocked_users', 'blocked_accounts']) {
              for (final item in snapshots[source] ?? <BlockedUser>[]) {
                byId[item.id] = item;
              }
            }
            final items = byId.values.toList()..sort((a, b) =>
                (b.createdAt?.millisecondsSinceEpoch ?? 0)
                    .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
            controller.add(items);
          }, onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          }));
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<void> blockUser(String identifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return;
    await blockAccount(targetId: trimmed, targetName: trimmed);
  }

  Future<void> unblockUser(String identifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    await unblockAccount(identifier.trim());
  }
}
