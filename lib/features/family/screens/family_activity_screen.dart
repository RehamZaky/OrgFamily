import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/activity_providers.dart';
import '../providers/family_providers.dart';
import '../widgets/family_activity_feed.dart';

/// The full Family Activity timeline (V2.1): a compact "This week" summary
/// of the whole family, a compact member/type filter bar (each opens a
/// bottom sheet), entries grouped Today / Yesterday / weekday / date in one
/// card per day, and "Show older activity" a week at a time.
class FamilyActivityScreen extends ConsumerStatefulWidget {
  const FamilyActivityScreen({super.key});

  @override
  ConsumerState<FamilyActivityScreen> createState() => _FamilyActivityScreenState();
}

class _FamilyActivityScreenState extends ConsumerState<FamilyActivityScreen> {
  String? _memberId;
  ActivityCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final days = ref.watch(activityDaysProvider);
    final all = ref.watch(familyActivityProvider(days));
    final week = ref.watch(familyActivityProvider(7)).valueOrNull ?? const <ActivityItem>[];
    final hasOlder = ref.watch(hasOlderActivityProvider(days)).valueOrNull ?? false;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const <FamilyMember>[];
    final membersById = {for (final m in members) m.id: m};

    final items = (all.valueOrNull ?? const <ActivityItem>[])
        .where(
          (i) =>
              (_memberId == null || i.memberId == _memberId) &&
              (_category == null || i.category == _category),
        )
        .toList();
    final groups = groupActivityByDay(items, l10n, locale);
    // Nothing at all yet: no filters to offer, and no "older" to mention.
    final nothingYet = all.hasValue && all.requireValue.isEmpty && !hasOlder;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionFamilyActivity)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _WeekSummary(summary: WeeklyActivitySummary.of(week)),
          const SizedBox(height: 18),
          if (!nothingYet) ...[
            _FilterBar(
              members: members,
              memberId: _memberId,
              category: _category,
              onMember: (id) => setState(() => _memberId = id),
              onCategory: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 12),
          ],
          if (all.isLoading && !all.hasValue)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  _memberId == null && _category == null
                      ? l10n.emptyNoActivityYet
                      : l10n.activityEmptyFiltered,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          else
            for (final (label, dayItems) in groups) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      for (var i = 0; i < dayItems.length; i++) ...[
                        ActivityRow(
                          item: dayItems[i],
                          membersById: membersById,
                          // The section already says which day.
                          timeLabel: DateFormat.jm(locale).format(dayItems[i].time.toLocal()),
                        ),
                        if (i != dayItems.length - 1)
                          Divider(height: 20, color: context.colors.border),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          if (hasOlder)
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(activityDaysProvider.notifier).state += 7,
                icon: const Icon(Icons.history),
                label: Text(l10n.activityLoadOlder),
              ),
            )
          else if (items.isNotEmpty)
            Center(
              child: Text(
                l10n.activityNoOlder,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sections of the timeline, newest first: Today, Yesterday, then the
/// weekday for the rest of the week ("Monday"), then the full date. Each
/// entry's time is converted to this phone's time zone first — Firestore
/// orders by server time, but the day it lands in is the viewer's.
List<(String, List<ActivityItem>)> groupActivityByDay(
  List<ActivityItem> items,
  AppLocalizations l10n,
  String locale, {
  DateTime? now,
}) {
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);
  String labelFor(DateTime t) {
    final local = t.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final ago = today.difference(day).inDays;
    if (ago <= 0) return l10n.today;
    if (ago == 1) return l10n.yesterday;
    if (ago < 7) return DateFormat.EEEE(locale).format(day);
    return day.year == today.year
        ? DateFormat.MMMEd(locale).format(day)
        : DateFormat.yMMMEd(locale).format(day);
  }

  final groups = <(String, List<ActivityItem>)>[];
  for (final item in items) {
    final label = labelFor(item.time);
    if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
    groups.last.$2.add(item);
  }
  return groups;
}

/// "This week" for the whole family — always, whatever the filters below
/// say (the subtitle states it), so the numbers never silently change.
class _WeekSummary extends StatelessWidget {
  const _WeekSummary({required this.summary});

  final WeeklyActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final start = activityWindowStart(7);
    final now = DateTime.now();
    final range =
        '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.MMMd(locale).format(now)}';

    Widget stat(int value, String label, String fullLabel, IconData icon, Color color) => Expanded(
      child: Semantics(
        label: '$value $fullLabel',
        excludeSemantics: true,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.activityThisWeek,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.activityWholeFamily(range),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat(
                  summary.tasksDone,
                  l10n.activityStatTasksShort,
                  l10n.activityStatTasks,
                  Icons.check_circle,
                  colors.success,
                ),
                stat(
                  summary.events,
                  l10n.activityStatEventsShort,
                  l10n.activityStatEvents,
                  Icons.event,
                  colors.warning,
                ),
                stat(
                  summary.shopping,
                  l10n.activityStatListsShort,
                  l10n.activityStatShopping,
                  Icons.shopping_cart,
                  colors.accent,
                ),
                stat(
                  summary.choresDone,
                  l10n.activityStatChoresShort,
                  l10n.activityStatChores,
                  Icons.task_alt,
                  colors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Activity timeline", and beneath it two compact pickers — member and
/// type — that open bottom sheets, instead of two full rows of chips.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.members,
    required this.memberId,
    required this.category,
    required this.onMember,
    required this.onCategory,
  });

  final List<FamilyMember> members;
  final String? memberId;
  final ActivityCategory? category;
  final ValueChanged<String?> onMember;
  final ValueChanged<ActivityCategory?> onCategory;

  static String categoryLabel(AppLocalizations l10n, ActivityCategory? c) => switch (c) {
    null => l10n.activityFilterAllTypes,
    ActivityCategory.tasks => l10n.activityFilterTasks,
    ActivityCategory.events => l10n.activityFilterEvents,
    ActivityCategory.shopping => l10n.activityFilterShopping,
    ActivityCategory.responsibilities => l10n.activityFilterResponsibilities,
    ActivityCategory.members => l10n.activityFilterMembers,
  };

  static IconData categoryIcon(ActivityCategory? c) => switch (c) {
    null => Icons.tune,
    ActivityCategory.tasks => Icons.check_circle_outline,
    ActivityCategory.events => Icons.event_outlined,
    ActivityCategory.shopping => Icons.shopping_cart_outlined,
    ActivityCategory.responsibilities => Icons.task_alt,
    ActivityCategory.members => Icons.group_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final member = members.where((m) => m.id == memberId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            l10n.activityTimeline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: _FilterPill(
                leading: member == null
                    ? const Icon(Icons.groups_outlined, size: 16)
                    : MemberAvatar(member: member, radius: 9),
                label: member?.name ?? l10n.activityFilterEveryone,
                active: member != null,
                onTap: () => _pickMember(context, l10n),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _FilterPill(
                leading: Icon(categoryIcon(category), size: 16),
                label: categoryLabel(l10n, category),
                active: category != null,
                onTap: () => _pickCategory(context, l10n),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickMember(BuildContext context, AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<(String?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PickerSheet(
        title: l10n.activityFilterByMember,
        options: [
          (
            const CircleAvatar(radius: 16, child: Icon(Icons.groups_outlined, size: 18)),
            l10n.activityFilterEveryone,
            memberId == null,
            () => Navigator.pop(context, (null,)),
          ),
          for (final m in members)
            (
              MemberAvatar(member: m, radius: 16),
              m.name,
              memberId == m.id,
              () => Navigator.pop(context, (m.id,)),
            ),
        ],
      ),
    );
    if (picked != null) onMember(picked.$1);
  }

  Future<void> _pickCategory(BuildContext context, AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<(ActivityCategory?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PickerSheet(
        title: l10n.activityFilterByType,
        options: [
          for (final c in <ActivityCategory?>[null, ...ActivityCategory.values])
            (
              Icon(categoryIcon(c)),
              categoryLabel(l10n, c),
              category == c,
              () => Navigator.pop(context, (c,)),
            ),
        ],
      ),
    );
    if (picked != null) onCategory(picked.$1);
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.leading,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = active ? colors.accent : colors.textPrimary;
    return Material(
      color: active ? colors.accent.withValues(alpha: 0.12) : colors.surface,
      shape: StadiumBorder(side: BorderSide(color: active ? colors.accent : colors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 6, 4),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.options});

  final String title;
  final List<(Widget, String, bool, VoidCallback)> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            for (final (leading, label, selected, onTap) in options)
              ListTile(
                leading: leading,
                title: Text(label),
                trailing: selected ? Icon(Icons.check, color: colors.accent) : null,
                selected: selected,
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }
}
