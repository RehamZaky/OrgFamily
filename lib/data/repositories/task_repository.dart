import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/utils/date_format_x.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/tasks_table.dart';

class TaskRepository {
  TaskRepository(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  /// "Due at 6:00 PM • Assigned to you" (or the member's name, or just the
  /// due-time clause when unassigned) — built fresh each time a reminder is
  /// (re)scheduled, from whatever the task's due date/assignee are then.
  Future<String> _reminderBody(DateTime dueDate, String? assigneeId) async {
    final due = 'Due at ${dueDate.timeLabel}';
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
    TaskPriority priority = TaskPriority.normal,
    TaskCategory category = TaskCategory.other,
    String? assigneeId,
    TaskRecurrence recurrence = TaskRecurrence.none,
  }) async {
    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            dueDate: Value(dueDate),
            priority: Value(priority),
            category: Value(category),
            assigneeId: Value(assigneeId),
            recurrence: Value(recurrence),
          ),
        );
    if (dueDate != null) {
      await _notifications.scheduleTaskReminder(
        taskId: id,
        title: title,
        body: await _reminderBody(dueDate, assigneeId),
        dueDate: dueDate,
      );
    }
  }

  Future<void> updateTask(Task task) async {
    await _db.update(_db.tasks).replace(
          task.copyWith(updatedAt: DateTime.now()),
        );
    if (task.dueDate != null && !task.isCompleted) {
      await _notifications.scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        body: await _reminderBody(task.dueDate!, task.assigneeId),
        dueDate: task.dueDate!,
      );
    } else {
      await _notifications.cancelTaskReminder(task.id);
    }
  }

  Future<void> setCompleted(String id, bool isCompleted) async {
    final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (task == null) return;
    if (isCompleted) {
      await _notifications.cancelTaskReminder(id);
      if (task.recurrence != TaskRecurrence.none) {
        await addTask(
          id: const Uuid().v4(),
          title: task.title,
          description: task.description,
          dueDate: _nextOccurrence(task.dueDate ?? DateTime.now(), task.recurrence),
          priority: task.priority,
          category: task.category,
          assigneeId: task.assigneeId,
          recurrence: task.recurrence,
        );
      }
    } else if (task.dueDate != null) {
      await _notifications.scheduleTaskReminder(
        taskId: id,
        title: task.title,
        body: await _reminderBody(task.dueDate!, task.assigneeId),
        dueDate: task.dueDate!,
      );
    }
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

  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    await _notifications.cancelTaskReminder(id);
  }
}
