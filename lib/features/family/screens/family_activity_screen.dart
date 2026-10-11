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

/// The full Family Activity timeline (V2.1): a "This week" summary, member
/// and type filters, entries grouped Today / Yesterday / Earlier this week
/// (then by date), and "Show older activity" a week at a time.
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
    final groups = _groupByDay(items, l10n, locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionFamilyActivity)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WeekSummary(summary: WeeklyActivitySummary.of(week)),
          const SizedBox(height: 16),
          _MemberFilter(
            members: members,
            selected: _memberId,
            onSelected: (id) => setState(() => _memberId = id),
          ),
          const SizedBox(height: 8),
          _CategoryFilter(selected: _category, onSelected: (c) => setState(() => _category = c)),
          const SizedBox(height: 16),
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
                          timeLabel: DateFormat.jm(locale).format(dayItems[i].time.toLocal()),
                        ),
                        if (i != dayItems.length - 1)
                          Divider(height: 20, color: context.colors.borderSubtle),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          Center(
            child: hasOlder
                ? TextButton.icon(
                    onPressed: () => ref.read(activityDaysProvider.notifier).state += 7,
                    icon: const Icon(Icons.history),
                    label: Text(l10n.activityLoadOlder),
                  )
                : Text(
                    l10n.activityNoOlder,
                    style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }

  /// Today / Yesterday / Earlier this week, then one group per date.
  List<(String, List<ActivityItem>)> _groupByDay(
    List<ActivityItem> items,
    AppLocalizations l10n,
    String locale,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String labelFor(DateTime t) {
      final local = t.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final ago = today.difference(day).inDays;
      if (ago <= 0) return l10n.today;
      if (ago == 1) return l10n.yesterday;
      if (ago < 7) return l10n.activityEarlierThisWeek;
      return DateFormat.MMMEd(locale).format(day);
    }

    final groups = <(String, List<ActivityItem>)>[];
    for (final item in items) {
      final label = labelFor(item.time);
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add(item);
    }
    return groups;
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({required this.summary});

  final WeeklyActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    Widget stat(int value, String label, IconData icon, Color color) => Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
              child: Text(
                l10n.activityThisWeek,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat(summary.tasksDone, l10n.activityStatTasks, Icons.check_circle, colors.success),
                stat(summary.events, l10n.activityStatEvents, Icons.event, colors.warning),
                stat(
                  summary.shopping,
                  l10n.activityStatShopping,
                  Icons.shopping_cart,
                  colors.accent,
                ),
                stat(summary.choresDone, l10n.activityStatChores, Icons.task_alt, colors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberFilter extends StatelessWidget {
  const _MemberFilter({required this.members, required this.selected, required this.onSelected});

  final List<FamilyMember> members;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.activityFilterEveryone),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final m in members) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: MemberAvatar(member: m, radius: 10),
              label: Text(m.name),
              selected: selected == m.id,
              onSelected: (on) => onSelected(on ? m.id : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});

  final ActivityCategory? selected;
  final ValueChanged<ActivityCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(ActivityCategory?, String)>[
      (null, l10n.activityFilterAll),
      (ActivityCategory.tasks, l10n.activityFilterTasks),
      (ActivityCategory.events, l10n.activityFilterEvents),
      (ActivityCategory.shopping, l10n.activityFilterShopping),
      (ActivityCategory.family, l10n.activityFilterFamily),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (category, label) in options) ...[
            if (category != null) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(label),
              selected: selected == category,
              onSelected: (on) => onSelected(on ? category : null),
            ),
          ],
        ],
      ),
    );
  }
}
