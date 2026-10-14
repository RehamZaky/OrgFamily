import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_settings_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/widgets/settings_group.dart';
import '../providers/activity_providers.dart';
import '../providers/family_providers.dart';
import 'family_insights.dart';
import 'insights_providers.dart';

/// Drawer → Family insights (V2.3): this week or month so far for the
/// whole family — five counts, each against the same point of the
/// previous period when this phone has the history for it — and who
/// completed what. Never money.
class FamilyInsightsScreen extends ConsumerStatefulWidget {
  const FamilyInsightsScreen({super.key});

  @override
  ConsumerState<FamilyInsightsScreen> createState() => _FamilyInsightsScreenState();
}

class _FamilyInsightsScreenState extends ConsumerState<FamilyInsightsScreen> {
  InsightsPeriod _period = InsightsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedule = ref.watch(familyScheduleProvider).valueOrNull ?? FamilySchedule.defaults;
    final window = insightsWindow(_period, now: DateTime.now(), schedule: schedule);
    final activity = ref.watch(insightsActivityProvider(window.previousStart));
    final historyStart = ref.watch(activityHistoryStartProvider);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const <FamilyMember>[];

    final loading = !activity.hasValue || !historyStart.hasValue;
    final items = activity.valueOrNull ?? const <ActivityItem>[];
    final current = countInsights(items, from: window.start, to: window.end);
    final previous = countInsights(items, from: window.previousStart, to: window.previousEnd);
    final canCompare = hasHistorySince(historyStart.valueOrNull, window.previousStart);
    final currentComplete = hasHistorySince(historyStart.valueOrNull, window.start);
    // A family with nothing recorded yet gets a welcome, not a wall of zeros.
    final nothingYet = !loading && historyStart.valueOrNull == null && items.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (!nothingYet) ...[
            SegmentedButton<InsightsPeriod>(
              style: settingsSegmentedStyle(),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: InsightsPeriod.week, label: Text(l10n.insightsWeek)),
                ButtonSegment(value: InsightsPeriod.month, label: Text(l10n.insightsMonth)),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 16),
          ],
          if (loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (nothingYet)
            const _Welcome()
          else ...[
            _Totals(
              period: _period,
              window: window,
              current: current,
              previous: canCompare ? previous : null,
              historyStart: currentComplete ? null : historyStart.valueOrNull,
            ),
            const SizedBox(height: 16),
            _MemberProgressCard(members: members, counts: current),
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.period,
    required this.window,
    required this.current,
    required this.previous,
    required this.historyStart,
  });

  final InsightsPeriod period;
  final InsightsWindow window;
  final InsightsCounts current;

  /// Null when the phone lacks the history to compare — comparisons are
  /// then left out, not replaced by a placeholder.
  final InsightsCounts? previous;

  /// Where this phone's log starts, when that's inside the current period.
  final DateTime? historyStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final range =
        '${DateFormat.MMMd(locale).format(window.start)} – ${DateFormat.MMMd(locale).format(window.end)}';
    final p = previous;

    final against = period == InsightsPeriod.week
        ? l10n.insightsVsLastWeek
        : l10n.insightsVsLastMonth;
    final start = historyStart;
    final about = [
      if (start != null) l10n.insightsHistoryFrom(DateFormat.yMMMd(locale).format(start.toLocal())),
      l10n.insightsHowCounted,
    ].join('\n\n');

    Widget row(IconData icon, Color color, String label, int value, int? before) {
      final percent = changePercent(value, before);
      final compare = switch (percent) {
        null => null,
        0 => l10n.insightsSameAs(against),
        final p =>
          '${p > 0 ? '+' : '−'}${NumberFormat.percentPattern(locale).format(p.abs() / 100)} $against',
      };
      final compareColor = (percent ?? 0) > 0 ? colors.success : colors.textSecondary;
      return Semantics(
        label: [label, '$value', ?compare].join('. '),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (compare != null)
                      Text(compare, style: TextStyle(fontSize: 12, color: compareColor)),
                  ],
                ),
              ),
              Text(
                NumberFormat.decimalPattern(locale).format(value),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rows = [
      row(
        Icons.check_circle,
        colors.accent,
        l10n.insightsTasksCompleted,
        current.tasksCompleted,
        p?.tasksCompleted,
      ),
      row(
        Icons.task_alt,
        colors.success,
        l10n.insightsResponsibilitiesDone,
        current.responsibilitiesDone,
        p?.responsibilitiesDone,
      ),
      row(
        Icons.add_shopping_cart,
        colors.warning,
        l10n.insightsShoppingAdded,
        current.shoppingAdded,
        p?.shoppingAdded,
      ),
      row(
        Icons.shopping_bag_outlined,
        colors.warning,
        l10n.insightsShoppingPurchased,
        current.shoppingPurchased,
        p?.shoppingPurchased,
      ),
      row(
        Icons.event,
        colors.danger,
        l10n.insightsEventUpdates,
        current.eventUpdates,
        p?.eventUpdates,
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  period == InsightsPeriod.week ? l10n.activityThisWeek : l10n.insightsThisMonth,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                // How the numbers are counted and how far back they go —
                // there when wanted, out of the way otherwise.
                Tooltip(
                  message: about,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  // Opaque, so the numbers underneath don't show through.
                  decoration: BoxDecoration(
                    color: colors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(fontSize: 12.5, height: 1.4, color: colors.surface),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
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
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// One bar per member: tasks then responsibilities completed this period.
class _MemberProgressCard extends StatelessWidget {
  const _MemberProgressCard({required this.members, required this.counts});

  final List<FamilyMember> members;
  final InsightsCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final progress = {
      for (final m in members) m.id: counts.byMember[m.id] ?? const MemberProgress(),
    };
    final ordered = [...members]
      ..sort((a, b) => progress[b.id]!.total.compareTo(progress[a.id]!.total));
    final most = progress.values.fold(0, (max, p) => p.total > max ? p.total : max);

    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.insightsWhoCompleted,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              children: [
                legend(colors.accent, l10n.insightsLegendTasks),
                legend(colors.success, l10n.insightsLegendResponsibilities),
              ],
            ),
            const SizedBox(height: 12),
            if (ordered.isEmpty)
              Text(l10n.emptyNoActivityYet, style: TextStyle(color: colors.textSecondary))
            else
              for (final m in ordered) _MemberBar(member: m, progress: progress[m.id]!, most: most),
          ],
        ),
      ),
    );
  }
}

class _MemberBar extends StatelessWidget {
  const _MemberBar({required this.member, required this.progress, required this.most});

  final FamilyMember member;
  final MemberProgress progress;
  final int most;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Semantics(
      label: l10n.insightsMemberSemantics(member.name, progress.tasks, progress.responsibilities),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            MemberAvatar(member: member, radius: 14),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  child: ColoredBox(
                    color: colors.track,
                    child: most == 0
                        ? const SizedBox.expand()
                        : Row(
                            // Fills the bar's height — a childless box
                            // would otherwise be zero high.
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (progress.tasks > 0)
                                Expanded(
                                  flex: progress.tasks,
                                  child: ColoredBox(color: colors.accent),
                                ),
                              if (progress.responsibilities > 0)
                                Expanded(
                                  flex: progress.responsibilities,
                                  child: ColoredBox(color: colors.success),
                                ),
                              if (most - progress.total > 0)
                                Expanded(flex: most - progress.total, child: const SizedBox()),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '${progress.total}',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A family with no activity yet: a welcome instead of empty numbers.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.insights_rounded, size: 30, color: colors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.insightsWelcomeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.insightsWelcomeBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
