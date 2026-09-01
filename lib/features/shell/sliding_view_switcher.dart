import 'package:flutter/material.dart';

class UniSpaceSlidingViewSwitcher extends StatelessWidget {
  const UniSpaceSlidingViewSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [...previousChildren, if (currentChild != null) currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey(index);
        final offsetTween = isIncoming
            ? Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
            : Tween<Offset>(begin: Offset.zero, end: const Offset(-0.15, 0));

        return ClipRect(
          child: SlideTransition(
            position: offsetTween.animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(index),
        child: children[index],
      ),
    );
  }
}
// ============================================================================
// CommunityScreen
// ============================================================================

// ============================================================================
// مثال: كيفاش تستعمل SpiderWidget فمكان آخر (مثلاً بدل _HangingSpider القديم)
// ============================================================================