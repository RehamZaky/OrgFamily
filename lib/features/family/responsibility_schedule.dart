import '../../data/local/database.dart';
import '../../data/local/tables/responsibilities_table.dart';

/// School days in this family's week: Sunday through Thursday.
const schoolWeekdays = {
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
};

/// The `DateTime.weekday` values [r] is due on.
Set<int> scheduledWeekdays(Responsibility r) {
  return switch (r.recurrence) {
    ResponsibilityRecurrence.daily => {for (var d = 1; d <= 7; d++) d},
    ResponsibilityRecurrence.schoolDays => schoolWeekdays,
    ResponsibilityRecurrence.custom => {
        for (final d in (r.customWeekdays ?? '').split(',').map((s) => int.tryParse(s.trim())))
          if (d != null && d >= 1 && d <= 7) d,
      },
  };
}

/// Whether [r] is due on [day] — what decides if it shows in Today/Home and
/// can be ticked "done today".
bool isDueOn(Responsibility r, DateTime day) => scheduledWeekdays(r).contains(day.weekday);

/// The first day after [day] that [r] is due — for "Next: Monday" on days
/// it isn't. Null if it has no scheduled weekdays at all.
DateTime? nextDueAfter(Responsibility r, DateTime day) {
  final weekdays = scheduledWeekdays(r);
  if (weekdays.isEmpty) return null;
  final start = DateTime(day.year, day.month, day.day);
  for (var i = 1; i <= 7; i++) {
    final candidate = start.add(Duration(days: i));
    if (weekdays.contains(candidate.weekday)) return candidate;
  }
  return null;
}

/// Whether [r] was ticked done on [day] (local date).
bool isDoneOn(Responsibility r, DateTime day) {
  final last = r.lastCompletedDate?.toLocal();
  return last != null && last.year == day.year && last.month == day.month && last.day == day.day;
}
