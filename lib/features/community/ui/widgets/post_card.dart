import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../data/community_repository.dart';
import '../../models/post_model.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.repository,
    this.onOpen,
    this.showActions = true,
    this.showOpBadge = false,
    this.onTagSelected,
  });

  final PostModel post;
  final CommunityRepository repository;
  final VoidCallback? onOpen;
  final bool showActions;
  final bool showOpBadge;
  final ValueChanged<String>? onTagSelected;

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: false,
    );
    return '${localizations.formatShortDate(date)} • $time';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }

  String _authorMeta() {
    final parts = <String>[];
    if (post.university != null && post.university!.trim().isNotEmpty) {
      parts.add(post.university!.trim());
    }
    if (post.authorMajor != null && post.authorMajor!.trim().isNotEmpty) {
      parts.add(post.authorMajor!.trim());
    }
    if (post.authorYear != null && post.authorYear!.trim().isNotEmpty) {
      parts.add(post.authorYear!.trim());
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _authorMeta();
    final tagChips = post.tags
        .map((tag) {
          if (onTagSelected == null) {
            return Chip(
              label: Text(tag),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }
          return ActionChip(
            label: Text(tag),
            onPressed: () => onTagSelected!(tag),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        })
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      color: post.isQuestion
          ? theme.colorScheme.primary.withOpacity(0.06)
          : theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    foregroundColor: theme.colorScheme.primary,
                    child: _initials(post.authorName).isEmpty
                        ? const Icon(Icons.person)
                        : Text(
                            _initials(post.authorName),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.authorName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (showOpBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primary.withOpacity(0.12),
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
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                      ],
                    ),
                  ),
                  if (_formatDate(context, post.createdAt).isNotEmpty)
                    Text(
                      _formatDate(context, post.createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (post.isQuestion)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    S.of(context).questionTag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (post.isQuestion) const SizedBox(height: 8),
              Text(
                post.content,
                style: theme.textTheme.bodyMedium,
              ),
              if (tagChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagChips,
                ),
              ],
              if (showActions) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: repository.streamIsPostLiked(post.id),
                      builder: (context, snapshot) {
                        final liked = snapshot.data ?? false;
                        return IconButton(
                          tooltip: S.of(context).like,
                          onPressed: () => _handleLike(context),
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color,
                          ),
                        );
                      },
                    ),
                    Text(
                      post.likesCount.toString(),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.mode_comment_outlined),
                      label: Text(
                        '${post.commentsCount} ${S.of(context).comments}',
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<bool>(
                      stream: repository.streamIsPostSaved(post.id),
                      builder: (context, snapshot) {
                        final saved = snapshot.data ?? false;
                        return IconButton(
                          tooltip: S.of(context).savePost,
                          onPressed: () => _handleSave(context),
                          icon: Icon(
                            saved ? Icons.bookmark : Icons.bookmark_border,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleLike(BuildContext context) async {
    try {
      await repository.toggleLike(post.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    }
  }

  void _handleSave(BuildContext context) async {
    try {
      await repository.toggleSave(post.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    }
  }
}
