import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String? authorMajor;
  final String? authorYear;
  final String? university;
  final String? universityId;
  final String content;
  final DateTime? createdAt;
  final int likesCount;
  final int commentsCount;
  final List<String> tags;
  final bool isQuestion;
  final String? bestAnswerCommentId;
  final String? bestAnswerAuthorId;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.tags,
    required this.isQuestion,
    this.bestAnswerCommentId,
    this.bestAnswerAuthorId,
    this.authorMajor,
    this.authorYear,
    this.university,
    this.universityId,
    this.createdAt,
  });

  factory PostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostModel(
      id: doc.id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? '') as String,
      authorEmail: (data['authorEmail'] ?? '') as String,
      authorMajor: data['authorMajor'] as String?,
      authorYear: data['authorYear'] as String?,
      university: data['university'] as String?,
      universityId: data['universityId'] as String?,
      content: (data['content'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      likesCount: (data['likesCount'] ?? 0) as int,
      commentsCount: (data['commentsCount'] ?? 0) as int,
      tags: List<String>.from(data['tags'] ?? const []),
      isQuestion: (data['isQuestion'] ?? false) as bool,
      bestAnswerCommentId: data['bestAnswerCommentId'] as String?,
      bestAnswerAuthorId: data['bestAnswerAuthorId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'authorMajor': authorMajor,
      'authorYear': authorYear,
      'university': university,
      'universityId': universityId,
      'content': content,
      'createdAt': createdAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'tags': tags,
      'isQuestion': isQuestion,
      'bestAnswerCommentId': bestAnswerCommentId,
      'bestAnswerAuthorId': bestAnswerAuthorId,
    };
  }
}
