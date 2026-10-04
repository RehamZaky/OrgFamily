import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/join_family_screen.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../family/providers/family_providers.dart';
import '../../family/screens/invite_family_member_screen.dart';
import '../widgets/sync_review_sheet.dart';
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
                const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                // Local family data and the cloud account are independent —
                // signing out only disconnects the cloud side, it never
                // clears the local family, so each gets its own status line
                // instead of one row that implies they're the same thing.
                // See docs/architecture.md "Family identity and authentication".
                Builder(
                  builder: (context) {
                    final memberCount =
                        ref.watch(familyMembersProvider).valueOrNull?.length ?? 0;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.storage_outlined, color: AppColors.primary),
                        title: const Text('Local family'),
                        subtitle: Text(
                          memberCount == 1
                              ? '1 member on this device · Available offline'
                              : '$memberCount members on this device · Available offline',
                        ),
                      ),
                    );
                  },
                ),
                if (isFirebaseAuthSupportedPlatform) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final user = ref.watch(authStateProvider).valueOrNull;
                      if (user == null) {
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off_outlined,
                                color: AppColors.textSecondary),
                            title: const Text('Cloud account'),
                            subtitle: const Text('Not connected'),
                            trailing: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignInScreen()),
                              ),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      }
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading:
                              const Icon(Icons.cloud_done_outlined, color: AppColors.priorityLow),
                          title: const Text('Cloud account'),
                          subtitle:
                              Text('${user.email ?? user.displayName ?? user.uid} · Connected'),
                          trailing: TextButton(
                            onPressed: () => ref.read(authRepositoryProvider).signOut(),
                            child: const Text('Disconnect'),
                          ),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      if (ref.watch(cloudAccessProvider) == CloudAccess.notMember) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: Icon(Icons.cloud_off_outlined,
                                  color: AppColors.priorityNormal),
                              title: Text(l10n.cloudNotMemberTitle),
                              subtitle: Text(l10n.cloudNotMemberBody),
                              trailing: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const JoinFamilyScreen(),
                                  ),
                                ),
                                child: Text(l10n.cloudNotMemberAction),
                              ),
                            ),
                          ),
                        );
                      }
                      final isActive = ref.watch(isCloudSyncActiveProvider);
                      if (!isActive) return const SizedBox.shrink();
                      final summary = ref.watch(syncOutboxSummaryProvider).valueOrNull;
                      final failed = summary?.failed ?? 0;
                      final pending = summary?.pending ?? 0;
                      final listenerError = ref.watch(syncListenerErrorProvider).valueOrNull;
                      final upToDate = failed == 0 && pending == 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: Icon(
                              failed > 0 || listenerError != null
                                  ? Icons.cloud_off_outlined
                                  : Icons.cloud_sync_outlined,
                              color: failed > 0 || listenerError != null
                                  ? AppColors.priorityUrgent
                                  : AppColors.primary,
                            ),
                            title: const Text('Cloud sync'),
                            subtitle: Text(
                              failed > 0
                                  ? '$failed change${failed == 1 ? '' : 's'} need attention'
                                  : listenerError != null
                                      ? l10n.syncListenerError(listenerError)
                                      : upToDate
                                          ? 'Up to date'
                                          : '$pending change${pending == 1 ? '' : 's'} syncing',
                            ),
                            trailing: (failed > 0 || pending > 0)
                                ? TextButton(
                                    onPressed: () => failed > 0
                                        ? ref.read(syncEngineProvider).retryFailed()
                                        : ref.read(syncEngineProvider).drainNow(),
                                    child: const Text('Retry'),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final summary = ref.watch(syncOutboxSummaryProvider).valueOrNull;
                      if (summary == null || summary.review.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.rule_folder_outlined,
                                color: AppColors.priorityNormal),
                            title: Text(l10n.syncReviewTitle(summary.reviewCount)),
                            subtitle: Text(l10n.syncReviewBody),
                            trailing: TextButton(
                              onPressed: () => showSyncReviewSheet(context),
                              child: Text(l10n.syncReviewAction),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final isActive = ref.watch(isCloudSyncActiveProvider);
                      if (!isActive) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.person_add_outlined,
                                color: AppColors.primary),
                            title: const Text('Invite a family member'),
                            subtitle: const Text(
                              'Generate a code for another adult to join on their own device',
                            ),
                            trailing: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InviteFamilyMemberScreen(),
                                ),
                              ),
                              child: const Text('Invite'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
