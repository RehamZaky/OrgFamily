import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/activity/activity_log.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';

/// What the Family Activity filters group entries by.
enum ActivityCategory { tasks, events, shopping, family }

/// One entry in the Family Activity timeline, from the activity log — or,
/// for time before this phone had the log, derived from completed tasks
/// and added shopping items (see [familyActivityProvider]).
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.memberId,
    required this.time,
    this.metadata = const {},
  });

  final String id;
  final String type;

  /// Who it's credited to: the acting member, or for `member.joined` the
  /// member who joined.
  final String? memberId;

  /// Server time once synced, this phone's clock until then.
  final DateTime time;
  final Map<String, dynamic> metadata;

  ActivityCategory get category => categoryOf(type);

  static ActivityCategory categoryOf(String type) => switch (type.split('.').first) {
    'task' => ActivityCategory.tasks,
    'event' => ActivityCategory.events,
    'shopping_item' => ActivityCategory.shopping,
    _ => ActivityCategory.family,
  };

  factory ActivityItem.fromRow(FamilyActivity row) {
    Map<String, dynamic> metadata;
    try {
      metadata = Map<String, dynamic>.from(jsonDecode(row.metadata) as Map);
    } catch (_) {
      metadata = const {};
    }
    return ActivityItem(
      id: row.id,
      type: row.type,
      memberId: row.type == ActivityTypes.memberJoined ? row.entityId : row.actorMemberId,
      time: row.occurredAt ?? row.createdAt,
      metadata: metadata,
    );
  }
}

/// How many days back the Family Activity screen shows — starts at a week,
/// "Show older activity" adds another.
final activityDaysProvider = StateProvider.autoDispose<int>((ref) => 7);

/// Start of the window covering today and the [days] - 1 days before it.
DateTime activityWindowStart(int days, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day).subtract(Duration(days: days - 1));
}

final _loggedActivityProvider = StreamProvider.autoDispose.family<List<FamilyActivity>, int>((
  ref,
  days,
) {
  final db = ref.watch(databaseProvider);
  final start = activityWindowStart(days);
  final a = db.familyActivities;
  return (db.select(
    a,
  )..where((r) => coalesce([r.occurredAt, r.createdAt]).isBiggerOrEqualValue(start))).watch();
});

/// When this phone started keeping the log (its oldest entry) — before
/// that, the timeline falls back to what tasks and shopping items record
/// themselves. Null while there's no entry at all.
final _logStartProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  final db = ref.watch(databaseProvider);
  final oldest = db.familyActivities.createdAt.min();
  return (db.selectOnly(
    db.familyActivities,
  )..addColumns([oldest])).map((r) => r.read(oldest)).watchSingle();
});

final _completedTasksProvider = StreamProvider.autoDispose.family<List<Task>, int>((ref, days) {
  final db = ref.watch(databaseProvider);
  final start = activityWindowStart(days);
  return (db.select(
    db.tasks,
  )..where((t) => t.deletedAt.isNull() & t.completedAt.isBiggerOrEqualValue(start))).watch();
});

final _addedItemsProvider = StreamProvider.autoDispose.family<List<(ShoppingItem, String)>, int>((
  ref,
  days,
) {
  final db = ref.watch(databaseProvider);
  final start = activityWindowStart(days);
  final query =
      db.select(db.shoppingItems).join([
        innerJoin(db.shoppingLists, db.shoppingLists.id.equalsExp(db.shoppingItems.listId)),
      ])..where(
        db.shoppingItems.deletedAt.isNull() &
            db.shoppingItems.createdAt.isBiggerOrEqualValue(start),
      );
  return query
      .map((r) => (r.readTable(db.shoppingItems), r.readTable(db.shoppingLists).name))
      .watch();
});

