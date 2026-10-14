import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/settings_group.dart';
import 'money_guide_screen.dart';

/// Drawer → Help & support (V2.3): common questions, answered in the app
/// (EN/AR), plus the Money guide. No contact channel yet.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = [
      (Icons.swap_horiz_rounded, l10n.helpSwitchProfileQ, l10n.helpSwitchProfileA),
      (Icons.person_add_alt_1_outlined, l10n.helpInviteQ, l10n.helpInviteA),
      (Icons.admin_panel_settings_outlined, l10n.helpRolesQ, l10n.helpRolesA),
      (Icons.task_alt, l10n.helpResponsibilitiesQ, l10n.helpResponsibilitiesA),
      (Icons.notifications_off_outlined, l10n.helpRemindersQ, l10n.helpRemindersA),
      (Icons.cloud_sync_outlined, l10n.helpOfflineQ, l10n.helpOfflineA),
      (Icons.lock_outline, l10n.helpMoneyQ, l10n.helpMoneyA),
      (Icons.translate, l10n.helpLanguageQ, l10n.helpLanguageA),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SettingsSectionHeader(l10n.helpFaqHeader),
          SettingsGroup(
            children: [
              for (final (icon, question, answer) in faqs)
                _Faq(icon: icon, question: question, answer: answer),
            ],
          ),
          SettingsSectionHeader(l10n.helpGuidesHeader),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.menu_book_outlined,
                color: context.colors.accent,
                title: l10n.settingsMoneyGuide,
                subtitle: l10n.settingsMoneyGuideHint,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MoneyGuideScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.icon, required this.question, required this.answer});

  final IconData icon;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // No ExpansionTile borders — the group already draws the dividers.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: SettingsIcon(icon, color: context.colors.accent),
        title: Text(question, style: SettingsText.title(context)),
        tilePadding: const EdgeInsetsDirectional.only(start: 14, end: 10),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(answer, style: SettingsText.subtitle(context))],
      ),
    );
  }
}
