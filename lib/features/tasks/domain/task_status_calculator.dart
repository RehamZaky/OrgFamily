import 'package:drift/drift.dart' show Value;

import '../../../core/permissions/family_permissions.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/family_members_table.dart';

/// Task fields relevant to deadline math, decoupled from the Drift row type
/// so this stays pure and easy to unit test without a database.
class TaskDeadlineInput {
  const TaskDeadlineInput({
    required this.dueDate,
    required this.dueTimeMinutes,
    required this.isCompleted,
  });

  TaskDeadlineInput.fromTask(Task task)
      : this(
          dueDate: task.dueDate,
          dueTimeMinutes: task.dueTimeMinutes,
          isCompleted: task.isCompleted,
        );

  final DateTime? dueDate;

  /// Minutes since midnight — null means the task is due sometime that
  /// day, not at a specific time.
  final int? dueTimeMinutes;
  final bool isCompleted;
}

/// The exact moment a task is due, or null if it has no due date. For a
/// date-only task (no [TaskDeadlineInput.dueTimeMinutes]), that's the end
/// of that local day — it stays "due today" all day rather than going
/// overdue the instant the clock passes midnight-implied-9am or some other
/// arbitrary default.
DateTime? taskDeadline(TaskDeadlineInput task) {
  final date = task.dueDate;
  if (date == null) return null;
  final minutes = task.dueTimeMinutes;
  if (minutes != null) {
    return DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
  }
  // End of that local day: the start of the next day is the cutoff.
  return DateTime(date.year, date.month, date.day + 1);
}

/// A task is overdue when it isn't completed, has a due date, and that
/// deadline (see [taskDeadline]) has passed — evaluated fresh against
/// `now` every time, never stored, so it can't go stale while the app
/// isn't running.
bool isTaskOverdue(TaskDeadlineInput task, DateTime now) {
  if (task.isCompleted) return false;
  final deadline = taskDeadline(task);
  if (deadline == null) return false;
  return now.isAfter(deadline);
}

/// When the initial "it's due" reminder should fire: at the exact time for
/// a timed task, or a reasonable default hour (9 AM) on the due date for a
/// date-only one — distinct from [taskDeadline], which for a date-only task
/// is end-of-day, not morning.
DateTime? taskReminderAt(TaskDeadlineInput task) {
  final date = task.dueDate;
  if (date == null) return null;
  final minutes = task.dueTimeMinutes;
  if (minutes != null) {
    return DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
  }
  return DateTime(date.year, date.month, date.day, 9);
}

/// When the single, non-repeating "still needs attention" follow-up should
/// fire if the task is still incomplete: a few hours after a timed task's
/// deadline, or the next morning for a date-only task (its deadline is
/// midnight, which isn't a fair time to notify anyone).
DateTime? taskOverdueFollowupAt(TaskDeadlineInput task) {
  final deadline = taskDeadline(task);
  if (deadline == null) return null;
  if (task.dueTimeMinutes != null) {
    return deadline.add(const Duration(hours: 3));
  }
  return DateTime(deadline.year, deadline.month, deadline.day, 9);
}

/// Whole days between the deadline and `now`, for "Overdue by N days"
/// copy. 0 means it went overdue today (or, for a timed task, within the
/// last 24h of a date that's still today).
int daysOverdue(TaskDeadlineInput task, DateTime now) {
  final deadline = taskDeadline(task);
  if (deadline == null) return 0;
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(deadlineDay).inDays;
  return diff < 0 ? 0 : diff;
}

/// Which permission an update from [existing] to [updated] needs: the
/// lighter [FamilyAction.rescheduleOwnTask] if [actingMemberId] is the
/// task's assignee and the only thing that changed is the due date/time
/// (covers both the "Tomorrow" quick action and picking another date in
/// the full editor), otherwise the full [FamilyAction.editAnyTask].
FamilyAction taskUpdateAction(Task existing, Task updated, String? actingMemberId) {
  final isOwnTask = actingMemberId != null && existing.assigneeId == actingMemberId;
  if (!isOwnTask) return FamilyAction.editAnyTask;
  final onlyRescheduled = existing.copyWith(
        dueDate: Value(updated.dueDate),
        dueTimeMinutes: Value(updated.dueTimeMinutes),
        updatedAt: updated.updatedAt,
      ) ==
      updated;
  return onlyRescheduled ? FamilyAction.rescheduleOwnTask : FamilyAction.editAnyTask;
}

/// Whether [actingMemberId] (with role [actingRole]) may permanently delete
/// [task] — deliberately narrower than [taskUpdateAction]'s editing rules:
/// completing or rescheduling your own task is fine, but making someone
/// else's task disappear entirely isn't, even for an Adult who's simply
/// the assignee. Only the Owner or whoever created the task can delete it
/// (see [Tasks.createdByMemberId]) — a Child who created their own task can
/// still delete that one, same as anyone else deleting their own creation.
bool canDeleteTask(Task task, FamilyRole actingRole, String? actingMemberId) {
  if (actingRole == FamilyRole.owner) return true;
  return actingMemberId != null && task.createdByMemberId == actingMemberId;
}
