import 'package:flutter/material.dart';

/// Shared UI roles for the approved campus identity. Media and user-selected
/// colors are deliberately independent of this palette.
abstract final class UniSpaceColors {
  static const forest = Color(0xFF00483F);
  static const emerald = Color(0xFF00AD87);
  static const mint = Color(0xFF83CBB2);
  static const ivory = Color(0xFFF6F0DF);
  static const lightBackground = Color(0xFFF4F6F3);
  static const lightInk = Color(0xFF202D25);
  static const darkInk = Color(0xFFEDF3EE);
  static const lightSurfaceHigh = Color(0xFFE7ECE8);
  static const darkSurfaceHigh = Color(0xFF24332A);
  static const lightSurfaceHighest = Color(0xFFDEE6DF);
  static const darkSurfaceHighest = Color(0xFF2D3E33);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightField = Color(0xFFEDF1EE);
  static const lightContainer = Color(0xFFE2EEE7);
  static const lightMuted = Color(0xFF59675F);
  static const lightOutline = Color(0xFF738078);
  static const lightBorder = Color(0xFFDCE3DD);
  static const darkBackground = Color(0xFF101914);
  static const darkSurface = Color(0xFF1B2720);
  static const darkField = Color(0xFF152019);
  static const darkContainer = Color(0xFF2B3D32);
  static const darkMuted = Color(0xFFAFBDB3);
  static const darkOutline = Color(0xFF84998C);
  static const darkBorder = Color(0xFF36483C);

  static Color background(bool dark) => dark ? darkBackground : lightBackground;
  static Color surface(bool dark) => dark ? darkSurface : lightSurface;
  static Color field(bool dark) => dark ? darkField : lightField;
  static Color ink(bool dark) => dark ? darkInk : lightInk;
  static Color muted(bool dark) => dark ? darkMuted : lightMuted;
  static Color border(bool dark) => dark ? darkBorder : lightBorder;
  static Color accent(bool dark) => dark ? mint : forest;
}
