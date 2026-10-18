import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Floating Instagram-style stack, anchored to the selected bubble and kept
/// inside the safe viewport even for a very long message or a visible keyboard.
class ChatMessageActionFrame extends StatelessWidget {
  const ChatMessageActionFrame(
      {super.key,
      required this.preview,
      required this.reactions,
      required this.actions,
      this.anchor,
      this.isMine = false});
  final Widget preview, reactions, actions;
  final Rect? anchor;
  final bool isMine;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
        child: Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + media.viewInsets.bottom),
      child: LayoutBuilder(
          builder: (context, constraints) => CustomSingleChildLayout(
                delegate: _ActionPosition(
                    anchor: anchor,
                    isMine: isMine,
                    topInset: media.padding.top + 12),
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: math.min(350, constraints.maxWidth),
                        maxHeight: constraints.maxHeight),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: reactions),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * .25),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child:
                                      SingleChildScrollView(child: preview))),
                          const SizedBox(height: 10),
                          Flexible(
                              child: SizedBox(
                                  width: math.min(270, constraints.maxWidth),
                                  child: Material(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      elevation: 8,
                                      shadowColor: Colors.black26,
                                      borderRadius: BorderRadius.circular(20),
                                      clipBehavior: Clip.antiAlias,
                                      child: SingleChildScrollView(
                                          child: actions)))),
                        ])),
              )),
    ));
  }
}

class _ActionPosition extends SingleChildLayoutDelegate {
  _ActionPosition(
      {required this.anchor, required this.isMine, required this.topInset});
  final Rect? anchor;
  final bool isMine;
  final double topInset;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = anchor == null
        ? (size.height - childSize.height) / 2
        : anchor!.top - topInset - 68;
    return Offset(isMine ? math.max(0, size.width - childSize.width) : 0,
        top.clamp(0.0, math.max(0.0, size.height - childSize.height)));
  }

  @override
  bool shouldRelayout(_ActionPosition old) =>
      anchor != old.anchor || isMine != old.isMine || topInset != old.topInset;
}
