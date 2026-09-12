import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/family/providers/family_providers.dart';
import '../../features/family/screens/member_profile_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/enum_display.dart';
import 'member_avatar.dart';

/// The app-wide navigation drawer — same content on every tab (Home, Tasks,
/// Calendar, Lists, Family), reached via the menu icon each Scaffold's
/// AppBar shows automatically once `drawer` is set.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// The drawer's "Switch profile" sheet — a soft, unprotected picker (see
  /// activeMemberIdProvider's doc comment): anyone can tap back to Owner,
  /// this just changes who the app treats as "you" for greetings and
  /// permission checks while it's set.
  Future<void> _pickProfile(BuildContext context, WidgetRef ref) async {
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    if (members.isEmpty) return;
    final currentId = ref.read(currentMemberProvider)?.id;
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
                color: Colors.grey.shade300,
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
                  subtitle: Text(m.role.label),
                  trailing: m.id == currentId
                      ? const Icon(Icons.check, color: AppColors.primary)
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
    final me = ref.watch(currentMemberProvider);

    return Drawer(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                  const SizedBox(height: 14),
                  Text(
                    me?.name ?? l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (me == null)
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    )
                  else
                    InkWell(
                      onTap: () => _pickProfile(context, ref),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            me.role.label,
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.unfold_more_rounded,
                              size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: l10n.drawerProfile,
                    color: AppColors.primary,
                    enabled: me != null,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => MemberProfileScreen(member: me!)),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: l10n.drawerSettings,
                    color: AppColors.info,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: l10n.drawerAbout,
                    color: AppColors.success,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
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
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.15 : 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: enabled ? color : Colors.grey),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
