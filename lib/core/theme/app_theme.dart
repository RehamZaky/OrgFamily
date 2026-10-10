import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        colors: AppColorScheme.light,
        fabBackground: AppColors.primary,
        fabForeground: Colors.white,
        dialogBackground: AppColorScheme.light.surface,
      );

  static ThemeData get dark {
    const c = AppColorScheme.dark;
    // Every surface role pinned to the one charcoal palette, so Material
    // widgets that pick their own container color (bottom sheets, menus,
    // chips, date pickers) don't introduce extra competing backgrounds.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: c.accent,
      onPrimary: const Color(0xFF1A1430),
      primaryContainer: const Color(0xFF6D55D9),
      onPrimaryContainer: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceElevated,
      surfaceContainerHighest: c.surfaceElevated,
      outline: c.border,
      outlineVariant: c.border,
      error: c.danger,
      surfaceTint: Colors.transparent,
    );
    return _build(
      colorScheme: scheme,
      colors: c,
      fabBackground: c.accent,
      fabForeground: scheme.onPrimary,
      dialogBackground: c.surfaceElevated,
      dividerColor: c.navDivider,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppColorScheme colors,
    required Color fabBackground,
    required Color fabForeground,
    required Color dialogBackground,
    Color? dividerColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Roboto',
      extensions: [colors],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        bodyMedium: TextStyle(color: colors.textPrimary),
        bodySmall: TextStyle(color: colors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
      ),
      dividerTheme: DividerThemeData(color: dividerColor),
      drawerTheme: DrawerThemeData(backgroundColor: colors.surface),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBackground,
        foregroundColor: fabForeground,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.navBackground,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
