import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.isOp = false,
  });

  final CommentModel comment;
  final bool isOp;

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(comment.authorName);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        foregroundColor: theme.colorScheme.primary,
        child: initials.isEmpty
            ? const Icon(Icons.person, size: 18)
            : Text(
                initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              comment.authorName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (isOp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                S.of(context).opBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(comment.content),
    );
  }
}
