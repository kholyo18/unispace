import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../data/community_repository.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'widgets/comment_tile.dart';
import 'widgets/post_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).postDetails),
      ),
      body: Column(
        children: [
          StreamBuilder<PostModel?>(
            stream: widget.repository.streamPost(widget.post.id),
            builder: (context, snapshot) {
              final post = snapshot.data ?? widget.post;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: PostCard(
                  post: post,
                  repository: widget.repository,
                  showActions: true,
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: widget.repository.streamComments(widget.post.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(S.of(context).noCommentsYet),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemBuilder: (context, index) =>
                      CommentTile(comment: comments[index]),
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemCount: comments.length,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
