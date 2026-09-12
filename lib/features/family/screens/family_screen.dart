import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../shopping/providers/shopping_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../providers/family_providers.dart';
import '../widgets/family_activity_feed.dart';
import 'add_member_screen.dart';
import 'member_profile_screen.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String memberId, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeMemberTitle),
        content: Text(l10n.removeMemberBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      if (!checkPermission(context, ref, FamilyAction.manageMembers)) return;
      await ref.read(familyRepositoryProvider).deleteMember(
            memberId,
            actingRole: ref.read(activeRoleProvider),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final me = ref.watch(currentMemberProvider);
    final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? [];
    final pointsByMember = ref.watch(familyPointsThisWeekProvider);
    final tasksDoneThisWeek = ref.watch(tasksDoneThisWeekProvider);
    final familyPoints = ref.watch(familyPointsTotalThisWeekProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) => CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0x14000000),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.primary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.ourFamily,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.ourFamilyTagline,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0x14000000),
                  child: Icon(Icons.notifications_none,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in members) ...[
                    _AvatarStripItem(
                      label: m.id == me?.id ? l10n.you : m.name,
                      isYou: m.id == me?.id,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MemberProfileScreen(member: m)),
                      ),
                      child: MemberAvatar(member: m, radius: 28),
                    ),
                    const SizedBox(width: 14),
                  ],
                  _AvatarStripItem(
                    label: l10n.addMember,
                    isYou: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddMemberScreen()),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.add, color: AppColors.primary, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryTile(
                      icon: Icons.groups_outlined,
                      color: AppColors.primary,
                      value: '${members.length}',
                      label: l10n.familySummaryMembers,
                    ),
                    _SummaryTile(
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      value: '$tasksDoneThisWeek',
                      label: l10n.familySummaryDoneThisWeek,
                    ),
                    _SummaryTile(
                      icon: Icons.star_rounded,
                      color: AppColors.priorityNormal,
                      value: '$familyPoints',
                      label: l10n.familySummaryPointsThisWeek,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.familyMembersHeading,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddMemberScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addMember),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(l10n.noFamilyMembersYet,
                        style: TextStyle(color: context.colors.textSecondary))),
              )
            else
              for (final m in members) ...[
                _MemberCard(
                  member: m,
                  isYou: m.id == me?.id,
                  tasksToday: tasks
                      .where((t) =>
                          t.assigneeId == m.id &&
                          !t.isCompleted &&
                          t.dueDate != null &&
                          _isToday(t.dueDate!))
                      .length,
                  // So "0 tasks today" (nothing assigned) reads differently
                  // from having finished everything that was — completing
                  // your last task for the day shouldn't look identical to
                  // never having had one.
                  tasksDoneToday: tasks
                      .where((t) =>
                          t.assigneeId == m.id &&
                          t.isCompleted &&
                          t.dueDate != null &&
                          _isToday(t.dueDate!))
                      .length,
                  points: pointsByMember[m.id] ?? 0,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MemberProfileScreen(member: m)),
                  ),
                  onLongPress: () => _confirmDelete(context, ref, m.id, m.name),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 16),
            Text(l10n.sectionFamilyActivity,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FamilyActivityFeed(tasks: tasks, lists: lists),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

class _AvatarStripItem extends StatelessWidget {
  const _AvatarStripItem({
    required this.child,
    required this.label,
    required this.isYou,
    required this.onTap,
  });

  final Widget child;
  final String label;
  final bool isYou;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                color: isYou ? AppColors.primary : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isYou,
    required this.tasksToday,
    required this.tasksDoneToday,
    required this.points,
    required this.onTap,
    required this.onLongPress,
  });

  final FamilyMember member;
  final bool isYou;
  final int tasksToday;
  final int tasksDoneToday;
  final int points;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pending tasks take priority (it's the actionable number); only once
    // there's nothing left pending do completed-today tasks get a look in,
    // so "all done" doesn't read the same as "nothing assigned."
    final taskLine = tasksToday > 0
        ? l10n.tasksTodayCount(tasksToday)
        : tasksDoneToday > 0
            ? l10n.tasksTodayAllDone(tasksDoneToday)
            : l10n.tasksTodayCount(0);
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              MemberAvatar(member: member, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isYou ? '${member.name} (${l10n.you})' : member.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(member.role.label,
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    const SizedBox(height: 3),
                    Text(
                      points > 0 ? '$taskLine • ${l10n.pointsShort(points)}' : taskLine,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
