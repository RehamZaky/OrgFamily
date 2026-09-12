import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_photo_store.dart';
import '../../../core/utils/date_format_x.dart' show DateFormatX;
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/header_wave_clipper.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/providers/event_providers.dart';
import '../../calendar/screens/event_form_screen.dart';
import '../../family/providers/family_providers.dart';
import '../../family/widgets/family_activity_feed.dart';
import '../../notes/providers/note_providers.dart';
import '../../notes/screens/note_form_screen.dart';
import '../../shopping/providers/shopping_providers.dart';
import '../../shopping/screens/list_detail_screen.dart';
import '../../tasks/domain/task_status_calculator.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/screens/task_form_screen.dart';

String _overdueLabel(AppLocalizations l10n, Task task) {
  final days = daysOverdue(TaskDeadlineInput.fromTask(task), DateTime.now());
  if (days == 0) return l10n.overdueToday;
  if (days == 1) return l10n.overdueYesterday;
  return l10n.overdueByDays(days);
}

bool _isToday(DateTime dt) {
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

bool _isTomorrow(DateTime dt) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return dt.year == tomorrow.year &&
      dt.month == tomorrow.month &&
      dt.day == tomorrow.day;
}

String _relativeDayAndTime(BuildContext context, AppLocalizations l10n, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  final day = _isToday(dt)
      ? l10n.today
      : _isTomorrow(dt)
          ? l10n.tomorrow
          : DateFormat('EEEE', locale).format(dt);
  final time = DateFormat('h:mm a', locale).format(dt);
  return '$day • $time';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onViewTasks,
    this.onViewEvents,
    this.onViewLists,
  });

  final VoidCallback? onViewTasks;
  final VoidCallback? onViewEvents;
  final VoidCallback? onViewLists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // RootScaffold already gates on no-members-yet and shows OnboardingScreen
    // full-screen before this widget is ever built, so `members` here is
    // always non-empty.
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final me = ref.watch(currentMemberProvider);

    final allTasks = ref.watch(allTasksProvider).valueOrNull ?? [];
    final todayTasks = allTasks.where((t) => t.dueDate?.isToday ?? false).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.priority.index.compareTo(b.priority.index);
      });
    // Overdue tasks surface here regardless of their original due date, so
    // "needs attention" is never buried behind whatever else is due today —
    // and never shown twice, since a task due today that's now overdue (a
    // timed task whose time already passed) only appears in this list.
    final overdueTasks = allTasks.where((t) =>
        !t.isCompleted && isTaskOverdue(TaskDeadlineInput.fromTask(t), DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final todayNotOverdue = todayTasks.where((t) => !overdueTasks.contains(t)).toList();
    // At most 4 rows total in the "Today's priorities" card — overdue
    // first (it needs attention most), today's remaining tasks filling
    // whatever's left. "View all" is right there for the rest.
    final visibleOverdue = overdueTasks.take(4).toList();
    final visibleToday = todayNotOverdue.take(4 - visibleOverdue.length).toList();

    final events = ref.watch(allEventsProvider).valueOrNull ?? [];
    final upcomingEvents = ref.watch(upcomingEventsProvider).valueOrNull ?? [];
    final eventsToday = events.where((e) => e.startAt.isToday).length;
    final eventMembers = ref.watch(allEventMembersProvider).valueOrNull ?? {};

    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? [];
    // Prefer whichever list actually has items over a blank "first" list —
    // e.g. an unused default "Grocery" list shouldn't crowd out a list the
    // family is actually using.
    final listsWithItems = [
      for (final list in lists)
        (list, ref.watch(shoppingItemsProvider(list.id)).valueOrNull ?? <ShoppingItem>[]),
    ];
    final primaryEntry = listsWithItems.where((e) => e.$2.isNotEmpty).firstOrNull ??
        listsWithItems.firstOrNull;
    final primaryList = primaryEntry?.$1;
    final primaryItems = primaryEntry?.$2 ?? <ShoppingItem>[];
    final pendingItems = primaryItems.where((i) => !i.isPurchased).toList();

    final memberById = {for (final m in members) m.id: m};
    final notes = ref.watch(notesProvider).valueOrNull ?? [];
    final noteSort = ref.watch(noteSortProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _Header(
              greetingName: me?.name,
              taskCount: todayTasks.where((t) => !t.isCompleted).length,
              eventCount: eventsToday,
              listCount: lists.length,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: l10n.sectionTodaysPriorities, onViewAll: onViewTasks),
                  const SizedBox(height: 10),
                  Card(
                    child: allTasks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: _EmptyCard(
                              text: l10n.emptyNoTasksYet,
                              hint: l10n.emptyNoTasksHint,
                            ),
                          )
                        : (todayNotOverdue.isEmpty && overdueTasks.isEmpty)
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: _EmptyCard(text: l10n.emptyNothingDueToday),
                              )
                            : Column(
                                children: [
                                  if (visibleOverdue.isNotEmpty)
                                    _NeedsAttentionHeader(count: overdueTasks.length),
                                  for (var i = 0; i < visibleOverdue.length; i++) ...[
                                    _PriorityRow(
                                      task: visibleOverdue[i],
                                      member: memberById[visibleOverdue[i].assigneeId],
                                      overdue: true,
                                    ),
                                    if (i != visibleOverdue.length - 1 ||
                                        visibleToday.isNotEmpty)
                                      const Divider(height: 1, indent: 56),
                                  ],
                                  for (var i = 0; i < visibleToday.length; i++) ...[
                                    _PriorityRow(
                                      task: visibleToday[i],
                                      member: memberById[visibleToday[i].assigneeId],
                                    ),
                                    if (i != visibleToday.length - 1)
                                      const Divider(height: 1, indent: 56),
                                  ],
                                ],
                              ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeader(
                                title: l10n.sectionUpcomingEvents, onViewAll: onViewEvents),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: upcomingEvents.isEmpty
                                    ? (events.isEmpty
                                        ? _EmptyCard(
                                            text: l10n.emptyNoEventsYet,
                                            hint: l10n.emptyNoEventsHint,
                                            actionLabel: l10n.actionAddEvent,
                                            onAction: () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const EventFormScreen()),
                                            ),
                                          )
                                        : _EmptyCard(text: l10n.emptyNoUpcomingEvents))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (final e in upcomingEvents.take(3))
                                            _EventRow(
                                              event: e,
                                              members: [
                                                for (final id
                                                    in eventMembers[e.id] ?? const [])
                                                  if (memberById[id] != null)
                                                    memberById[id]!,
                                              ],
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeader(
                                title: primaryList?.name ?? l10n.sectionShopping,
                                onViewAll: onViewLists),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: primaryList == null
                                    ? _EmptyCard(
                                        text: l10n.emptyNoListsYet,
                                        hint: l10n.emptyNoListsHint,
                                        compact: true,
                                      )
                                    : primaryItems.isEmpty
                                        ? _EmptyCard(
                                            text: l10n.emptyNoItemsYet,
                                            hint: l10n.emptyNoItemsHint,
                                            actionLabel: l10n.actionAddItem,
                                            onAction: onViewLists,
                                            compact: true,
                                          )
                                        : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (final item in pendingItems.take(5))
                                            InkWell(
                                              onTap: () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ListDetailScreen(
                                                      list: primaryList),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 3),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.circle_outlined,
                                                        size: 16,
                                                        color:
                                                            context.colors.textSecondary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(item.name,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                              fontSize: 13)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (pendingItems.isEmpty)
                                            Text(l10n.emptyAllDone,
                                                style: TextStyle(
                                                    color: context.colors.textSecondary,
                                                    fontSize: 13)),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: onViewLists,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 6, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.shopping_cart,
                                                      size: 14,
                                                      color: AppColors.success),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    l10n.itemsCount(primaryItems.length),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.success,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: l10n.sectionFamilyActivity),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FamilyActivityFeed(tasks: allTasks, lists: lists),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.sectionNotes.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.quickAddNote,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const NoteFormScreen()),
                                ),
                              ),
                              PopupMenuButton<NoteSort>(
                                icon:
                                    const Icon(Icons.sort, size: 18, color: AppColors.primary),
                                initialValue: noteSort,
                                onSelected: (sort) =>
                                    ref.read(noteSortProvider.notifier).state = sort,
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: NoteSort.date,
                                    child: Text(l10n.notesSortByDate),
                                  ),
                                  PopupMenuItem(
                                    value: NoteSort.color,
                                    child: Text(l10n.notesSortByColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final note in notes)
                          _NoteCard(
                            note: note,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => NoteFormScreen(existing: note)),
                            ),
                          ),
                      ],
                    ),
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

