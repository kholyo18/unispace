part of '../../main.dart';

/// تُرجع عدد الأصوات النهائي بعد التحديث، أو null عند الفشل
final Set<String> _sharedVotesInFlight = {};
Future<int?> _applyVote(_Post post, {required bool like}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final postId = post.id;
  if (uid == null || postId == null || postId.isEmpty) return null;
  final key = '$uid/$postId';
  if (!_sharedVotesInFlight.add(key)) return null;
  final vote = like ? (post.upvoted ? 0 : 1) : (post.downvoted ? 0 : -1);
  try {
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('setPostVote', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call<Map<String, dynamic>>({'postId': postId, 'vote': vote});
    if (response.data['vote'] != vote || response.data['votes'] is! num) {
      throw const FormatException('Invalid vote response');
    }
    if (FirebaseAuth.instance.currentUser?.uid != uid) return null;
    post.votes = (response.data['votes'] as num).toInt();
    post.upvoted = vote == 1;
    post.downvoted = vote == -1;
    HapticFeedback.lightImpact();
    return post.votes;
  } catch (e) {
    debugPrint('Vote failed: $e');
    return null;
  } finally {
    _sharedVotesInFlight.remove(key);
  }
}

void _showPostTagsSheet(BuildContext context, _Post post) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Directionality(
      textDirection: Directionality.of(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Icon(Icons.device_hub_rounded, color: AppTeal.foreground(context)),
                const SizedBox(width: 8),
                Text(
                  mainText(context, "الوسوم على هذا المنشور"),
                  style: Theme.of(context)
                      .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (post.tags.isEmpty)
              Text(mainText(context, "لا توجد وسوم على هذا المنشور"),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: post.tags.map((tag) => _CommunityPostTagChip(label: tag))
                    .toList(),
              ),
          ],
        ),
      ),
    ),
  );
}
class _RedditStyleMeta extends StatefulWidget {
  const _RedditStyleMeta({
    this.authorName,
    this.authorPhotoUrl,
    this.postTitle,
    this.postBody,
  });

  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody;

  @override
  State<_RedditStyleMeta> createState() => _RedditStyleMetaState();
}

class _RedditStyleMetaState extends State<_RedditStyleMeta> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.authorName?.trim() ?? '';
    final title = widget.postTitle?.trim() ?? '';
    final body = widget.postBody?.trim() ?? '';
    final canExpand = body.length > 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name.isNotEmpty)
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white24,
                backgroundImage: (widget.authorPhotoUrl != null &&
                    widget.authorPhotoUrl!.trim().isNotEmpty)
                    ? ProtectedNetworkImage(widget.authorPhotoUrl!)
                    : null,
                child: (widget.authorPhotoUrl == null ||
                    widget.authorPhotoUrl!.trim().isEmpty)
                    ? const Icon(Icons.person, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.startsWith('') ? name : 'u/$name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

        if (title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],

        if (body.isNotEmpty) ...[
          const SizedBox(height: 4),

          // عند التوسيع: منطقة قابلة للتمرير + تمنع سحب الإغلاق
          if (_expanded)
            NotificationListener<ScrollNotification>(
              onNotification: (_) => true, // امتصاص السكرول حتى لا يغلق العارض
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
                height: 1.35,
              ),
            ),

          if (canExpand) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? mainText(context, "عرض أقل") : mainText(context, "عرض المزيد"),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _FullscreenActionBar extends StatelessWidget {
  const _FullscreenActionBar({
    required this.likeButtonKey,
    required this.tagsCount,
    required this.onTagsTap,
    required this.commentLabel,
    required this.onCommentTap,
    required this.likeLabel,
    required this.isLiked,
    required this.isDisliked,
    required this.onLikeTap,
    required this.onDislike,
  });

  final Key likeButtonKey;
  final int tagsCount;
  final VoidCallback onTagsTap;
  final String commentLabel;
  final VoidCallback onCommentTap;
  final String likeLabel;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLikeTap;
  final VoidCallback onDislike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FullscreenLikePill(
              key: likeButtonKey,
              label: likeLabel,
              isLiked: isLiked,
              isDisliked: isDisliked,
              onLike: onLikeTap,
              onDislike: onDislike,
            ),
            const SizedBox(width: 8),
            _FullscreenActionPill(
              icon: FontAwesomeIcons.comment,
              label: commentLabel,
              onTap: onCommentTap,
            ),
          ],
        ),
        const Spacer(),
        _FullscreenTagsButton(
          count: tagsCount,
          onTap: onTagsTap,
        ),
      ],
    );
  }
}

