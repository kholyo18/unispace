import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../data/community_repository.dart';
import '../../models/comment_model.dart';
import '../../utils/community_score_utils.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.repository,
    required this.comment,
    this.isOp = false,
    this.isBestAnswer = false,
    this.onBestAnswerPressed,
  });

  final CommunityRepository repository;
  final CommentModel comment;
  final bool isOp;
  final bool isBestAnswer;
  final VoidCallback? onBestAnswerPressed;

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
          _AuthorBadge(
            repository: repository,
            authorId: comment.authorId,
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBestAnswer)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                S.of(context).bestAnswerLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(comment.content),
        ],
      ),
      trailing: onBestAnswerPressed == null
          ? null
          : TextButton(
              onPressed: onBestAnswerPressed,
              child: Text(
                isBestAnswer
                    ? S.of(context).unmarkBestAnswer
                    : S.of(context).markBestAnswer,
              ),
            ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge({
    required this.repository,
    required this.authorId,
  });

  final CommunityRepository repository;
  final String authorId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: repository.streamCommunityScore(authorId),
      builder: (context, snapshot) {
        final score = snapshot.data ?? 0;
        final badge = badgeForScore(score);
        if (badge == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsetsDirectional.only(start: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeLabel(context, badge),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
