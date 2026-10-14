import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../features/family/insights/family_insights_screen.dart';
import '../../features/family/providers/family_providers.dart';
import '../../features/family/screens/family_activity_screen.dart';
import '../../features/family/screens/invite_family_member_screen.dart';
import '../../features/family/screens/member_profile_screen.dart';
import '../../features/family/screens/my_responsibilities_screen.dart';
import '../../features/reminders/my_reminders_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../utils/enum_display.dart';
import 'member_avatar.dart';

/// The app-wide navigation drawer — same content on every tab (Home, Tasks,
/// Calendar, Lists, Family), reached via the menu icon each Scaffold's
/// AppBar shows automatically once `drawer` is set. A compact header, then
/// three groups (V2.3): My space, Family, App — the list scrolls on small
/// phones.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// Share of the screen width the drawer takes, and its widest (tablets).
  static const drawerWidthFraction = 0.86;
  static const drawerMaxWidth = 360.0;

  /// The drawer's "Switch profile" sheet — a soft, unprotected picker (see
  /// actingMemberProvider's doc comment): anyone can tap back to Owner,
  /// this just changes who the app treats as "you" for greetings and
  /// permission checks while it's set.
  Future<void> _pickProfile(BuildContext context, WidgetRef ref) async {
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    if (members.isEmpty) return;
    final currentId = ref.read(actingMemberProvider)?.id;
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.drawerSwitchProfile,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  subtitle: Text(m.role.labelIn(context)),
                  trailing: m.id == currentId
                      ? Icon(Icons.check, color: context.colors.accent)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) await setActiveMember(ref, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(actingMemberProvider);

    return Drawer(
      // 86% of the screen, so the page behind stays visible — capped for
      // tablets at Material's standard drawer width.
      width: (MediaQuery.sizeOf(context).width * drawerWidthFraction)
          .clamp(0, drawerMaxWidth)
          .toDouble(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.colors.heroGradient,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/onboarding/drawer.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me?.name ?? l10n.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (me == null)
                          Text(
                            l10n.appTitle,
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          )
                        else
                          InkWell(
                            onTap: () => _pickProfile(context, ref),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    me.role.labelIn(context),
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.unfold_more_rounded,
                                      size: 14, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                children: [
                  _DrawerGroupLabel(l10n.drawerGroupMySpace),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: l10n.drawerProfile,
                    color: context.colors.accent,
                    enabled: me != null,
                    onTap: () => _open(context, MemberProfileScreen(member: me!)),
                  ),
                  _DrawerItem(
                    icon: Icons.task_alt,
                    label: l10n.homeMyResponsibilities,
                    color: context.colors.success,
                    onTap: () => _open(context, const MyResponsibilitiesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_none_rounded,
                    label: l10n.remindersTitle,
                    color: context.colors.warning,
                    onTap: () => _open(context, const MyRemindersScreen()),
                  ),
                  const _DrawerDivider(),
                  _DrawerGroupLabel(l10n.drawerGroupFamily),
                  _DrawerItem(
                    icon: Icons.timeline_rounded,
                    label: l10n.sectionFamilyActivity,
                    color: context.colors.warning,
                    onTap: () => _open(context, const FamilyActivityScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.insights_rounded,
                    label: l10n.insightsTitle,
                    color: AppColors.info,
                    onTap: () => _open(context, const FamilyInsightsScreen()),
                  ),
                  // Same rule as Settings → Account: an invite needs a
                  // synced family this account belongs to.
                  if (ref.watch(cloudAccessProvider) == CloudAccess.member)
                    _DrawerItem(
                      icon: Icons.person_add_alt_1_outlined,
                      label: l10n.drawerInviteMember,
                      color: context.colors.accent,
                      onTap: () => _open(context, const InviteFamilyMemberScreen()),
                    ),
                  const _DrawerDivider(),
                  _DrawerGroupLabel(l10n.drawerGroupApp),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: l10n.drawerSettings,
                    color: AppColors.info,
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: l10n.helpTitle,
                    color: context.colors.accent,
                    onTap: () => _open(context, const HelpScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: l10n.drawerAbout,
                    color: context.colors.success,
                    onTap: () => _open(context, const AboutScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group's small heading ("My space", "Family", "App").
class _DrawerGroupLabel extends StatelessWidget {
  const _DrawerGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 12, indent: 20, endIndent: 20, color: context.colors.border);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.15 : 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: enabled ? color : context.colors.textSecondary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

/// Closes the drawer, then opens [screen] — every drawer destination.
void _open(BuildContext context, Widget screen) {
  Navigator.of(context).pop();
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
