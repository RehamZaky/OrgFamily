import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove family member?'),
        content: Text('$name will be removed from your family.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(familyRepositoryProvider).deleteMember(memberId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final me = ref.watch(currentMemberProvider);
    final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? [];
    final pointsByMember = ref.watch(familyPointsThisWeekProvider);
    final tasksDoneThisWeek = ref.watch(tasksDoneThisWeekProvider);
    final familyPoints = ref.watch(familyPointsTotalThisWeekProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_add_member',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddMemberScreen()),
        ),
        child: const Icon(Icons.person_add_alt_1),
      ),
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
                      const Text('Our Family',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Together we organize, plan and make every day better 💜',
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
            if (members.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
              Container(
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < members.take(4).length; i++)
                      Align(
                        alignment: Alignment(
                            -1 + i * (2 / (members.take(4).length - 1).clamp(1, 4)),
                            0),
                        child: MemberAvatar(member: members[i], radius: 28),
                      ),
                  ],
                ),
              ),
              ),
            ],
        
            const SizedBox(height: 24),
            const Text('Family Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryTile(
                      icon: Icons.groups_outlined,
                      color: AppColors.primary,
                      value: '${members.length}',
                      label: 'Members',
                    ),
                    _SummaryTile(
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      value: '$tasksDoneThisWeek',
                      label: 'Tasks Done\nThis Week',
                    ),
                    _SummaryTile(
                      icon: Icons.star_rounded,
                      color: AppColors.priorityNormal,
                      value: '$familyPoints',
                      label: 'Family Points\nThis Week',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Family Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No family members yet')),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < members.length; i++) ...[
                      _MemberRow(
                        member: members[i],
                        isYou: members[i].id == me?.id,
                        points: pointsByMember[members[i].id] ?? 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MemberProfileScreen(member: members[i]),
                          ),
                        ),
                        onLongPress: () => _confirmDelete(
                            context, ref, members[i].id, members[i].name),
                      ),
                      if (i != members.length - 1) const Divider(height: 1, indent: 68),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text('Family Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isYou,
    required this.points,
    required this.onTap,
    required this.onLongPress,
  });

  final FamilyMember member;
  final bool isYou;
  final int points;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final birthday = member.birthday;
    final subtitle = birthday != null
        ? '${birthday.ageInYears} years old'
        : member.role.label;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: MemberAvatar(member: member, radius: 22),
      title: Text(
        isYou ? '${member.name} (You)' : member.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$points pts',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.primary)),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
