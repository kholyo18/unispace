import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';

/// Suggested baseline Firestore rules for Community:
/// - Allow read: if request.auth != null
/// - Allow write on posts/comments/likes/savedPosts only for authenticated users.
/// - For likes/savedPosts, allow write only to the user's own document id.
/// (Configure in Firebase console; rules are not modified by this app.)

enum CommunityFilter { all, myUniversity, questions, trending, saved }

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get _user => _auth.currentUser;

  Future<String?> getUserUniversity() async {
    final user = _user;
    if (user == null) return null;
    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data()?['university'] as String?;
  }

  Stream<List<PostModel>> streamPosts({
    required CommunityFilter filter,
    String query = '',
  }) async* {
    if (filter == CommunityFilter.saved) {
      yield* streamSavedPosts(query: query);
      return;
    }

    Query<Map<String, dynamic>> ref = _firestore.collection('posts');

    if (filter == CommunityFilter.questions) {
      ref = ref.where('isQuestion', isEqualTo: true);
    }

    if (filter == CommunityFilter.myUniversity) {
      final university = await getUserUniversity();
      if (university == null || university.isEmpty) {
        yield [];
        return;
      }
      ref = ref.where('university', isEqualTo: university);
    }

    if (filter == CommunityFilter.trending) {
      ref = ref
          .orderBy('likesCount', descending: true)
          .orderBy('commentsCount', descending: true)
          .orderBy('createdAt', descending: true);
    } else {
      ref = ref.orderBy('createdAt', descending: true);
    }

    yield* ref.snapshots().map((snapshot) {
      final posts = snapshot.docs.map(PostModel.fromDoc).toList();
      return _applySearch(posts, query);
    });
  }

  Stream<PostModel?> streamPost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromDoc(doc);
    });
  }

  Future<void> createPost({
    required String content,
    required List<String> tags,
    required bool isQuestion,
    String? university,
  }) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final docRef = _firestore.collection('posts').doc();
    final authorName =
        user.displayName ?? user.email?.split('@').first ?? 'Student';

    await docRef.set({
      'authorId': user.uid,
      'authorName': authorName,
      'authorEmail': user.email ?? '',
      'university': university,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
      'tags': tags,
      'isQuestion': isQuestion,
    });
  }

  Future<bool> toggleLike(String postId) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
        return false;
      }
      transaction.set(likeRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'likesCount': FieldValue.increment(1),
      });
      return true;
    });
  }

  Stream<bool> streamIsPostLiked(String postId) {
    final user = _user;
    if (user == null) {
      return const Stream<bool>.value(false);
    }
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<CommentModel>> streamComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CommentModel.fromDoc).toList());
  }

  Future<void> addComment(String postId, String content) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final authorName =
        user.displayName ?? user.email?.split('@').first ?? 'Student';

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'authorId': user.uid,
        'authorName': authorName,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
  }

  Future<bool> toggleSave(String postId) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final savedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId);

    final snapshot = await savedRef.get();
    if (snapshot.exists) {
      await savedRef.delete();
      return false;
    }

    await savedRef.set({
      'postId': postId,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Stream<bool> streamIsPostSaved(String postId) {
    final user = _user;
    if (user == null) {
      return const Stream<bool>.value(false);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<Set<String>> streamSavedPostIds() {
    final user = _user;
    if (user == null) {
      return const Stream<Set<String>>.value(<String>{});
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<List<PostModel>> streamSavedPosts({String query = ''}) {
    return streamSavedPostIds().asyncMap((ids) async {
      if (ids.isEmpty) return [];
      final idList = ids.toList();
      final chunks = <List<String>>[];
      for (var i = 0; i < idList.length; i += 10) {
        chunks.add(idList.sublist(
            i, i + 10 > idList.length ? idList.length : i + 10));
      }

      final posts = <PostModel>[];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        posts.addAll(snapshot.docs.map(PostModel.fromDoc));
      }

      posts.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return _applySearch(posts, query);
    });
  }

  List<PostModel> _applySearch(List<PostModel> posts, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return posts;

    return posts.where((post) {
      return post.content.toLowerCase().contains(trimmed) ||
          post.authorName.toLowerCase().contains(trimmed) ||
          post.tags.any((tag) => tag.toLowerCase().contains(trimmed));
    }).toList();
  }
}
