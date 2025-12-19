import 'package:flutter/material.dart';

import '../../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        foregroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.person, size: 18),
      ),
      title: Text(
        comment.authorName,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(comment.content),
    );
  }
}
