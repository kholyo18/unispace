import 'package:flutter/material.dart';

/// One continuous wallpaper behind both translucent chrome and conversation.
/// Content stays below the app bar, so the first message is never obscured.
class ChatWallpaperScaffold extends StatelessWidget {
  const ChatWallpaperScaffold({super.key, required this.decoration,
    required this.appBar, required this.body});
  final Decoration decoration;
  final PreferredSizeWidget appBar;
  final Widget body;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: decoration,
    child: Scaffold(backgroundColor: Colors.transparent, appBar: appBar, body: body),
  );
}