// ==================== زر القلب + Dislike — سحب طويل للمعاينة ====================
class _FullscreenLikePill extends StatefulWidget {
  const _FullscreenLikePill({
    super.key,
    required this.label,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  final String label;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  @override
  State<_FullscreenLikePill> createState() => _FullscreenLikePillState();
}

class _FullscreenLikePillState extends State<_FullscreenLikePill> {
  bool _isLongPressing = false;
  int _dragDirection = 0;
  Offset? _longPressStartPosition;

  static const double _activationDistance = 18;
  static const Color _likeColor = Color(0xFFE11D48);
  static const Color _dislikeColor = Color(0xFF8B5CF6);

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isLongPressing = true;
      _dragDirection = 0;
      _longPressStartPosition = details.globalPosition;
    });
    HapticFeedback.mediumImpact();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isLongPressing || _longPressStartPosition == null) return;
    final dx = details.globalPosition.dx - _longPressStartPosition!.dx;
    int direction = 0;
    if (dx > _activationDistance) {
      direction = 1;
    } else if (dx < -_activationDistance) {
      direction = -1;
    }
    if (direction != _dragDirection) {
      setState(() => _dragDirection = direction);
      if (direction != 0) HapticFeedback.selectionClick();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isLongPressing) return;
    final direction = _dragDirection;
    setState(() {
      _isLongPressing = false;
      _dragDirection = 0;
      _longPressStartPosition = null;
    });
    if (direction == 1) {
      widget.onLike();
    } else if (direction == -1) {
      widget.onDislike();
    }
  }

  void _onLongPressCancel() {
    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
      _dragDirection = 0;
      _longPressStartPosition = null;
    });
  }

  void _onNormalTap() {
    if (_isLongPressing) return;
    if (widget.isDisliked) {
      widget.onDislike();
      return;
    }
    if (widget.isLiked) {
      widget.onLike();
      return;
    }
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final showLikeSelected = widget.isLiked || _dragDirection == 1;
    final showDislikeSelected = widget.isDisliked || _dragDirection == -1;

    final Color color;
    if (showLikeSelected) {
      color = _likeColor;
    } else if (showDislikeSelected) {
      color = _dislikeColor;
    } else {
      color = Colors.white;
    }

    final IconData icon;
    if (showLikeSelected) {
      icon = Icons.favorite_rounded;
    } else if (showDislikeSelected) {
      icon = Icons.heart_broken_rounded;
    } else {
      icon = Icons.favorite_border_rounded;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      onTap: _onNormalTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 34,
            decoration: BoxDecoration(
              color: showLikeSelected
                  ? _likeColor.withValues(alpha: 0.22)
                  : showDislikeSelected
                  ? _dislikeColor.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: showLikeSelected
                    ? _likeColor.withValues(alpha: 0.5)
                    : showDislikeSelected
                    ? _dislikeColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (_isLongPressing)
            Positioned(
              bottom: 48,
              left: -30,
              right: -20,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FullscreenVotePreview(
                      icon: Icons.heart_broken_rounded,
                      color: _dislikeColor,
                      selected: _dragDirection == -1,
                    ),
                    _FullscreenVotePreview(
                      icon: Icons.favorite_rounded,
                      color: _likeColor,
                      selected: _dragDirection == 1,
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

class _FullscreenVotePreview extends StatelessWidget {
  const _FullscreenVotePreview({
    required this.icon,
    required this.color,
    required this.selected,
  });

  final IconData icon;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.75) : color.withValues(alpha: 0.30),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 2)
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: selected ? 25 : 22),
      ),
    );
  }
}

// ==================== زر التعليقات — pill شفاف بحال Reddit ====================
class _FullscreenActionPill extends StatelessWidget {
  const _FullscreenActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== زر الوسوم — دائرة شفافة مع Badge ====================
class _FullscreenTagsButton extends StatelessWidget {
  const _FullscreenTagsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(LucideIcons.gitPullRequest, color: Colors.white, size: 18),
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: UniSpaceColors.emerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
