import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../l10n/app_localizations.dart';
import 'money_guide_screen.dart';

/// A sentinel distinct from any real [Locale] to represent "follow system"
/// in the segmented button, since its value type can't be nullable.
const _systemLocale = Locale('system');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      // The banner sits in a Column below the scrollable body, matching
      // every other screen that shows one (root_scaffold.dart) — wiring it
      // through Scaffold.bottomNavigationBar instead let the ad's native
      // platform view take over the whole body's layout once it loaded.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                Text(l10n.settingsAppearance,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(l10n.settingsThemeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(l10n.settingsThemeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.settings_suggest_outlined),
                      label: Text(l10n.settingsThemeSystem),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).state = s.first,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsThemeSystemHint,
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 28),
                Text(l10n.settingsLanguage,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment(
                      value: const Locale('en'),
                      label: Text(l10n.settingsLanguageEnglish),
                    ),
                    ButtonSegment(
                      value: const Locale('ar'),
                      label: Text(l10n.settingsLanguageArabic),
                    ),
                    ButtonSegment(
                      value: _systemLocale,
                      label: Text(l10n.settingsLanguageSystem),
                    ),
                  ],
                  selected: {locale ?? _systemLocale},
                  onSelectionChanged: (s) {
                    final selected = s.first;
                    ref.read(localeProvider.notifier).state =
                        selected == _systemLocale ? null : selected;
                  },
                ),
                const SizedBox(height: 28),
                Text(l10n.navBudget, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                    title: Text(l10n.settingsMoneyGuide),
                    subtitle: Text(l10n.settingsMoneyGuideHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MoneyGuideScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
