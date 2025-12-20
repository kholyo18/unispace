import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../data/community_repository.dart';
import '../../models/post_model.dart';
import '../../utils/community_score_utils.dart';
import '../../utils/saved_post_category.dart';
import '../../utils/tag_utils.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.repository,
    this.onOpen,
    this.showActions = true,
    this.showOpBadge = false,
    this.savedCategory,
    this.onSavedCategoryTap,
    this.onTagSelected,
  });

  final PostModel post;
  final CommunityRepository repository;
  final VoidCallback? onOpen;
  final bool showActions;
  final bool showOpBadge;
  final SavedPostCategory? savedCategory;
  final VoidCallback? onSavedCategoryTap;
  final ValueChanged<String>? onTagSelected;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool? _savedOverride;

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
    if (widget.post.university != null &&
        widget.post.university!.trim().isNotEmpty) {
      parts.add(widget.post.university!.trim());
    }
    if (widget.post.authorMajor != null &&
        widget.post.authorMajor!.trim().isNotEmpty) {
      parts.add(widget.post.authorMajor!.trim());
    }
    if (widget.post.authorYear != null &&
        widget.post.authorYear!.trim().isNotEmpty) {
      parts.add(widget.post.authorYear!.trim());
    }
    return parts.join(' • ');
  }

  void _syncSavedOverride(bool? savedFromStream) {
    if (_savedOverride == null) return;
    if (savedFromStream != _savedOverride) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _savedOverride = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _authorMeta();
    final tagChips = widget.post.tags
        .map((tag) {
          if (widget.onTagSelected == null) {
            return Chip(
              label: Text(displayTag(tag)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }
          return ActionChip(
            label: Text(displayTag(tag)),
            onPressed: () => widget.onTagSelected!(tag),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        })
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      color: widget.post.isQuestion
          ? theme.colorScheme.primary.withOpacity(0.06)
          : theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onOpen,
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
                    child: _initials(widget.post.authorName).isEmpty
                        ? const Icon(Icons.person)
                        : Text(
                            _initials(widget.post.authorName),
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
                                widget.post.authorName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _AuthorBadge(
                              repository: widget.repository,
                              authorId: widget.post.authorId,
                            ),
                            if (widget.showOpBadge)
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
                  if (_formatDate(context, widget.post.createdAt).isNotEmpty)
                    Text(
                      _formatDate(context, widget.post.createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.post.isQuestion)
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
              if (widget.post.isQuestion) const SizedBox(height: 8),
              Text(
                widget.post.content,
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.savedCategory != null &&
                  widget.onSavedCategoryTap != null) ...[
                const SizedBox(height: 12),
                ActionChip(
                  label: Text(
                    savedPostCategoryLabel(context, widget.savedCategory!),
                  ),
                  onPressed: widget.onSavedCategoryTap,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (tagChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagChips,
                ),
              ],
              if (widget.showActions) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: widget.repository.streamIsPostLiked(widget.post.id),
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
                      widget.post.likesCount.toString(),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: widget.onOpen,
                      icon: const Icon(Icons.mode_comment_outlined),
                      label: Text(
                        '${widget.post.commentsCount} ${S.of(context).comments}',
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<bool>(
                      stream:
                          widget.repository.streamIsPostSaved(widget.post.id),
                      builder: (context, snapshot) {
                        _syncSavedOverride(snapshot.data);
                        final saved =
                            _savedOverride ?? (snapshot.data ?? false);
                        return IconButton(
                          tooltip: S.of(context).savePost,
                          onPressed: () => _handleSave(context, saved),
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
      await widget.repository.toggleLike(widget.post.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    }
  }

  void _handleSave(BuildContext context, bool currentSaved) async {
    setState(() => _savedOverride = !currentSaved);
    try {
      await widget.repository.toggleSave(widget.post.id);
    } catch (_) {
      if (mounted) {
        setState(() => _savedOverride = currentSaved);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginRequired)),
        );
      }
    }
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
