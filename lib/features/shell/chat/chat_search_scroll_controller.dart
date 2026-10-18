import 'package:flutter/widgets.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Stops a multi-step indexed jump when the query changes or search closes.
class ChatSearchScrollController extends SimpleAutoScrollController {
  ChatSearchScrollController()
      : super(beginGetter: (rect) => rect.top, endGetter: (rect) => rect.bottom);
  bool _seeking = false, _cancelled = false;

  Future<void> reveal(int index) async {
    _cancelled = false;
    _seeking = true;
    try {
      await scrollToIndex(index, preferPosition: AutoScrollPosition.middle,
          duration: const Duration(milliseconds: 220));
    } on _SearchScrollCancelled {
      // Cancellation is expected when typing a new query or leaving search.
    } finally { _seeking = false; }
  }

  void cancelSearchJump() {
    _cancelled = true;
    if (_seeking && hasClients) super.jumpTo(offset);
  }

  @override
  Future<void> animateTo(double offset, {required Duration duration, required Curve curve}) async {
    if (_seeking && _cancelled) throw const _SearchScrollCancelled();
    await super.animateTo(offset, duration: duration, curve: curve);
    if (_seeking && _cancelled) throw const _SearchScrollCancelled();
  }

  @override
  void dispose() {
    cancelSearchJump();
    super.dispose();
  }
}

class _SearchScrollCancelled implements Exception {
  const _SearchScrollCancelled();
}
