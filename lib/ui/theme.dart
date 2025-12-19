import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF3557D5);
  static const _secondary = Color(0xFF2F9E44);
  static const _error = Color(0xFFE03131);

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      secondary: _secondary,
      error: _error,
      surface: brightness == Brightness.light
          ? const Color(0xFFF7F8FC)
          : const Color(0xFF12131A),
      background: brightness == Brightness.light
          ? const Color(0xFFF2F3F9)
          : const Color(0xFF0C0D11),
    );

    final textTheme = _buildTextTheme(brightness);

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        shape: roundedShape,
        elevation: brightness == Brightness.light ? 1 : 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: scheme.primary,
      ),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: roundedShape,
          textStyle: textTheme.labelLarge,
          elevation: brightness == Brightness.light ? 1 : 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: roundedShape,
          textStyle: textTheme.labelLarge,
          elevation: brightness == Brightness.light ? 1 : 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: roundedShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withOpacity(.12),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(MaterialState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: brightness == Brightness.light ? 2 : 0,
        color: scheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.titleSmall,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 24),
        ),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.surface),
        shape: roundedShape,
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: scheme.primary.withOpacity(.12),
        backgroundColor: scheme.surfaceVariant,
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: scheme.outlineVariant.withOpacity(.6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: scheme.surface,
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        shape: roundedShape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: scheme.surface,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.55),
      bodySmall: base.bodySmall?.copyWith(height: 1.5),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    );
  }
}
