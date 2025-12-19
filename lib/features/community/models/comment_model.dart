import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.createdAt,
  });

  factory CommentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      id: doc.id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? '') as String,
      content: (data['content'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
