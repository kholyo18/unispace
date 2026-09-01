import 'package:flutter/material.dart';

const kUniSpaceGreen = Color(0xFFB2DFDB);
const kUniSpaceBlue = Color(0xFF004D40);
const kNoteYellow = Color(0xFFFFF3C4);
const kDefaultTeal = Color(0xFF0F7C80);


class AppTeal {
  static Color main = const Color(0xFF0F7C80);
  static Color accent = const Color(0xFF13B8A6);
  static Color chat = const Color(0xFF10A37F);
  static Color green = const Color(0xFFB2DFDB);
  static Color dark = const Color(0xFF004D40);

  static Color get shade500 => main;
  static Color get shade700 => Color.lerp(main, Colors.black, 0.25)!;
  static Color get shade800 => Color.lerp(main, Colors.black, 0.40)!;
  static Color get shade900 => Color.lerp(main, Colors.black, 0.55)!;

  static void apply(Color c) {
    main = c;
    accent = Color.lerp(c, const Color(0xFF13B8A6), 0.30)!;
    chat = Color.lerp(c, const Color(0xFF10A37F), 0.20)!;
    green = Color.lerp(c, Colors.white, 0.55)!;
    dark = Color.lerp(c, Colors.black, 0.35)!;
  }
}
class AppPrimary {
  static Color seed = const Color(0xFF30475E);

  static void apply(Color c) {
    seed = c;
  }
}