/// Every entry from the last [days] days, newest first. Types this version
/// doesn't know (a newer app's, e.g. V3's) are skipped, not shown wrongly.
final familyActivityProvider = Provider.autoDispose.family<AsyncValue<List<ActivityItem>>, int>((
  ref,
  days,
) {
  final logged = ref.watch(_loggedActivityProvider(days));
  final logStart = ref.watch(_logStartProvider);
  final tasks = ref.watch(_completedTasksProvider(days));
  final items = ref.watch(_addedItemsProvider(days));
  for (final v in [logged, logStart, tasks, items]) {
    if (v is AsyncError) return AsyncError(v.error, v.stackTrace);
  }
  if (!logged.hasValue || !logStart.hasValue || !tasks.hasValue || !items.hasValue) {
    return const AsyncLoading();
  }
  final cutoff = logStart.value;
  bool beforeLog(DateTime t) => cutoff == null || t.isBefore(cutoff);
  final result = <ActivityItem>[
    for (final row in logged.value!)
      if (ActivityTypes.known.contains(row.type)) ActivityItem.fromRow(row),
    for (final t in tasks.value!)
      if (beforeLog(t.completedAt!))
        ActivityItem(
          id: 'legacy-task-${t.id}',
          type: ActivityTypes.taskCompleted,
          // Whoever ticked it; the assignee only for tasks completed
          // before completers were recorded.
          memberId: t.completedByMemberId ?? t.assigneeId,
          time: t.completedAt!,
          metadata: {'title': t.title},
        ),
    for (final (item, listName) in items.value!)
      if (beforeLog(item.createdAt))
        ActivityItem(
          id: 'legacy-item-${item.id}',
          type: ActivityTypes.shoppingItemAdded,
          memberId: item.addedById,
          time: item.createdAt,
          metadata: {'name': item.name, 'listName': listName},
        ),
  ]..sort((a, b) => b.time.compareTo(a.time));
  return AsyncData(result);
});

/// Whether anything on this phone is older than the [days]-day window —
/// decides between "Show older activity" and "No older activity".
final hasOlderActivityProvider = StreamProvider.autoDispose.family<bool, int>((ref, days) {
  final db = ref.watch(databaseProvider);
  final start = activityWindowStart(days);
  final a = db.familyActivities;
  final olderLogged =
      (db.selectOnly(a)
            ..addColumns([a.id])
            ..where(coalesce([a.occurredAt, a.createdAt]).isSmallerThanValue(start))
            ..limit(1))
          .watch();
  return olderLogged.asyncMap((rows) async {
    if (rows.isNotEmpty) return true;
    final olderTask =
        await (db.select(db.tasks)
              ..where((t) => t.deletedAt.isNull() & t.completedAt.isSmallerThanValue(start))
              ..limit(1))
            .get();
    if (olderTask.isNotEmpty) return true;
    final olderItem =
        await (db.select(db.shoppingItems)
              ..where((i) => i.deletedAt.isNull() & i.createdAt.isSmallerThanValue(start))
              ..limit(1))
            .get();
    return olderItem.isNotEmpty;
  });
});

/// The "This week" numbers at the top of the Family Activity screen.
class WeeklyActivitySummary {
  const WeeklyActivitySummary({
    required this.tasksDone,
    required this.events,
    required this.shopping,
    required this.choresDone,
  });

  final int tasksDone;
  final int events;
  final int shopping;
  final int choresDone;

  factory WeeklyActivitySummary.of(Iterable<ActivityItem> items) {
    var tasks = 0, events = 0, shopping = 0, chores = 0;
    for (final i in items) {
      switch (i.type) {
        case ActivityTypes.taskCompleted:
          tasks++;
        case ActivityTypes.eventCreated:
        case ActivityTypes.eventChanged:
        case ActivityTypes.eventCancelled:
          events++;
        case ActivityTypes.responsibilityCompleted:
          chores++;
        default:
          if (i.category == ActivityCategory.shopping) shopping++;
      }
    }
    return WeeklyActivitySummary(
      tasksDone: tasks,
      events: events,
      shopping: shopping,
      choresDone: chores,
    );
  }
}
