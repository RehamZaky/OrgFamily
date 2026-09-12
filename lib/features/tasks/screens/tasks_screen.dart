import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/no_results_animation.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../domain/task_status_calculator.dart';
import '../providers/task_providers.dart';
import 'task_form_screen.dart';

enum _TaskTab { today, upcoming, all, completed }

bool _isFutureDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  return day.isAfter(today);
}

bool _isOverdue(Task t) => isTaskOverdue(TaskDeadlineInput.fromTask(t), DateTime.now());

/// Which permission covers toggling [task]'s completion for whoever the app
/// is currently "acting as" — their own task vs someone else's.
FamilyAction _completeAction(Task task, WidgetRef ref) {
  final activeId = ref.read(activeMemberIdProvider);
  final isOwnTask = activeId != null && task.assigneeId == activeId;
  return isOwnTask ? FamilyAction.completeOwnTask : FamilyAction.completeAnyTask;
}

/// Which permission covers moving [task]'s due date via the "Tomorrow"
/// quick action — a lighter bar than general editing when it's your own
/// task, matching [taskUpdateAction] (used by the full editor for the same
/// distinction).
FamilyAction _rescheduleAction(Task task, WidgetRef ref) {
  final activeId = ref.read(activeMemberIdProvider);
  final isOwnTask = activeId != null && task.assigneeId == activeId;
  return isOwnTask ? FamilyAction.rescheduleOwnTask : FamilyAction.editAnyTask;
}

/// Deleting a task isn't resolved through the flat role matrix (see
/// [canDeleteTask]) — only the creator or Owner can, regardless of
/// Adult/Child. Pre-checks here so a denied swipe never even animates.
bool _checkDeletePermission(BuildContext context, WidgetRef ref, Task task) {
  final role = ref.read(activeRoleProvider);
  final memberId = ref.read(activeMemberIdProvider);
  if (canDeleteTask(task, role, memberId)) return true;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.permissionDenied(role.label))),
  );
  return false;
}

