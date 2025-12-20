import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
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
    final textDirection = Directionality.of(context);

    final wrappedAppBar = appBar == null
        ? null
        : PreferredSize(
            preferredSize: appBar!.preferredSize,
            child: Directionality(
              textDirection: textDirection,
              child: appBar!,
            ),
          );

    final scaffold = Scaffold(
      appBar: wrappedAppBar,
      drawer: drawer == null
          ? null
          : Directionality(
              textDirection: textDirection,
              child: drawer!,
            ),
      backgroundColor: background ?? theme.colorScheme.background,
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : Directionality(
              textDirection: textDirection,
              child: bottomNavigationBar!,
            ),
      floatingActionButton: floatingActionButton == null
          ? null
          : Directionality(
              textDirection: textDirection,
              child: floatingActionButton!,
            ),
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: SafeArea(
        top: appBar == null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: safePadding,
          child: Directionality(
            textDirection: textDirection,
            child: body,
          ),
        ),
      ),
    );

    if (drawer == null) {
      return scaffold;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: scaffold,
    );
  }
}
