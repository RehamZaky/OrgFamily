import '../../../data/activity/activity_log.dart';
import '../../../data/repositories/family_settings_repository.dart';
import '../providers/activity_providers.dart';

/// Family insights (V2.3) — the pure part: which dates a period covers and
/// what gets counted, so both are easy to test.
enum InsightsPeriod { week, month }

/// The period so far, and the same stretch of the period before it — so a
/// Tuesday is compared with last week up to Tuesday, not all of last week.
class InsightsWindow {
  const InsightsWindow({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
  });

  /// Midnight on the period's first day (the family's week start, or the
  /// 1st of the month).
  final DateTime start;

  /// Now.
  final DateTime end;
  final DateTime previousStart;

  /// The same point in the previous period: as many days in, at the same
  /// time of day — capped at the period's end (31 March vs February).
  final DateTime previousEnd;
}

InsightsWindow insightsWindow(
  InsightsPeriod period, {
  required DateTime now,
  required FamilySchedule schedule,
}) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case InsightsPeriod.week:
      final start = schedule.weekStart(now);
      final previousStart = DateTime(start.year, start.month, start.day - 7);
      // Calendar days, not Durations, so a DST change can't shift a day.
      final daysIn = DateTime.utc(today.year, today.month, today.day)
          .difference(DateTime.utc(start.year, start.month, start.day))
          .inDays;
      return InsightsWindow(
        start: start,
        end: now,
        previousStart: previousStart,
        previousEnd: DateTime(
          previousStart.year,
          previousStart.month,
          previousStart.day + daysIn,
          now.hour,
          now.minute,
          now.second,
        ),
      );
    case InsightsPeriod.month:
      final start = DateTime(now.year, now.month);
      final previousStart = DateTime(now.year, now.month - 1);
      final previousLength = DateTime(now.year, now.month, 0).day;
      return InsightsWindow(
        start: start,
        end: now,
        previousStart: previousStart,
        previousEnd: now.day > previousLength
            ? start
            : DateTime(
                previousStart.year,
                previousStart.month,
                now.day,
                now.hour,
                now.minute,
                now.second,
              ),
      );
  }
}

/// Tasks and responsibilities one member completed.
class MemberProgress {
  const MemberProgress({this.tasks = 0, this.responsibilities = 0});

  final int tasks;
  final int responsibilities;
  int get total => tasks + responsibilities;
}

/// What happened in one stretch of time.
class InsightsCounts {
  const InsightsCounts({
    required this.tasksCompleted,
    required this.responsibilitiesDone,
    required this.shoppingAdded,
    required this.shoppingPurchased,
    required this.eventUpdates,
    required this.byMember,
  });

  /// Distinct tasks completed.
  final int tasksCompleted;

  /// Distinct responsibility-and-day completions.
  final int responsibilitiesDone;

  /// Distinct shopping items added.
  final int shoppingAdded;

  /// Distinct shopping items marked bought.
  final int shoppingPurchased;

  /// Events created, changed or cancelled — each entry once.
  final int eventUpdates;

  /// Tasks and responsibilities by who completed them (only those two —
  /// adding an item or editing an event isn't "progress").
  final Map<String, MemberProgress> byMember;
}

/// Counts [items] from [from] (inclusive) to [to] (exclusive), each thing
/// once however many entries describe it: a task completed twice, or a
/// responsibility ticked twice on one day — entries from before the
/// log's once-only ids, from a phone on an older build, or a log entry
/// alongside the same completion derived from the tasks table — counts
/// once, credited to whoever did it first.
InsightsCounts countInsights(
  Iterable<ActivityItem> items, {
  required DateTime from,
  required DateTime to,
}) {
  final ordered = [
    for (final i in items)
      if (!i.time.toLocal().isBefore(from) && i.time.toLocal().isBefore(to)) i,
  ]..sort((a, b) => a.time.compareTo(b.time));

  final tasks = <String>{};
  final responsibilities = <String>{};
  final added = <String>{};
  final purchased = <String>{};
  final events = <String>{};
  final taskCredit = <String, int>{};
  final choreCredit = <String, int>{};

  for (final i in ordered) {
    final entity = i.entityId ?? i.id;
    final member = i.memberId;
    switch (i.type) {
      case ActivityTypes.taskCompleted:
        if (tasks.add(entity) && member != null) {
          taskCredit[member] = (taskCredit[member] ?? 0) + 1;
        }
      case ActivityTypes.responsibilityCompleted:
        final day = i.time.toLocal();
        if (responsibilities.add('$entity|${day.year}-${day.month}-${day.day}') && member != null) {
          choreCredit[member] = (choreCredit[member] ?? 0) + 1;
        }
      case ActivityTypes.shoppingItemAdded:
        added.add(entity);
      case ActivityTypes.shoppingItemPurchased:
        purchased.add(entity);
      case ActivityTypes.eventCreated || ActivityTypes.eventChanged || ActivityTypes.eventCancelled:
        events.add(i.id);
    }
  }

  return InsightsCounts(
    tasksCompleted: tasks.length,
    responsibilitiesDone: responsibilities.length,
    shoppingAdded: added.length,
    shoppingPurchased: purchased.length,
    eventUpdates: events.length,
    byMember: {
      for (final id in {...taskCredit.keys, ...choreCredit.keys})
        id: MemberProgress(tasks: taskCredit[id] ?? 0, responsibilities: choreCredit[id] ?? 0),
    },
  );
}

/// Whether this phone has the activity log all the way back to [from]:
/// its earliest entry ([historyStart]) is no later than that. Before the
/// log started (V2.1), and before the 30 days a newly joined phone
/// receives, responsibilities, purchases and events weren't recorded, so a
/// comparison reaching further back would be misleading.
bool hasHistorySince(DateTime? historyStart, DateTime from) =>
    historyStart != null && !historyStart.toLocal().isAfter(from);

/// The change from [previous] to [current] in whole percent, or null when
/// there's nothing reliable to compare with: no complete previous period
/// ([previous] null), or nothing in it (a change from zero has no
/// percentage). A real change never shows as 0%.
int? changePercent(int current, int? previous) {
  if (previous == null || previous == 0) return null;
  final percent = ((current - previous) * 100 / previous).round();
  if (percent == 0 && current != previous) return current > previous ? 1 : -1;
  return percent;
}
