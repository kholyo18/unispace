import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../utils/community_score_utils.dart';
import '../utils/saved_post_category.dart';
import '../utils/tag_utils.dart';

/// Suggested baseline Firestore rules for Community:
/// - Allow read: if request.auth != null
/// - Allow write on posts/comments/likes/savedPosts only for authenticated users.
/// - For likes/savedPosts, allow write only to the user's own document id.
/// (Configure in Firebase console; rules are not modified by this app.)

enum CommunityTab { all, myUniversity, questions }

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
    required CommunityTab tab,
    String query = '',
    String? tagFilter,
    bool showUnanswered = false,
    bool showTrending = false,
    bool showSavedOnly = false,
    SavedPostCategory? savedCategoryFilter,
  }) async* {
    if (showSavedOnly) {
      yield* streamSavedPosts(
        query: query,
        tagFilter: tagFilter,
        tab: tab,
        showUnanswered: showUnanswered,
        showTrending: showTrending,
        savedCategoryFilter: savedCategoryFilter,
      );
      return;
    }

    Query<Map<String, dynamic>> ref = _firestore.collection('posts');

    if (tab == CommunityTab.questions || showUnanswered) {
      ref = ref.where('isQuestion', isEqualTo: true);
    }

    if (showUnanswered) {
      ref = ref.where('commentsCount', isEqualTo: 0);
    }

    if (tab == CommunityTab.myUniversity) {
      final university = await getUserUniversity();
      if (university == null || university.isEmpty) {
        yield [];
        return;
      }
      ref = ref.where('university', isEqualTo: university);
    }

    if (showTrending) {
      ref = ref
          .orderBy('likesCount', descending: true)
          .orderBy('commentsCount', descending: true)
          .orderBy('createdAt', descending: true);
    } else {
      ref = ref.orderBy('createdAt', descending: true);
    }

    yield* ref.snapshots().map((snapshot) {
      final posts = snapshot.docs.map(PostModel.fromDoc).toList();
      return _applySearch(
        posts,
        query,
        tagFilter,
        tab: tab,
        showUnanswered: showUnanswered,
        showTrending: showTrending,
      );
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

    final normalizedTags = <String>{};
    for (final tag in tags) {
      final normalized = normalizeTag(tag);
      if (normalized != null) {
        normalizedTags.add(normalized);
      }
    }

    await docRef.set({
      'authorId': user.uid,
      'authorName': authorName,
      'authorEmail': user.email ?? '',
      'university': university,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
      'tags': normalizedTags.toList(),
      'isQuestion': isQuestion,
      'bestAnswerCommentId': null,
      'bestAnswerAuthorId': null,
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
      final postSnapshot = await transaction.get(postRef);
      final postData = postSnapshot.data();
      final postAuthorId = postData?['authorId'] as String?;
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
        if (postAuthorId != null && postAuthorId.isNotEmpty) {
          transaction.set(
            _firestore.collection('users').doc(postAuthorId),
            {'communityScore': FieldValue.increment(-1)},
            SetOptions(merge: true),
          );
        }
        return false;
      }
      transaction.set(likeRef, {
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'likesCount': FieldValue.increment(1),
      });
      if (postAuthorId != null && postAuthorId.isNotEmpty) {
        transaction.set(
          _firestore.collection('users').doc(postAuthorId),
          {'communityScore': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      return true;
    });
  }

  Stream<bool> streamIsPostLiked(String postId) {
    final user = _user;
    if (user == null) {
      return Stream<bool>.value(false);
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
      final postSnapshot = await transaction.get(postRef);
      final postData = postSnapshot.data();
      final postAuthorId = postData?['authorId'] as String?;
      transaction.set(commentRef, {
        'authorId': user.uid,
        'authorName': authorName,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
      if (postAuthorId != null && postAuthorId.isNotEmpty) {
        transaction.set(
          _firestore.collection('users').doc(postAuthorId),
          {'communityScore': FieldValue.increment(2)},
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<bool> toggleSave(
    String postId, {
    SavedPostCategory defaultCategory = SavedPostCategory.later,
  }) async {
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
      'category': savedPostCategoryValue(defaultCategory),
    });
    return true;
  }

  Future<void> updateSavedCategory(
    String postId,
    SavedPostCategory category,
  ) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final savedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId);

    await savedRef.update({
      'category': savedPostCategoryValue(category),
    });
  }

  Stream<bool> streamIsPostSaved(String postId) {
    final user = _user;
    if (user == null) {
      return Stream<bool>.value(false);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<Map<String, SavedPostCategory>> streamSavedPostCategories() {
    final user = _user;
    if (user == null) {
      return Stream<Map<String, SavedPostCategory>>.value({});
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .snapshots()
        .map((snapshot) => {
              for (final doc in snapshot.docs)
                doc.id: savedPostCategoryFromValue(
                  doc.data()['category'] as String?,
                ),
            });
  }

  Stream<SavedPostCategory?> streamSavedCategory(String postId) {
    final user = _user;
    if (user == null) {
      return Stream<SavedPostCategory?>.value(null);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return savedPostCategoryFromValue(snapshot.data()?['category'] as String?);
    });
  }

  Stream<List<PostModel>> streamSavedPosts({
    String query = '',
    String? tagFilter,
    required CommunityTab tab,
    bool showUnanswered = false,
    bool showTrending = false,
    SavedPostCategory? savedCategoryFilter,
  }) {
    return streamSavedPostCategories().asyncMap((savedPosts) async {
      if (savedPosts.isEmpty) return [];
      final idList = savedPosts.keys.toList();
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

      final filteredSavedPosts = savedCategoryFilter == null
          ? posts
          : posts
              .where((post) =>
                  savedPosts[post.id] == savedCategoryFilter)
              .toList();

      final university = tab == CommunityTab.myUniversity
          ? await getUserUniversity()
          : null;
      if (tab == CommunityTab.myUniversity &&
          (university == null || university.isEmpty)) {
        return [];
      }
      return _applySearch(
        filteredSavedPosts,
        query,
        tagFilter,
        tab: tab,
        showUnanswered: showUnanswered,
        showTrending: showTrending,
        university: university,
      );
    });
  }

  List<PostModel> _applySearch(
    List<PostModel> posts,
    String query,
    String? tagFilter,
    {
    required CommunityTab tab,
    bool showUnanswered = false,
    bool showTrending = false,
    String? university,
  }) {
    var filtered = posts;
    if (tab == CommunityTab.questions) {
      filtered = filtered.where((post) => post.isQuestion).toList();
    }
    if (showUnanswered) {
      filtered = filtered
          .where((post) => post.isQuestion && post.commentsCount == 0)
          .toList();
    }
    if (tab == CommunityTab.myUniversity &&
        university != null &&
        university.isNotEmpty) {
      filtered =
          filtered.where((post) => post.university == university).toList();
    }

    final trimmed = query.trim().toLowerCase();
    final normalizedTag = normalizeTag(tagFilter ?? '');
    if (normalizedTag != null) {
      filtered = filtered
          .where((post) => post.tags.any((tag) {
                final normalized = normalizeTag(tag);
                return normalized != null && normalized == normalizedTag;
              }))
          .toList();
    }

    if (!showTrending) {
      filtered.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    if (trimmed.isEmpty) {
      if (showTrending) {
        final now = DateTime.now();
        filtered.sort((a, b) {
          final aScore = trendingScore(a, now);
          final bScore = trendingScore(b, now);
          final scoreCompare = bScore.compareTo(aScore);
          if (scoreCompare != 0) return scoreCompare;
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      }
      return filtered;
    }

    filtered = filtered.where((post) {
      return post.content.toLowerCase().contains(trimmed) ||
          post.authorName.toLowerCase().contains(trimmed) ||
          post.tags.any((tag) => tag.toLowerCase().contains(trimmed));
    }).toList();

    if (showTrending) {
      final now = DateTime.now();
      filtered.sort((a, b) {
        final aScore = trendingScore(a, now);
        final bScore = trendingScore(b, now);
        final scoreCompare = bScore.compareTo(aScore);
        if (scoreCompare != 0) return scoreCompare;
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    return filtered;
  }

  Stream<int> streamCommunityScore(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) =>
            (snapshot.data()?['communityScore'] ?? 0) as int);
  }

  Future<void> setBestAnswer({
    required String postId,
    required String? commentId,
    required String? commentAuthorId,
  }) async {
    final user = _user;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      final postData = postSnapshot.data();
      final currentBestAuthorId =
          postData?['bestAnswerAuthorId'] as String?;

      if (currentBestAuthorId != null && currentBestAuthorId.isNotEmpty) {
        transaction.set(
          _firestore.collection('users').doc(currentBestAuthorId),
          {'communityScore': FieldValue.increment(-10)},
          SetOptions(merge: true),
        );
      }

      if (commentId == null || commentId.isEmpty) {
        transaction.update(postRef, {
          'bestAnswerCommentId': null,
          'bestAnswerAuthorId': null,
        });
        return;
      }

      transaction.update(postRef, {
        'bestAnswerCommentId': commentId,
        'bestAnswerAuthorId': commentAuthorId,
      });

      if (commentAuthorId != null && commentAuthorId.isNotEmpty) {
        transaction.set(
          _firestore.collection('users').doc(commentAuthorId),
          {'communityScore': FieldValue.increment(10)},
          SetOptions(merge: true),
        );
      }
    });
  }
}