String _overdueLabel(AppLocalizations l10n, Task t) {
  final days = daysOverdue(TaskDeadlineInput.fromTask(t), DateTime.now());
  if (days == 0) return l10n.overdueToday;
  if (days == 1) return l10n.overdueYesterday;
  return l10n.overdueByDays(days);
}

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _searching = false;
  String _query = '';
  TaskCategory? _categoryFilter;
  String? _assigneeFilter;
  _TaskTab _tab = _TaskTab.today;
  static const _unassignedSentinel = '__unassigned__';

  bool get _hasFilters => _categoryFilter != null || _assigneeFilter != null;

  static const _allCategoriesSentinel = '__all__';

  Future<void> _pickCategoryFilter() async {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.labelCategory,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: Text(l10n.allCategories),
                    trailing: _categoryFilter == null
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_allCategoriesSentinel),
                  ),
                  ...TaskCategory.values.map((c) => ListTile(
                        leading: Icon(c.icon, color: c.color),
                        title: Text(c.label(l10n)),
                        trailing: c == _categoryFilter
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(c.name),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _categoryFilter = result == _allCategoriesSentinel
          ? null
          : TaskCategory.values.byName(result);
    });
  }

  Future<void> _pickAssigneeFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
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
                child: Text(l10n.labelAssignedTo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(l10n.everyone),
              trailing: _assigneeFilter == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            ListTile(
              leading: const MemberAvatar(),
              title: Text(l10n.unassigned),
              trailing: _assigneeFilter == _unassignedSentinel
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(_unassignedSentinel),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  trailing: m.id == _assigneeFilter
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _assigneeFilter = result.isEmpty ? null : result);
  }

  bool _matchesTab(Task t) {
    switch (_tab) {
      case _TaskTab.today:
        // Undated tasks (the common case from Quick Add, which doesn't ask
        // for a date) have no better default home than "what needs doing
        // now" — hiding them here would make them effectively invisible.
        // Overdue tasks belong here too, however old their due date is —
        // "needs attention" doesn't stop being true just because it's been
        // a few days.
        if (t.isCompleted) return false;
        return t.dueDate == null || t.dueDate!.isToday || _isOverdue(t);
      case _TaskTab.upcoming:
        return !t.isCompleted && t.dueDate != null && _isFutureDay(t.dueDate!);
      case _TaskTab.all:
        return !t.isCompleted;
      case _TaskTab.completed:
        return t.isCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(allTasksProvider);
    final members = {
      for (final m in ref.watch(familyMembersProvider).valueOrNull ?? [])
        m.id: m
    };

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.tasksSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.navTasks),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? l10n.closeSearch : l10n.search,
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          IconButton(
            icon: Icon(_hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: _hasFilters ? AppColors.primary : null),
            tooltip: l10n.filter,
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(l10n.labelCategory),
                      subtitle:
                          Text(_categoryFilter?.label(l10n) ?? l10n.allCategories),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickCategoryFilter();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: Text(l10n.labelAssignedTo),
                      subtitle: Text(_assigneeFilter == null
                          ? l10n.everyone
                          : _assigneeFilter == _unassignedSentinel
                              ? l10n.unassigned
                              : members[_assigneeFilter]?.name ?? l10n.everyone),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAssigneeFilter();
                      },
                    ),
                    if (_hasFilters)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _categoryFilter = null;
                            _assigneeFilter = null;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.clearFilters),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                for (final tab in _TaskTab.values) ...[
                  Expanded(
                    child: _TabChip(
                      label: switch (tab) {
                        _TaskTab.today => l10n.today,
                        _TaskTab.upcoming => l10n.sectionUpcomingEvents,
                        _TaskTab.all => l10n.tasksTabAll,
                        _TaskTab.completed => l10n.completed,
                      },
                      selected: _tab == tab,
                      onTap: () => setState(() => _tab = tab),
                    ),
                  ),
                  if (tab != _TaskTab.values.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allTasks) {
                if (allTasks.isEmpty) {
                  return const _EmptyTasks();
                }
                final query = _query.trim().toLowerCase();
                final tasks = allTasks.where((t) {
                  if (query.isNotEmpty &&
                      !t.title.toLowerCase().contains(query) &&
                      !(t.description?.toLowerCase().contains(query) ?? false)) {
                    return false;
                  }
                  if (_categoryFilter != null && t.category != _categoryFilter) {
                    return false;
                  }
                  if (_assigneeFilter == _unassignedSentinel && t.assigneeId != null) {
                    return false;
                  }
                  if (_assigneeFilter != null &&
                      _assigneeFilter != _unassignedSentinel &&
                      t.assigneeId != _assigneeFilter) {
                    return false;
                  }
                  return _matchesTab(t);
                }).toList()
                  ..sort((a, b) {
                    final ad = a.dueDate;
                    final bd = b.dueDate;
                    if (ad == null && bd == null) return 0;
                    if (ad == null) return 1;
                    if (bd == null) return -1;
                    return ad.compareTo(bd);
                  });

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NoResultsAnimation(),
                        Text(l10n.noTasksMatch,
                            style: TextStyle(color: context.colors.textSecondary)),
                      ],
                    ),
                  );
                }

                // Overdue tasks always get their own leading section,
                // oldest-first (already true of `tasks`, sorted ascending
                // by due date) — regardless of tab, so "needs attention"
                // never blends into whatever bucket the due date would
                // otherwise land in.
                final overdueTasks = tasks.where(_isOverdue).toList();
                final restTasks = tasks.where((t) => !_isOverdue(t)).toList();

                // Today/Upcoming/Completed are already a single focused
                // bucket — only "All" benefits from being broken back down
                // by day, since it spans everything at once.
                if (_tab != _TaskTab.all) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    children: [
                      if (overdueTasks.isNotEmpty) ...[
                        _GroupHeader(
                            label: l10n.overdue, count: overdueTasks.length, accent: true),
                        for (final t in overdueTasks)
                          _TaskCard(task: t, member: members[t.assigneeId]),
                        const SizedBox(height: 12),
                      ],
                      for (final t in restTasks)
                        _TaskCard(task: t, member: members[t.assigneeId]),
                    ],
                  );
                }

                final today = <Task>[];
                final tomorrow = <Task>[];
                final later = <Task>[];
                for (final t in restTasks) {
                  final d = t.dueDate;
                  if (d != null && d.isToday) {
                    today.add(t);
                  } else if (d != null && d.isTomorrow) {
                    tomorrow.add(t);
                  } else {
                    later.add(t);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  children: [
                    if (overdueTasks.isNotEmpty) ...[
                      _GroupHeader(
                          label: l10n.overdue, count: overdueTasks.length, accent: true),
                      for (final t in overdueTasks)
                        _TaskCard(task: t, member: members[t.assigneeId]),
                      const SizedBox(height: 12),
                    ],
                    if (today.isNotEmpty) ...[
                      _GroupHeader(label: l10n.today, count: today.length),
                      for (final t in today)
                        _TaskCard(task: t, member: members[t.assigneeId]),
                      const SizedBox(height: 12),
                    ],
                    if (tomorrow.isNotEmpty) ...[
                      _GroupHeader(label: l10n.tomorrow, count: tomorrow.length),
                      for (final t in tomorrow)
                        _TaskCard(task: t, member: members[t.assigneeId]),
                      const SizedBox(height: 12),
                    ],
                    if (later.isNotEmpty) ...[
                      _GroupHeader(label: l10n.later, count: later.length),
                      for (final t in later)
                        _TaskCard(task: t, member: members[t.assigneeId]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count, this.accent = false});

  final String label;
  final int count;

  /// Used only for the OVERDUE section header — red text, same weight and
  /// layout as every other group header otherwise, so it reads as "needs
  /// attention" rather than an alarm.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.priorityHigh : context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          Text('$count',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NoResultsAnimation(),
            const SizedBox(height: 12),
            Text(l10n.emptyNoTasksYet,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.tasksEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.member});

  final Task task;
  final FamilyMember? member;

  Future<void> _pickAssignee(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.taskFormAssignTo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    await ref.read(taskRepositoryProvider).updateTask(
          task.copyWith(assigneeId: drift.Value(result)),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overdue = !task.isCompleted && _isOverdue(task);
    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (checkPermission(context, ref, _completeAction(task, ref))) {
            ref.read(taskRepositoryProvider).setCompleted(
                  task.id,
                  !task.isCompleted,
                  actingRole: ref.read(activeRoleProvider),
                  actingMemberId: ref.read(activeMemberIdProvider),
                );
          }
          return false;
        }
        return _checkDeletePermission(context, ref, task);
      },
      onDismissed: (_) => ref.read(taskRepositoryProvider).deleteTask(
            task.id,
            actingRole: ref.read(activeRoleProvider),
            actingMemberId: ref.read(activeMemberIdProvider),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: task.isCompleted ? Colors.transparent : task.priority.color,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskFormScreen(existing: task)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!checkPermission(context, ref, _completeAction(task, ref))) {
                              return;
                            }
                            ref.read(taskRepositoryProvider).setCompleted(
                                  task.id,
                                  !task.isCompleted,
                                  actingRole: ref.read(activeRoleProvider),
                                  actingMemberId: ref.read(activeMemberIdProvider),
                                );
                          },
                          child: Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: task.isCompleted
                                ? AppColors.success
                                : context.colors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  decoration:
                                      task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted
                                      ? context.colors.textSecondary
                                      : context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(task.category.icon,
                                      size: 12, color: task.category.color),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      task.dueDate == null
                                          ? task.category.label(l10n)
                                          : overdue
                                              ? '${task.category.label(l10n)} • ${_overdueLabel(l10n, task)}'
                                              : '${task.category.label(l10n)} • ${task.dueDate!.relativeDayAndTime}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: overdue ? FontWeight.w700 : null,
                                          color: overdue
                                              ? AppColors.priorityHigh
                                              : context.colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              if (overdue) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    if (!checkPermission(
                                        context, ref, _rescheduleAction(task, ref))) {
                                      return;
                                    }
                                    ref.read(taskRepositoryProvider).rescheduleToTomorrow(
                                          task.id,
                                          actingRole: ref.read(activeRoleProvider),
                                          actingMemberId: ref.read(activeMemberIdProvider),
                                        );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 12, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Text(
                                        l10n.actionTomorrow,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        member != null
                            ? MemberAvatar(member: member, radius: 14)
                            : InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _pickAssignee(context, ref),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add,
                                          size: 12, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        l10n.quickAddTaskAssignShort,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
