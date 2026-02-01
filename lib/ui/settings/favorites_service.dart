import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final String itemType;
  final DateTime? createdAt;

  factory FavoriteItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return FavoriteItem(
      id: snapshot.id,
      itemId: data['itemId'] as String? ?? snapshot.id,
      itemType: data['itemType'] as String? ?? 'generic',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  // TODO: Map favorite item IDs to real content entities once available.
  Stream<List<FavoriteItem>> streamFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FavoriteItem.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<void> addFavorite({
    required String itemId,
    String itemType = 'generic',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    final trimmed = itemId.trim();
    if (trimmed.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(trimmed)
        .set({
      'itemId': trimmed,
      'itemType': itemType.trim().isEmpty ? 'generic' : itemType.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(id)
        .delete();
  }
}
