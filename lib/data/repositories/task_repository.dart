import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/permissions/family_permissions.dart';
import '../../core/utils/date_format_x.dart';
import '../../features/tasks/domain/task_status_calculator.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/tasks_table.dart';

class TaskRepository {
  TaskRepository(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  /// "Due at 6:00 PM • Assigned to you" (or "Due today" for a date-only
  /// task, or just the due clause when unassigned) — built fresh each time
  /// a reminder is (re)scheduled, from whatever the task's due
  /// time/assignee are then.
  Future<String> _reminderBody(int? dueTimeMinutes, String? assigneeId) async {
    final due = dueTimeMinutes == null ? 'Due today' : 'Due at ${dueTimeMinutes.timeOfDayLabel}';
    if (assigneeId == null) return due;
    final members = await _db.select(_db.familyMembers).get();
    final assignee = members.where((m) => m.id == assigneeId).firstOrNull;
    if (assignee == null) return due;
    final currentMember = members
            .where((m) => m.role == FamilyRole.owner)
            .firstOrNull ??
        members.firstOrNull;
    final who = assignee.id == currentMember?.id ? 'you' : assignee.name;
    return '$due • Assigned to $who';
  }

  /// Schedules the initial "it's due" reminder and the single overdue
  /// follow-up together — see [taskReminderAt]/[taskOverdueFollowupAt] for
  /// exactly when each fires. Either can be a no-op if its time already
  /// passed (the notification service silently skips scheduling for the
  /// past).
  Future<void> _scheduleReminders({
    required String id,
    required String title,
    required DateTime dueDate,
    required int? dueTimeMinutes,
    required String? assigneeId,
  }) async {
    final input = TaskDeadlineInput(
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
      isCompleted: false,
    );
    final reminderAt = taskReminderAt(input)!;
    await _notifications.scheduleTaskReminder(
      taskId: id,
      title: title,
      body: await _reminderBody(dueTimeMinutes, assigneeId),
      dueDate: reminderAt,
    );
    await _notifications.scheduleTaskOverdueFollowup(
      taskId: id,
      title: 'Still needs attention',
      body: '$title is overdue',
      at: taskOverdueFollowupAt(input)!,
    );
  }

  Future<void> _cancelReminders(String id) async {
    await _notifications.cancelTaskReminder(id);
    await _notifications.cancelTaskOverdueFollowup(id);
  }

  Future<Task?> getById(String id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Re-schedules every incomplete, dated task's reminders from current DB
  /// state. Called after detecting a reboot (see [hasRebootedSinceLastCheck]
  /// in boot_detector.dart) as a correctness backstop on top of the native
  /// BOOT_COMPLETED replay, which replays a snapshot rather than live data.
  Future<void> resyncReminders() async {
    final tasks = await _db.select(_db.tasks).get();
    for (final t in tasks) {
      if (!t.isCompleted && t.dueDate != null) {
        await _scheduleReminders(
          id: t.id,
          title: t.title,
          dueDate: t.dueDate!,
          dueTimeMinutes: t.dueTimeMinutes,
          assigneeId: t.assigneeId,
        );
      }
    }
  }

  Stream<List<Task>> watchAll() {
    return (_db.select(_db.tasks)
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.dueDate),
          ]))
        .watch();
  }

  Stream<List<Task>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (_db.select(_db.tasks)
          ..where((t) =>
              t.isCompleted.equals(false) &
              t.dueDate.isBiggerOrEqualValue(startOfDay) &
              t.dueDate.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .watch();
  }

  Future<void> addTask({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
    int? dueTimeMinutes,
    TaskPriority priority = TaskPriority.normal,
    TaskCategory category = TaskCategory.other,
    String? assigneeId,
    TaskRecurrence recurrence = TaskRecurrence.none,
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.createTask)) {
      throw FamilyPermissionException(FamilyAction.createTask, actingRole);
    }
    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            dueDate: Value(dueDate),
            dueTimeMinutes: Value(dueTimeMinutes),
            priority: Value(priority),
            category: Value(category),
            assigneeId: Value(assigneeId),
            recurrence: Value(recurrence),
            createdByMemberId: Value(actingMemberId),
          ),
        );
    if (dueDate != null) {
      await _scheduleReminders(
        id: id,
        title: title,
        dueDate: dueDate,
        dueTimeMinutes: dueTimeMinutes,
        assigneeId: assigneeId,
      );
    }
  }

  Future<void> updateTask(
    Task task, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    final existing = await getById(task.id);
    final requiredAction = existing == null
        ? FamilyAction.editAnyTask
        : taskUpdateAction(existing, task, actingMemberId);
    if (!canPerform(actingRole, requiredAction)) {
      throw FamilyPermissionException(requiredAction, actingRole);
    }
    await _db.update(_db.tasks).replace(
          task.copyWith(updatedAt: DateTime.now()),
        );
    if (task.dueDate != null && !task.isCompleted) {
      await _scheduleReminders(
        id: task.id,
        title: task.title,
        dueDate: task.dueDate!,
        dueTimeMinutes: task.dueTimeMinutes,
        assigneeId: task.assigneeId,
      );
    } else {
      await _cancelReminders(task.id);
    }
  }

  Future<void> setCompleted(
    String id,
    bool isCompleted, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (task != null) {
      final isOwnTask = actingMemberId != null && task.assigneeId == actingMemberId;
      final action =
          isOwnTask ? FamilyAction.completeOwnTask : FamilyAction.completeAnyTask;
      if (!canPerform(actingRole, action)) {
        throw FamilyPermissionException(action, actingRole);
      }
    }
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        completedByMemberId: Value(isCompleted ? actingMemberId : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (task == null) return;
    if (isCompleted) {
      await _cancelReminders(id);
      if (task.recurrence != TaskRecurrence.none) {
        // The new occurrence continues the same recurring series, so it
        // keeps the series' original creator — not whoever happened to
        // complete this particular instance.
        await addTask(
          id: const Uuid().v4(),
          title: task.title,
          description: task.description,
          dueDate: _nextOccurrence(task.dueDate ?? DateTime.now(), task.recurrence),
          dueTimeMinutes: task.dueTimeMinutes,
          priority: task.priority,
          category: task.category,
          assigneeId: task.assigneeId,
          recurrence: task.recurrence,
          actingMemberId: task.createdByMemberId,
        );
      }
    } else if (task.dueDate != null) {
      await _scheduleReminders(
        id: id,
        title: task.title,
        dueDate: task.dueDate!,
        dueTimeMinutes: task.dueTimeMinutes,
        assigneeId: task.assigneeId,
      );
    }
  }

  /// The "Tomorrow" quick-recovery action for an overdue task: moves the
  /// due date forward without touching its time-of-day (or lack of one),
  /// so a task that was due "at 6 PM" is now due tomorrow at 6 PM rather
  /// than losing its scheduled time.
  Future<void> rescheduleToTomorrow(
    String id, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    final task = await getById(id);
    if (task == null) return;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await updateTask(
      task.copyWith(dueDate: Value(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))),
      actingRole: actingRole,
      actingMemberId: actingMemberId,
    );
  }

  DateTime _nextOccurrence(DateTime from, TaskRecurrence recurrence) {
    return switch (recurrence) {
      TaskRecurrence.daily => from.add(const Duration(days: 1)),
      TaskRecurrence.weekly => from.add(const Duration(days: 7)),
      TaskRecurrence.monthly =>
        DateTime(from.year, from.month + 1, from.day, from.hour, from.minute),
      TaskRecurrence.none => from,
    };
  }

  Future<void> deleteTask(
    String id, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    final task = await getById(id);
    if (task != null && !canDeleteTask(task, actingRole, actingMemberId)) {
      throw FamilyPermissionException(FamilyAction.deleteTask, actingRole);
    }
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    await _notifications.cancelTaskReminder(id);
  }
}
