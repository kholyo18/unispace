import 'package:flutter/widgets.dart';

/// Preserves a visited image slide while its parent pager remains mounted.
/// The child continues to own its authorization and invalidation listeners.
class RetainedImageSlide extends StatefulWidget {
  const RetainedImageSlide(
      {super.key, required this.child, this.keepAlive = true});

  final Widget child;
  final bool keepAlive;

  @override
  State<RetainedImageSlide> createState() => _RetainedImageSlideState();
}

class _RetainedImageSlideState extends State<RetainedImageSlide>
    with AutomaticKeepAliveClientMixin<RetainedImageSlide> {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void didUpdateWidget(covariant RetainedImageSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
