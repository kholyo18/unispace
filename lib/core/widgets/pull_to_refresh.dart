import 'package:flutter/material.dart';
import '../utils/haptic_feedback.dart';

class UniSpacePullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;

  const UniSpacePullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticUtils.onRefresh();
        await onRefresh();
      },
      child: scrollController != null
          ? child
          : NotificationListener<ScrollUpdateNotification>(
        child: child,
        onNotification: (n) {
          // سيتم معالجة إخفاء الشريط في HomeShell
          return false;
        },
      ),
    );
  }
}