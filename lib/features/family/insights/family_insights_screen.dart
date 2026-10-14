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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
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
          if (loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _Totals(
              period: _period,
              window: window,
              current: current,
              previous: canCompare ? previous : null,
            ),
            const SizedBox(height: 16),
            _MemberProgressCard(members: members, counts: current),
            const SizedBox(height: 16),
            _HistoryNote(
              historyStart: currentComplete ? null : historyStart.valueOrNull,
            ),
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
  });

  final InsightsPeriod period;
  final InsightsWindow window;
  final InsightsCounts current;

  /// Null when the phone lacks the history to compare.
  final InsightsCounts? previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final range =
        '${DateFormat.MMMd(locale).format(window.start)} – ${DateFormat.MMMd(locale).format(window.end)}';
    final p = previous;

    Widget row(IconData icon, Color color, String label, int value, int? before) {
      final String compare;
      final Color compareColor;
      if (before == null) {
        compare = l10n.insightsNotEnoughHistory;
        compareColor = colors.textSecondary;
      } else {
        final diff = value - before;
        final against = period == InsightsPeriod.week
            ? l10n.insightsVsLastWeek
            : l10n.insightsVsLastMonth;
        compare = diff == 0
            ? l10n.insightsSameAs(against)
            : '${diff > 0 ? '+' : '−'}${NumberFormat.decimalPattern(locale).format(diff.abs())} $against';
        compareColor = diff > 0 ? colors.success : colors.textSecondary;
      }
      return Semantics(
        label: '$label: $value. $compare',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(compare, style: TextStyle(fontSize: 12, color: compareColor)),
                  ],
                ),
              ),
              Text(
                NumberFormat.decimalPattern(locale).format(value),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    final rows = [
      row(Icons.check_circle, colors.accent, l10n.insightsTasksCompleted, current.tasksCompleted,
          p?.tasksCompleted),
      row(Icons.task_alt, colors.success, l10n.insightsResponsibilitiesDone,
          current.responsibilitiesDone, p?.responsibilitiesDone),
      row(Icons.add_shopping_cart, colors.warning, l10n.insightsShoppingAdded,
          current.shoppingAdded, p?.shoppingAdded),
      row(Icons.shopping_bag_outlined, colors.warning, l10n.insightsShoppingPurchased,
          current.shoppingPurchased, p?.shoppingPurchased),
      row(Icons.event, colors.danger, l10n.insightsEventUpdates, current.eventUpdates,
          p?.eventUpdates),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
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
              for (final m in ordered)
                _MemberBar(member: m, progress: progress[m.id]!, most: most),
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
                                Expanded(flex: progress.tasks, child: ColoredBox(color: colors.accent)),
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

/// How the numbers are counted, and where the phone's history runs out.
class _HistoryNote extends StatelessWidget {
  const _HistoryNote({required this.historyStart});

  /// When the log on this phone starts, if that's inside the current
  /// period (its numbers are then partial too).
  final DateTime? historyStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final start = historyStart;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (start != null)
                  l10n.insightsHistoryFrom(
                    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(start.toLocal()),
                  ),
                l10n.insightsHowCounted,
              ].join('\n'),
              style: TextStyle(fontSize: 12, height: 1.4, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
