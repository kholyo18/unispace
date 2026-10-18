import 'package:flutter/material.dart';

class ChatWallpaperPreset {
  const ChatWallpaperPreset(
      this.id, this.ar, this.en, this.fr, this.light, this.dark);
  final String id, ar, en, fr;
  final List<Color> light, dark;
  String label(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en,
      };
  LinearGradient gradient(bool isDark) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark ? dark : light);
}

const extraChatWallpapers = [
  ChatWallpaperPreset(
      'pearl',
      'لؤلؤي',
      'Pearl',
      'Perle',
      [Color(0xFFF8F7F3), Color(0xFFE4E7E9)],
      [Color(0xFF23272B), Color(0xFF15191D)]),
  ChatWallpaperPreset(
      'sage',
      'مريمية',
      'Sage',
      'Sauge',
      [Color(0xFFEEF4E9), Color(0xFFD4E4D6)],
      [Color(0xFF20342C), Color(0xFF14251F)]),
  ChatWallpaperPreset(
      'coffee',
      'قهوة',
      'Coffee',
      'Café',
      [Color(0xFFF3EAE1), Color(0xFFE2D0BF)],
      [Color(0xFF32271F), Color(0xFF201B17)]),
  ChatWallpaperPreset(
      'ice',
      'جليدي',
      'Ice',
      'Glace',
      [Color(0xFFF0F8FC), Color(0xFFD4E7F2)],
      [Color(0xFF1C3040), Color(0xFF101E2C)]),
  ChatWallpaperPreset(
      'apricot',
      'مشمشي',
      'Apricot',
      'Abricot',
      [Color(0xFFFFF0E4), Color(0xFFF4D4C0)],
      [Color(0xFF39271F), Color(0xFF261A17)]),
  ChatWallpaperPreset(
      'lilac',
      'ليلكي',
      'Lilac',
      'Lilas',
      [Color(0xFFF2ECF8), Color(0xFFDED6ED)],
      [Color(0xFF2E263E), Color(0xFF1C192A)]),
  ChatWallpaperPreset(
      'aurora',
      'شفق',
      'Aurora',
      'Aurore',
      [Color(0xFFDDEFE8), Color(0xFFE7E0F5)],
      [Color(0xFF183530), Color(0xFF2A2140)]),
  ChatWallpaperPreset(
      'blush',
      'وردي هادئ',
      'Blush',
      'Rose poudré',
      [Color(0xFFF9EEEE), Color(0xFFEED9DF)],
      [Color(0xFF35232D), Color(0xFF241A23)]),
];

ChatWallpaperPreset? extraChatWallpaper(String id) {
  for (final preset in extraChatWallpapers) {
    if (preset.id == id) return preset;
  }
  return null;
}
