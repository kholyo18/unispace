import 'package:flutter/widgets.dart';

/// Requests another page from the feed viewport, including after layout changes.
class FeedPaginationListener extends StatefulWidget {
  const FeedPaginationListener({
    super.key,
    required this.onLoadMore,
    required this.child,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  @override
  State<FeedPaginationListener> createState() => _FeedPaginationListenerState();
}

class _FeedPaginationListenerState extends State<FeedPaginationListener> {
  bool _scheduled = false;

  void _consider(ScrollMetrics metrics, int depth) {
    if (depth != 0 ||
        metrics.axis != Axis.vertical ||
        metrics.extentAfter > 1000 ||
        _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _consider(notification.metrics, notification.depth);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _consider(notification.metrics, notification.depth);
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
