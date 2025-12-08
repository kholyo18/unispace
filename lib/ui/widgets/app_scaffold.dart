import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.endDrawer,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.background,
    this.padding,
    this.extendBody = true,
    required this.body,
  });

  final PreferredSizeWidget? appBar;
  final Widget? endDrawer;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget body;
  final Color? background;
  final EdgeInsetsGeometry? padding;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safePadding = padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    return Scaffold(
      appBar: appBar,
      endDrawer: endDrawer,
      drawer: drawer,
      backgroundColor: background ?? theme.colorScheme.background,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        top: appBar == null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: safePadding,
          child: body,
        ),
      ),
    );
  }
}
