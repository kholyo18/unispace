import 'package:flutter/material.dart';
import '../core/branding.dart';

class AppTheme {
  // ────────────────────────────── ثوابت الألوان ──────────────────────────────

  // ────────────────────────────── Getters الثيمات ──────────────────────────────
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark  => _buildTheme(Brightness.dark);

  // ────────────────────────────── بناء الثيم الرئيسي ──────────────────────────────
  static ThemeData _buildTheme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppPrimary.seed,
      brightness: brightness,
    );

    final dark = brightness == Brightness.dark;
    final branded = AppPrimary.seed == UniSpaceColors.forest;
    final primary = branded ? UniSpaceColors.accent(dark) : baseScheme.primary;
    final scheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: branded ? (dark ? UniSpaceColors.forest : Colors.white) : baseScheme.onPrimary,
      primaryContainer: dark ? UniSpaceColors.darkContainer : UniSpaceColors.lightContainer,
      onPrimaryContainer: UniSpaceColors.ink(dark),
      secondary: dark ? const Color(0xFFA8C7B5) : const Color(0xFF4C6858),
      onSecondary: dark ? UniSpaceColors.darkBackground : Colors.white,
      secondaryContainer: dark ? UniSpaceColors.darkContainer : UniSpaceColors.lightContainer,
      onSecondaryContainer: UniSpaceColors.ink(dark),
      surface: UniSpaceColors.surface(dark),
      onSurface: UniSpaceColors.ink(dark),
      onSurfaceVariant: UniSpaceColors.muted(dark),
      surfaceDim: UniSpaceColors.background(dark),
      surfaceBright: UniSpaceColors.surface(dark),
      surfaceContainerLowest: dark ? UniSpaceColors.darkBackground : Colors.white,
      surfaceContainerLow: UniSpaceColors.field(dark),
      surfaceContainer: UniSpaceColors.surface(dark),
      surfaceContainerHigh: dark ? UniSpaceColors.darkSurfaceHigh : UniSpaceColors.lightSurfaceHigh,
      surfaceContainerHighest: dark ? UniSpaceColors.darkSurfaceHighest : UniSpaceColors.lightSurfaceHighest,
      outline: dark ? UniSpaceColors.darkOutline : UniSpaceColors.lightOutline,
      outlineVariant: UniSpaceColors.border(dark),
    );
    final scaffoldBackgroundColor = UniSpaceColors.background(dark);
    final textTheme = _buildTextTheme(brightness).apply(
      bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,

      // ───── Card Theme ─────
      cardTheme: CardThemeData(
        shape: roundedShape,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ───── Input Decoration ─────
      inputDecorationTheme: _inputDecorationTheme(scheme),
      textSelectionTheme: TextSelectionThemeData(cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .22), selectionHandleColor: scheme.primary),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(color: scheme.surface, surfaceTintColor: Colors.transparent),
      drawerTheme: DrawerThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary, unselectedItemColor: scheme.onSurfaceVariant),

      // ───── AppBar ─────
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      // ───── Buttons ─────
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

      // ───── Navigation & Bottom ─────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: brightness == Brightness.light ? 2 : 0,
        color: scheme.surface,
      ),

      // ───── TabBar ─────
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

      // ───── SnackBar, Chip, Divider, BottomSheet, ListTile ─────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.surface),
        shape: roundedShape,
      ),

      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: scheme.primary.withValues(alpha: .12),
        backgroundColor: scheme.surfaceContainerLow,
        labelStyle: textTheme.labelLarge,
      ),

      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: scheme.outlineVariant.withValues(alpha: .6),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: scheme.surface,
        showDragHandle: true,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: roundedShape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: scheme.surface,
      ),
    );
  }

  // ────────────────────────────── TextTheme ──────────────────────────────
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

  // ────────────────────────────── InputDecorationTheme ──────────────────────────────
  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .6),
        ),
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