class _Header extends ConsumerWidget {
  const _Header({
    required this.greetingName,
    required this.taskCount,
    required this.eventCount,
    required this.listCount,
  });

  final String? greetingName;
  final int taskCount;
  final int eventCount;
  final int listCount;

  Future<void> _pickFamilyPhoto(BuildContext context, WidgetRef ref) async {
    if (!checkPermission(context, ref, FamilyAction.manageFamilySettings)) return;
    final path =
        await pickAndSaveAvatarPhoto(context: context, memberId: 'family');
    if (path != null) {
      await ref.read(familyProfileRepositoryProvider).setPhotoPath(
            path,
            actingRole: ref.read(activeRoleProvider),
          );
    }
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final familyPhotoPath = ref.watch(familyPhotoPathProvider).valueOrNull;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: const HeaderWaveClipper(),
          child: Container(
            height: 210,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.menu, color: Colors.white),
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.notifications_none, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.greetingWithName(
                              _greeting(l10n),
                              greetingName ?? l10n.greetingFallbackName,
                            ),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d', locale).format(DateTime.now()),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _pickFamilyPhoto(context, ref),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white38,
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              backgroundImage: familyPhotoPath == null
                                  ? const AssetImage('assets/onboarding/family.png')
                                  : FileImage(File(familyPhotoPath)) as ImageProvider,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 1),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -28,
          child: Card(
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: Icons.assignment_turned_in_outlined,
                    color: AppColors.primary,
                    value: taskCount,
                    label: l10n.statTasksToday,
                  ),
                  const _StatDivider(),
                  _StatChip(
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.info,
                    value: eventCount,
                    label: eventCount == 1 ? l10n.statEvent : l10n.statEvents,
                  ),
                  const _StatDivider(),
                  _StatChip(
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.success,
                    value: listCount,
                    label: listCount == 1 ? l10n.statList : l10n.statLists,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: Colors.grey.shade200);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text('$value',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _NeedsAttentionHeader extends StatelessWidget {
  const _NeedsAttentionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.priorityHigh),
          const SizedBox(width: 6),
          Text(
            '${l10n.needsAttention.toUpperCase()} ($count)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.priorityHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.task, required this.member, this.overdue = false});

  final Task task;
  final FamilyMember? member;

  /// Restricts red to the category/date line and the trailing badge — per
  /// the rest of the app's overdue treatment, the row itself never turns
  /// red.
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHighPriority =
        task.priority == TaskPriority.high || task.priority == TaskPriority.urgent;
    final statusColor = task.isCompleted
        ? AppColors.success
        : isHighPriority
            ? AppColors.priorityUrgent
            : AppColors.priorityNormal;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskFormScreen(existing: task)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: task.isCompleted
                  ? Icon(Icons.check, size: 16, color: statusColor)
                  : Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
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
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          overdue
                              ? '${task.category.label(l10n)} • ${_overdueLabel(l10n, task)}'
                              : task.category.label(l10n),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: overdue ? FontWeight.w700 : null,
                            color: overdue
                                ? AppColors.priorityHigh
                                : context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MemberAvatar(member: member, radius: 16),
            const SizedBox(width: 8),
            if (task.isCompleted)
              Text(
                l10n.taskStatusDone,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              )
            else if (overdue)
              const Icon(Icons.error_outline, size: 18, color: AppColors.priorityHigh)
            else if (isHighPriority)
              Icon(Icons.flag_rounded, size: 18, color: statusColor)
            else
              Text(
                l10n.today,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.members});

  final Event event;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peopleLine = members.isEmpty
        ? null
        : members.length <= 2
            ? members.map((m) => m.name).join(', ')
            : l10n.peopleCount(members.length);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: event.displayColor.withValues(alpha: 0.15),
              child: Icon(event.category.icon, size: 14, color: event.displayColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _relativeDayAndTime(context, l10n, event.startAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: event.displayColor,
                    ),
                  ),
                  Text(
                    event.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (peopleLine != null)
                    Text(peopleLine,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.text,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String text;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tighter padding/spacing for sections where an empty state shouldn't
  /// visually compete for the same space a populated list would take.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : null,
            ),
          ),
          if (hint != null) ...[
            SizedBox(height: compact ? 2 : 4),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 4 : 8),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 16),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.notePalette[note.colorIndex],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          note.body,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
