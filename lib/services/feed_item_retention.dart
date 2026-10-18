import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Retains a bounded number of recently visible row states, not permissions.
/// The owning feed must discard this controller when its viewer changes.
class FeedItemRetentionController extends ChangeNotifier {
  FeedItemRetentionController({this.capacity = 6}) : assert(capacity > 0);

  final int capacity;
  final LinkedHashSet<String> _recent = LinkedHashSet<String>();
  bool _disposed = false;

  bool contains(String id) => !_disposed && _recent.contains(id);

  void markVisible(String id) {
    if (_disposed) return;
    final alreadyRetained = _recent.remove(id);
    _recent.add(id);
    var evicted = false;
    while (_recent.length > capacity) {
      _recent.remove(_recent.first);
      evicted = true;
    }
    if (!alreadyRetained || evicted) notifyListeners();
  }

  /// Releases retained rows on feed/account invalidation.
  void clear() {
    if (_disposed || _recent.isEmpty) return;
    _recent.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _recent.clear();
    super.dispose();
  }
}

class RetainedFeedItem extends StatefulWidget {
  const RetainedFeedItem(
      {super.key,
      required this.id,
      required this.controller,
      required this.child});

  final String id;
  final FeedItemRetentionController controller;
  final Widget child;

  @override
  State<RetainedFeedItem> createState() => _RetainedFeedItemState();
}

class _RetainedFeedItemState extends State<RetainedFeedItem>
    with AutomaticKeepAliveClientMixin<RetainedFeedItem> {
  @override
  bool get wantKeepAlive => widget.controller.contains(widget.id);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_retentionChanged);
  }

  void _retentionChanged() {
    if (mounted) updateKeepAlive();
  }

  @override
  void didUpdateWidget(covariant RetainedFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_retentionChanged);
      widget.controller.addListener(_retentionChanged);
    }
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: ObjectKey(this),
      onVisibilityChanged: (info) {
        if (mounted && info.visibleFraction > 0) {
          widget.controller.markVisible(widget.id);
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_retentionChanged);
    super.dispose();
  }
}
