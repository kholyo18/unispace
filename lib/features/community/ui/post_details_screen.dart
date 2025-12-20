import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../../generated/l10n.dart';
import '../../../ui/widgets/empty_state.dart';
import '../data/community_repository.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'widgets/comment_tile.dart';
import 'widgets/post_card.dart';

enum CommentSort { newest, mostHelpful }

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    super.key,
    required this.repository,
    required this.post,
  });

  final CommunityRepository repository;
  final PostModel post;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;
  CommentSort _commentSort = CommentSort.newest;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.repository.addComment(widget.post.id, text);
      _commentController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  List<CommentModel> _sortedComments(
    List<CommentModel> comments,
    String? bestAnswerId,
  ) {
    final sorted = [...comments];
    CommentModel? bestAnswer;
    if (bestAnswerId != null && bestAnswerId.isNotEmpty) {
      for (final comment in sorted) {
        if (comment.id == bestAnswerId) {
          bestAnswer = comment;
          break;
        }
      }
      sorted.removeWhere((comment) => comment.id == bestAnswerId);
    }
    if (_commentSort == CommentSort.newest) {
      sorted.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (bestAnswer != null) {
        return [bestAnswer, ...sorted];
      }
      return sorted;
    }

    final hasLikes = comments.any((comment) => comment.likesCount > 0);
    if (!hasLikes) {
      sorted.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      if (bestAnswer != null) {
        return [bestAnswer, ...sorted];
      }
      return sorted;
    }

    sorted.sort((a, b) {
      final likeCompare = b.likesCount.compareTo(a.likesCount);
      if (likeCompare != 0) return likeCompare;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    if (bestAnswer != null) {
      return [bestAnswer, ...sorted];
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final blockStream = user == null
        ? Stream<Set<String>>.value(<String>{})
        : widget.repository.streamBlockedUserIds(user.uid);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).postDetails),
      ),
      body: StreamBuilder<PostModel?>(
        stream: widget.repository.streamPost(widget.post.id),
        builder: (context, snapshot) {
          final post = snapshot.data ?? widget.post;
          return StreamBuilder<Set<String>>(
            stream: blockStream,
            builder: (context, blockedSnapshot) {
              final blockedIds = blockedSnapshot.data ?? <String>{};
              if (blockedIds.contains(post.authorId)) {
                return EmptyState(
                  icon: Icons.block,
                  title: S.of(context).blockedContentTitle,
                  subtitle: S.of(context).blockedContentSubtitle,
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: PostCard(
                      post: post,
                      repository: widget.repository,
                      showActions: true,
                      showOpBadge: true,
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<CommentModel>>(
                      stream:
                          widget.repository.streamComments(widget.post.id),
                      builder: (context, snapshot) {
                        final comments = _sortedComments(
                          (snapshot.data ?? [])
                              .where(
                                (comment) =>
                                    !blockedIds.contains(comment.authorId),
                              )
                              .toList(),
                          post.bestAnswerCommentId,
                        );
                        if (comments.isEmpty) {
                          return EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: S.of(context).noCommentsYet,
                            subtitle: S.of(context).beFirstToComment,
                          );
                        }
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    S.of(context).sortComments,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SegmentedButton<CommentSort>(
                                      segments: [
                                        ButtonSegment(
                                          value: CommentSort.newest,
                                          label: Text(S.of(context).sortNewest),
                                        ),
                                        ButtonSegment(
                                          value: CommentSort.mostHelpful,
                                          label: Text(
                                            S.of(context).sortMostHelpful,
                                          ),
                                        ),
                                      ],
                                      selected: {_commentSort},
                                      onSelectionChanged: (selection) {
                                        setState(
                                          () => _commentSort = selection.first,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final isBestAnswer =
                                      comment.id == post.bestAnswerCommentId;
                                  final canMarkBest = post.isQuestion &&
                                      user?.uid == post.authorId;
                                  return CommentTile(
                                    repository: widget.repository,
                                    comment: comment,
                                    isOp: comment.authorId == post.authorId,
                                    isBestAnswer: isBestAnswer,
                                    onBestAnswerPressed: canMarkBest
                                        ? () => _handleBestAnswer(
                                              post: post,
                                              comment: comment,
                                              isBestAnswer: isBestAnswer,
                                            )
                                        : null,
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 8),
                                itemCount: comments.length,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: S.of(context).writeComment,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _sending ? null : _sendComment,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBestAnswer({
    required PostModel post,
    required CommentModel comment,
    required bool isBestAnswer,
  }) async {
    try {
      await widget.repository.setBestAnswer(
        postId: post.id,
        commentId: isBestAnswer ? null : comment.id,
        commentAuthorId: isBestAnswer ? null : comment.authorId,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).somethingWentWrong)),
        );
      }
    }
  }
}
