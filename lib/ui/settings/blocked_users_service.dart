import 'package:cloud_firestore/cloud_firestore.dart';
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
      identifier: data['identifier'] as String? ?? snapshot.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('blocked_users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BlockedUser.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<void> blockUser(String identifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('blocked_users')
        .doc(trimmed)
        .set({
      'identifier': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String identifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('blocked_users')
        .doc(identifier)
        .delete();
  }
}
