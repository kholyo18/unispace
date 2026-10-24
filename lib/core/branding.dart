import 'package:flutter/material.dart';
import 'brand_palette.dart';
export 'brand_palette.dart';

const kUniSpaceGreen = UniSpaceColors.lightContainer;
const kUniSpaceBlue = UniSpaceColors.forest;
const kNoteYellow = Color(0xFFFFF3C4);
const kDefaultTeal = UniSpaceColors.forest;


class AppTeal {
  static Color main = UniSpaceColors.forest;
  static Color accent = UniSpaceColors.emerald;
  static Color chat = UniSpaceColors.forest;
  static Color green = UniSpaceColors.lightContainer;
  static Color dark = UniSpaceColors.forest;

  static Color foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Color.lerp(main, UniSpaceColors.ivory, 0.65)!
          : main;

  static Color get shade500 => main;
  static Color get shade700 => Color.lerp(main, Colors.black, 0.25)!;
  static Color get shade800 => Color.lerp(main, Colors.black, 0.40)!;
  static Color get shade900 => Color.lerp(main, Colors.black, 0.55)!;

  static void apply(Color c) {
    main = c;
    accent = c == UniSpaceColors.forest ? UniSpaceColors.emerald : Color.lerp(c, UniSpaceColors.emerald, 0.30)!;
    chat = Color.lerp(c, UniSpaceColors.forest, 0.20)!;
    green = c == UniSpaceColors.forest ? UniSpaceColors.lightContainer : Color.lerp(c, Colors.white, 0.55)!;
    dark = c == UniSpaceColors.forest ? UniSpaceColors.forest : Color.lerp(c, Colors.black, 0.35)!;
  }
}
class AppPrimary {
  static Color seed = UniSpaceColors.forest;

  static void apply(Color c) {
    seed = c;
  }
}