part of '../../main.dart';

class _TagsIndicatorButton extends StatelessWidget {
  const _TagsIndicatorButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFEAF7F8).withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.12
                  : 0.78,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color:  AppTeal.main.withValues(alpha: 0.14)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
               Center(
                child: Icon(LucideIcons.gitPullRequest, size: 18,
                    color: Theme.of(context)
                      .colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color:  AppTeal.main,
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
class _CommunityPostTagChip extends StatelessWidget {
  const _CommunityPostTagChip({required this.label});

  final String label;

  IconData get _icon {
    switch (label.trim()) {
      case 'نقاش جامعي':
        return Icons.forum_rounded;
      case 'أسئلة':
        return Icons.help_outline_rounded;
      case 'مواد':
        return Icons.menu_book_rounded;
      case 'امتحانات':
        return Icons.assignment_rounded;
      case 'نصائح':
        return Icons.lightbulb_outline_rounded;
      case 'تخصصات':
        return Icons.school_rounded;
      default:
        return Icons.sell_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 13.5,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 4),
          Text(
            mainTagText(context, label),
            style:  TextStyle(
              color: AppTeal.main,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPostActionBar extends StatelessWidget {
  const _CommunityPostActionBar({
    super.key,
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
            const SizedBox(width: 8),
            _LikeActionPill(
              key: likeButtonKey,
              label: likeLabel,
              isLiked: isLiked,
              isDisliked: isDisliked,
              onLike: onLikeTap,
              onDislike: onDislike,
            ),

            const SizedBox(width: 8),
            _PostActionPill(
              icon: FontAwesomeIcons.comment,
              label: commentLabel,
              selected: false,
              selectedColor: const Color(0xFF1565C0),
              onTap: onCommentTap,
            ),

          ],
        ),

        const Spacer(),
        _TagsIndicatorButton(
          count: tagsCount,
          onTap: onTagsTap,
        ),

      ],
    );
  }
}

class _LikeActionPill extends StatefulWidget {
  const _LikeActionPill({
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
  State<_LikeActionPill> createState() => _LikeActionPillState();
}

class _LikeActionPillState extends State<_LikeActionPill> {
  bool _pressing = false;
  bool _armedDislike = false; // السحب لأعلى وصل العتبة
  Offset? _start;

  static const double _upThreshold = 28; // مسافة السحب لأعلى بالميل

  void _startPress(Offset global) {
    HapticFeedback.mediumImpact();
    setState(() {
      _pressing = true;
      _armedDislike = false;
      _start = global;
    });
  }

  void _updatePress(Offset global) {
    if (!_pressing || _start == null) return;
    final dy = _start!.dy - global.dy; // موجب = سحب لأعلى
    final armed = dy >= _upThreshold;
    if (armed != _armedDislike) {
      setState(() => _armedDislike = armed);
      if (armed) HapticFeedback.selectionClick();
    }
  }

  void _endPress() {
    if (!_pressing) return;
    final doDislike = _armedDislike;
    setState(() {
      _pressing = false;
      _armedDislike = false;
      _start = null;
    });
    if (doDislike) {
      widget.onDislike();
    }
  }

  void _cancelPress() {
    if (!mounted) return;
    setState(() {
      _pressing = false;
      _armedDislike = false;
      _start = null;
    });
  }

  void _onTap() {
    if (_pressing) return;
    if (widget.isDisliked) {
      widget.onDislike(); // إلغاء عدم الإعجاب
      return;
    }
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const likeColor = Color(0xFFE11D48);
    const dislikeColor = Color(0xFF8B5CF6);
    const neutral = Color(0xFF64748B);

    final Color color;
    final IconData icon;
    if (widget.isLiked) {
      color = likeColor;
      icon = Icons.favorite_rounded;
    } else if (widget.isDisliked) {
      color = dislikeColor;
      icon = Icons.heart_broken_rounded;
    } else {
      color = neutral;
      icon = Icons.favorite_border_rounded;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // ===== الزر الأساسي =====
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onLongPressStart: (d) => _startPress(d.globalPosition),
          onLongPressMoveUpdate: (d) => _updatePress(d.globalPosition),
          onLongPressEnd: (_) => _endPress(),
          onLongPressCancel: _cancelPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isLiked
                  ? likeColor.withValues(alpha: 0.13)
                  : widget.isDisliked
                  ? dislikeColor.withValues(alpha: 0.13)
                  : const Color(0xFFEAF7F8)
                  .withValues(alpha: isDark ? 0.12 : 0.78),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: widget.isLiked
                    ? likeColor.withValues(alpha: 0.30)
                    : widget.isDisliked
                    ? dislikeColor.withValues(alpha: 0.30)
                    : AppTeal.main.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(icon, size: 18, color: color),
              ],
            ),
          ),
        ),

        // ===== زر عدم الإعجاب (يظهر فوق أثناء الضغط المطوّل) =====
        if (_pressing)
          Positioned(
            bottom: 40,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: _armedDislike ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _armedDislike
                        ? dislikeColor
                        : (isDark ? const Color(0xFF1E1E22) : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dislikeColor.withValues(
                        alpha: _armedDislike ? 0 : 0.4,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.heart_broken_rounded,
                    size: 22,
                    color: _armedDislike ? Colors.white : dislikeColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PostActionPill extends StatelessWidget {
  const _PostActionPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? selectedColor : const Color(0xFF64748B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 30,
      decoration: BoxDecoration(
        color: selected
            ? selectedColor.withValues(alpha: 0.13)
            : const Color(0xFFEAF7F8).withValues(
          alpha: theme.brightness == Brightness.dark ? 0.12 : 0.78,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? selectedColor.withValues(alpha: 0.30)
              :  AppTeal.main.withValues(alpha: 0.10),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FaIcon(icon, size: 17, color: color),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ==================== MediaCarousel ====================
