import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityNotification {
  const CommunityNotification({
    required this.id,
    required this.toUserId,
    required this.fromUserId,
    required this.type,
    required this.postId,
    required this.createdAt,
    required this.isRead,
    this.commentId,
    this.snippet,
  });

  final String id;
  final String toUserId;
  final String fromUserId;
  final String type;
  final String postId;
  final String? commentId;
  final String? snippet;
  final DateTime? createdAt;
  final bool isRead;

  factory CommunityNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CommunityNotification(
      id: doc.id,
      toUserId: (data['toUserId'] ?? '') as String,
      fromUserId: (data['fromUserId'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      postId: (data['postId'] ?? '') as String,
      commentId: data['commentId'] as String?,
      snippet: data['snippet'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: (data['isRead'] ?? false) as bool,
    );
  }
}
