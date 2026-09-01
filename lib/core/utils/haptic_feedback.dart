import 'package:flutter/services.dart';

class HapticUtils {
  static void lightImpact() => HapticFeedback.lightImpact();
  static void mediumImpact() => HapticFeedback.mediumImpact();
  static void heavyImpact() => HapticFeedback.heavyImpact();
  static void selectionClick() => HapticFeedback.selectionClick();
  static void vibrate() => HapticFeedback.vibrate();

  // استخدامات محددة
  static void onLike() => lightImpact();
  static void onDislike() => mediumImpact();
  static void onLongPress() => heavyImpact();
  static void onRefresh() => lightImpact();
  static void onTabSelect() => selectionClick();
}