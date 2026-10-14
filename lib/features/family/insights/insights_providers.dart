import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../providers/activity_providers.dart';

/// When this phone's activity log starts — its earliest entry, or null
/// when it has none. Decides whether an earlier period can be compared.
final activityHistoryStartProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  final db = ref.watch(databaseProvider);
  final a = db.familyActivities;
  final when = coalesce([a.occurredAt, a.createdAt]);
  return (db.selectOnly(a)
        ..addColumns([when])
        ..orderBy([OrderingTerm.asc(when)])
        ..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.first.read(when));
});

/// Every activity entry from [since] on (with history derived from before
/// the log, as on the Family Activity screen) — [familyActivityProvider]
/// for enough days to reach [since].
final insightsActivityProvider =
    Provider.autoDispose.family<AsyncValue<List<ActivityItem>>, DateTime>((ref, since) {
  final now = DateTime.now();
  final days = DateTime.utc(now.year, now.month, now.day)
          .difference(DateTime.utc(since.year, since.month, since.day))
          .inDays +
      1;
  return ref.watch(familyActivityProvider(days));
});
