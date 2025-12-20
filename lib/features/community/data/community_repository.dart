import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';
import '../models/community_notification.dart';
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

  Future<String?> getUserUniversityId() async {
    final user = _user;
    if (user == null) return null;
    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data()?['universityId'] as String?;
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
      final universityId = await getUserUniversityId();
      if (universityId == null || universityId.isEmpty) {
        yield [];
        return;
      }
      ref = ref.where('universityId', isEqualTo: universityId);
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

  Stream<List<PostModel>> streamCommunityPosts({
    required CommunityTab tab,
    String query = '',
    String? tagFilter,
    bool showUnanswered = false,
    bool showTrending = false,
    bool showSavedOnly = false,
    SavedPostCategory? savedCategoryFilter,
  }) {
    return streamPosts(
      tab: tab,
      query: query,
      tagFilter: tagFilter,
      showUnanswered: showUnanswered,
      showTrending: showTrending,
      showSavedOnly: showSavedOnly,
      savedCategoryFilter: savedCategoryFilter,
    );
  }

  Stream<PostModel?> streamPost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromDoc(doc);
    });
  }

  Future<PostModel?> fetchPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromDoc(doc);
  }

  Future<void> createPost({
    required String content,
    required List<String> tags,
    required bool isQuestion,
    String? university,
    String? universityId,
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

    final resolvedUniversityId =
        universityId ?? await getUserUniversityId();
    await docRef.set({
      'authorId': user.uid,
      'authorName': authorName,
      'authorEmail': user.email ?? '',
      'university': university,
      'universityId': resolvedUniversityId,
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

    final result = await _firestore.runTransaction((transaction) async {
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
        return {
          'liked': false,
          'postAuthorId': postAuthorId,
        };
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
      return {
        'liked': true,
        'postAuthorId': postAuthorId,
      };
    });
    final liked = result['liked'] as bool? ?? false;
    final postAuthorId = result['postAuthorId'] as String?;
    if (liked && postAuthorId != null && postAuthorId != user.uid) {
      await createNotificationLike(
        toUserId: postAuthorId,
        fromUserId: user.uid,
        postId: postId,
      );
    }
    return liked;
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

    final commentId = commentRef.id;
    final postAuthorId = await _firestore.runTransaction((transaction) async {
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
      return postAuthorId;
    });
    if (postAuthorId != null && postAuthorId != user.uid) {
      await createNotificationComment(
        toUserId: postAuthorId,
        fromUserId: user.uid,
        postId: postId,
        commentId: commentId,
        snippet: _snippet(content),
      );
    }
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
          ? await getUserUniversityId()
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
        universityId: university,
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
    String? universityId,
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
        universityId != null &&
        universityId.isNotEmpty) {
      filtered =
          filtered.where((post) => post.universityId == universityId).toList();
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

  Future<void> createNotificationLike({
    required String toUserId,
    required String fromUserId,
    required String postId,
  }) async {
    if (toUserId == fromUserId) return;
    final ref = _firestore.collection('community_notifications').doc();
    await ref.set({
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'type': 'like',
      'postId': postId,
      'commentId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> createNotificationComment({
    required String toUserId,
    required String fromUserId,
    required String postId,
    required String commentId,
    String? snippet,
  }) async {
    if (toUserId == fromUserId) return;
    final ref = _firestore.collection('community_notifications').doc();
    await ref.set({
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'type': 'comment',
      'postId': postId,
      'commentId': commentId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'snippet': snippet,
    });
  }

  Future<void> markNotificationRead(String notificationId) {
    return _firestore
        .collection('community_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllRead(String toUserId) async {
    final snapshot = await _firestore
        .collection('community_notifications')
        .where('toUserId', isEqualTo: toUserId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<List<CommunityNotification>> streamNotifications(String toUserId) {
    if (toUserId.isEmpty) {
      return Stream<List<CommunityNotification>>.value(const []);
    }
    return _firestore
        .collection('community_notifications')
        .where('toUserId', isEqualTo: toUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CommunityNotification.fromDoc).toList());
  }

  Stream<int> unreadCountStream(String toUserId) {
    if (toUserId.isEmpty) {
      return Stream<int>.value(0);
    }
    return _firestore
        .collection('community_notifications')
        .where('toUserId', isEqualTo: toUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> hidePost(String userId, String postId) async {
    final ref = _firestore
        .collection('community_user_hidden_posts')
        .doc('${userId}_$postId');
    await ref.set({
      'userId': userId,
      'postId': postId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unhidePost(String userId, String postId) {
    return _firestore
        .collection('community_user_hidden_posts')
        .doc('${userId}_$postId')
        .delete();
  }

  Stream<Set<String>> streamHiddenPostIds(String userId) {
    if (userId.isEmpty) {
      return Stream<Set<String>>.value(<String>{});
    }
    return _firestore
        .collection('community_user_hidden_posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['postId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    final ref = _firestore
        .collection('community_user_blocks')
        .doc('${blockerId}_$blockedId');
    await ref.set({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String blockerId, String blockedId) {
    return _firestore
        .collection('community_user_blocks')
        .doc('${blockerId}_$blockedId')
        .delete();
  }

  Stream<Set<String>> streamBlockedUserIds(String blockerId) {
    if (blockerId.isEmpty) {
      return Stream<Set<String>>.value(<String>{});
    }
    return _firestore
        .collection('community_user_blocks')
        .where('blockerId', isEqualTo: blockerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['blockedId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  Future<void> reportPost({
    required String reporterId,
    required String postId,
    required String postOwnerId,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection('community_reports').add({
      'reporterId': reporterId,
      'postId': postId,
      'postOwnerId': postOwnerId,
      'reason': reason,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _snippet(String content) {
    final trimmed = content.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 77)}...';
  }
}
