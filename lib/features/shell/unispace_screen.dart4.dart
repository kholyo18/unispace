import 'package:flutter/material.dart';
// إن كان يستدعي HomeLandingScreen وما زالت في main:
// لا تنقل UnispaceScreen حتى تُنقل HomeLandingScreen، أو اترك الاستيراد عبر export من main مؤقتاً إن لزم

// class UnispaceScreen extends StatelessWidget {
//   const UnispaceScreen({super.key, required this.onOpenDrawer});
//
//   final VoidCallback onOpenDrawer;
//
//   @override
//   Widget build(BuildContext context) {
//     return HomeLandingScreen(
//       showAppBar: true,          // keep its own AppBar if you want
//       bottomPadding: 116,
//       onOpenDrawer: onOpenDrawer,
//     );
//   }
// }