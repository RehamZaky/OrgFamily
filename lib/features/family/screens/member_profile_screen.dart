import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_photo_store.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/responsibilities_table.dart';
import '../../../data/providers.dart';
import '../providers/family_providers.dart';
import '../providers/responsibility_providers.dart';
import 'add_member_screen.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key, required this.member});

  final FamilyMember member;

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  final _statsKey = GlobalKey();

  void _scrollToStats() {
    final ctx = _statsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    }
  }

  Future<void> _changePhoto() async {
    final path = await pickAndSaveAvatarPhoto(
        context: context, memberId: widget.member.id);
    if (path == null) return;
    await ref
        .read(familyRepositoryProvider)
        .updateMember(widget.member.copyWith(photoPath: Value(path)));
  }

  Future<void> _addResponsibility() async {
    final result = await showModalBottomSheet<_NewResponsibility>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddResponsibilitySheet(),
    );
    if (result == null) return;
    await ref.read(responsibilityRepositoryProvider).addResponsibility(
          id: const Uuid().v4(),
          memberId: widget.member.id,
          title: result.title,
          recurrence: result.recurrence,
          customWeekdays: result.customWeekdays,
        );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final me = ref.watch(currentMemberProvider);
    final isYou = member.id == me?.id;
    final birthday = member.birthday;
    final pointsByMember = ref.watch(familyPointsThisWeekProvider);
    final tasksDone = ref.watch(tasksDoneThisWeekForMemberProvider(member.id));
    final tasksPending = ref.watch(tasksPendingForMemberProvider(member.id));
    final points = pointsByMember[member.id] ?? 0;
    final responsibilities =
        ref.watch(responsibilitiesForMemberProvider(member.id)).valueOrNull ??
            [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddMemberScreen(existing: member),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MemberAvatar(member: member, radius: 56),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _changePhoto,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                isYou ? '${member.name} (You)' : member.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                birthday != null ? '${birthday.ageInYears} years old' : member.role.label,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.star_rounded,
                    label: 'Points',
                    onTap: _scrollToStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.event_note_outlined,
                    label: 'Schedule',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _MemberScheduleScreen(member: member),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('About ${member.name}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddMemberScreen(existing: member),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _AboutRow(icon: Icons.badge_outlined, label: 'Role', value: member.role.label),
                    _AboutRow(
                      icon: Icons.cake_outlined,
                      label: 'Birthday',
                      value: birthday != null
                          ? DateFormat('MMM d, y').format(birthday)
                          : 'Not set',
                    ),
                    if ((member.grade ?? '').isNotEmpty)
                      _AboutRow(icon: Icons.school_outlined, label: 'Grade', value: member.grade!),
                    if ((member.school ?? '').isNotEmpty)
                      _AboutRow(icon: Icons.apartment_outlined, label: 'School', value: member.school!),
                    _AboutRow(
                      icon: Icons.palette_outlined,
                      label: 'Favorite color',
                      value: '',
                      trailing: CircleAvatar(
                          radius: 9, backgroundColor: Color(member.colorValue)),
                    ),
                    if ((member.notes ?? '').isNotEmpty)
                      _AboutRow(icon: Icons.notes_outlined, label: 'Notes', value: member.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(key: _statsKey),
            const Text('This Week',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTile(
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      value: '$tasksDone',
                      label: 'Tasks Done',
                    ),
                    _StatTile(
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.priorityNormal,
                      value: '$tasksPending',
                      label: 'Task Pending',
                    ),
                    _StatTile(
                      icon: Icons.star_rounded,
                      color: AppColors.info,
                      value: '$points',
                      label: 'Points',
                    ),
                    const _StatTile(
                      icon: Icons.flag_outlined,
                      color: AppColors.primary,
                      value: '—',
                      label: 'Goal Contributed',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Responsibility',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: _addResponsibility,
                ),
              ],
            ),
            if (responsibilities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No responsibilities yet')),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < responsibilities.length; i++) ...[
                      _ResponsibilityRow(responsibility: responsibilities[i]),
                      if (i != responsibilities.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          const Spacer(),
          trailing ?? Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _ResponsibilityRow extends ConsumerWidget {
  const _ResponsibilityRow({required this.responsibility});

  final Responsibility responsibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneToday = responsibility.lastCompletedDate?.isToday ?? false;
    return ListTile(
      leading: Checkbox(
        value: doneToday,
        onChanged: (checked) => ref
            .read(responsibilityRepositoryProvider)
            .setCompletedToday(responsibility.id, checked ?? false),
      ),
      title: Text(
        responsibility.title,
        style: TextStyle(
          decoration: doneToday ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(responsibilityScheduleLabel(responsibility)),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: context.colors.textSecondary),
        onPressed: () => ref
            .read(responsibilityRepositoryProvider)
            .deleteResponsibility(responsibility.id),
      ),
    );
  }
}

class _NewResponsibility {
  _NewResponsibility(this.title, this.recurrence, this.customWeekdays);

  final String title;
  final ResponsibilityRecurrence recurrence;
  final List<int>? customWeekdays;
}

class _AddResponsibilitySheet extends StatefulWidget {
  const _AddResponsibilitySheet();

  @override
  State<_AddResponsibilitySheet> createState() => _AddResponsibilitySheetState();
}

class _AddResponsibilitySheetState extends State<_AddResponsibilitySheet> {
  final _titleController = TextEditingController();
  ResponsibilityRecurrence _recurrence = ResponsibilityRecurrence.daily;
  final Set<int> _customWeekdays = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('New responsibility',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Make bed'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          const Text('Repeats', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Daily'),
                selected: _recurrence == ResponsibilityRecurrence.daily,
                onSelected: (_) =>
                    setState(() => _recurrence = ResponsibilityRecurrence.daily),
              ),
              ChoiceChip(
                label: const Text('Every school day'),
                selected: _recurrence == ResponsibilityRecurrence.schoolDays,
                onSelected: (_) => setState(
                    () => _recurrence = ResponsibilityRecurrence.schoolDays),
              ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: _recurrence == ResponsibilityRecurrence.custom,
                onSelected: (_) =>
                    setState(() => _recurrence = ResponsibilityRecurrence.custom),
              ),
            ],
          ),
          if (_recurrence == ResponsibilityRecurrence.custom) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekdayNames.entries.map((e) {
                final selected = _customWeekdays.contains(e.key);
                return FilterChip(
                  label: Text(e.value.substring(0, 3)),
                  selected: selected,
                  onSelected: (checked) => setState(() {
                    if (checked) {
                      _customWeekdays.add(e.key);
                    } else {
                      _customWeekdays.remove(e.key);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              if (_recurrence == ResponsibilityRecurrence.custom &&
                  _customWeekdays.isEmpty) {
                return;
              }
              Navigator.of(context).pop(_NewResponsibility(
                title,
                _recurrence,
                _recurrence == ResponsibilityRecurrence.custom
                    ? (_customWeekdays.toList()..sort())
                    : null,
              ));
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

const _weekdayNames = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// A lightweight read-only view of this member's upcoming tasks and events —
/// event editing doesn't exist yet (see roadmap V1.1), so rows here aren't
/// tappable.
class _MemberScheduleScreen extends ConsumerWidget {
  const _MemberScheduleScreen({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text("${member.name}'s Schedule")),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
