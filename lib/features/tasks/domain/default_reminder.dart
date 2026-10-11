import '../../../data/local/tables/tasks_table.dart';

/// The reminder a **new** task starts with, from the "default task
/// reminder" setting ([taskDefault]: null none, 0 at the due time, n
/// minutes before — see `ReminderPreferences.taskDefault`). Existing tasks
/// are never changed by the setting.
///
/// A date-only task ([dueTimeMinutes] null) has no time to count minutes
/// back from, so an "n minutes before" default leaves it with the usual
/// on-the-day reminder (9 AM, see `taskReminderAt`).
({TaskReminderType type, int? offsetMinutes}) defaultTaskReminder(
  int? taskDefault, {
  required int? dueTimeMinutes,
}) {
  if (taskDefault == null) return (type: TaskReminderType.none, offsetMinutes: null);
  if (taskDefault == 0 || dueTimeMinutes == null) {
    return (type: TaskReminderType.dueTime, offsetMinutes: null);
  }
  return (type: TaskReminderType.offset, offsetMinutes: taskDefault);
}
