import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware colors — everything that must differ between light and dark.
///
/// Screens should read these via `context.colors` instead of hard-coding
/// light-theme values (`Colors.grey.shade300` borders, `AppColors.primary`
/// text, etc.), which is what made the dark theme look like a patchwork of
/// competing backgrounds and bright outlines. Fixed brand colors that stay
/// the same in both themes (category/avatar palettes, the solid
/// [AppColors.primary] *fill* behind white content) still live in
/// [AppColors].
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.border,
    required this.borderSubtle,
    required this.track,
    required this.heroGradient,
    required this.heroCardGradient,
    required this.onHeroSecondary,
    required this.navBackground,
    required this.navDivider,
    required this.success,
    required this.danger,
    required this.warning,
  });

  /// Every screen's background.
  final Color background;

  /// Cards, sheets, list tiles.
  final Color surface;

  /// One step above [surface] — dialogs, selected panels, unselected chip
  /// fills.
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;

  /// Purple used as a *foreground* — icons, links, active labels, focus
  /// rings. Lighter than [AppColors.primary] in dark mode so it keeps
  /// contrast against dark surfaces.
  final Color accent;

  /// Outlines that need to be visible (input fields, outlined chips).
  final Color border;

  /// Outlines on content cards — barely-there in light, none in dark (the
  /// surface-vs-background step separates them instead).
  final Color borderSubtle;

  /// Empty part of progress bars.
  final Color track;

  /// Large purple areas — Home header, balance card, drawer header.
  final List<Color> heroGradient;

  /// Cards carrying headline numbers in white (the Money balance card) —
  /// solid brand purple in light, the same deep gradient as [heroGradient]
  /// in dark.
  final List<Color> heroCardGradient;

  /// Secondary text on top of [heroGradient].
  final Color onHeroSecondary;

  final Color navBackground;
  final Color navDivider;

  /// Income, completed.
  final Color success;

  /// Expenses, overdue.
  final Color danger;

  /// Upcoming reminders, approaching limits.
  final Color warning;

  static const light = AppColorScheme(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: Color(0xFFF5F5F5),
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    accent: AppColors.primary,
    border: Color(0xFFE0E0E0),
    borderSubtle: Color(0xFFEEEEEE),
    track: Color(0xFFEEEEEE),
    heroGradient: [AppColors.primaryLight, AppColors.primary],
    heroCardGradient: [AppColors.primary, AppColors.primary],
    onHeroSecondary: Colors.white70,
    navBackground: AppColors.surface,
    navDivider: Colors.transparent,
    success: AppColors.success,
    danger: AppColors.priorityUrgent,
    warning: AppColors.priorityNormal,
  );

  /// Charcoal-and-lavender dark palette.
  static const dark = AppColorScheme(
    background: Color(0xFF14121C),
    surface: Color(0xFF242130),
    surfaceElevated: Color(0xFF302B40),
    textPrimary: Color(0xFFF5F2FA),
    textSecondary: Color(0xFFB9B2CA),
    accent: Color(0xFFA78BFA),
    border: Color(0xFF464052),
    borderSubtle: Colors.transparent,
    track: Color(0xFF302B40),
    heroGradient: [Color(0xFF6D55D9), Color(0xFF3A2E7A)],
    heroCardGradient: [Color(0xFF6D55D9), Color(0xFF3A2E7A)],
    onHeroSecondary: Color(0xE6FFFFFF),
    navBackground: Color(0xFF14121C),
    navDivider: Color(0xFF2E2A3A),
    success: Color(0xFF5ED6A0),
    danger: Color(0xFFFF777D),
    warning: Color(0xFFFFBC70),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? border,
    Color? borderSubtle,
    Color? track,
    List<Color>? heroGradient,
    List<Color>? heroCardGradient,
    Color? onHeroSecondary,
    Color? navBackground,
    Color? navDivider,
    Color? success,
    Color? danger,
    Color? warning,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      track: track ?? this.track,
      heroGradient: heroGradient ?? this.heroGradient,
      heroCardGradient: heroCardGradient ?? this.heroCardGradient,
      onHeroSecondary: onHeroSecondary ?? this.onHeroSecondary,
      navBackground: navBackground ?? this.navBackground,
      navDivider: navDivider ?? this.navDivider,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorScheme(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      track: l(track, other.track),
      heroGradient: [
        for (var i = 0; i < heroGradient.length; i++)
          l(heroGradient[i], other.heroGradient[i]),
      ],
      heroCardGradient: [
        for (var i = 0; i < heroCardGradient.length; i++)
          l(heroCardGradient[i], other.heroCardGradient[i]),
      ],
      onHeroSecondary: l(onHeroSecondary, other.onHeroSecondary),
      navBackground: l(navBackground, other.navBackground),
      navDivider: l(navDivider, other.navDivider),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
    );
  }
}

extension AppColorSchemeX on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}
