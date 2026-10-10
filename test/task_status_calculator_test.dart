import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/features/tasks/domain/task_status_calculator.dart';

void main() {
  group('isTaskOverdue', () {
    test('timed task becomes overdue right after its due time', () {
      final input = TaskDeadlineInput(
        dueDate: DateTime(2026, 9, 8),
        dueTimeMinutes: 18 * 60, // 6:00 PM
        isCompleted: false,
      );
      expect(isTaskOverdue(input, DateTime(2026, 9, 8, 17, 59)), isFalse);
      expect(isTaskOverdue(input, DateTime(2026, 9, 8, 18, 0)), isFalse);
      expect(isTaskOverdue(input, DateTime(2026, 9, 8, 18, 1)), isTrue);
    });

    test('date-only task stays due (not overdue) until the day ends', () {
      final input = TaskDeadlineInput(
        dueDate: DateTime(2026, 9, 8),
        dueTimeMinutes: null,
        isCompleted: false,
      );
      expect(isTaskOverdue(input, DateTime(2026, 9, 8, 0, 0)), isFalse);
      expect(isTaskOverdue(input, DateTime(2026, 9, 8, 23, 59)), isFalse);
      expect(isTaskOverdue(input, DateTime(2026, 9, 9, 0, 0)), isFalse);
      expect(isTaskOverdue(input, DateTime(2026, 9, 9, 0, 1)), isTrue);
    });

    test('a task with no due date is never overdue', () {
      final input = TaskDeadlineInput(
        dueDate: null,
        dueTimeMinutes: null,
        isCompleted: false,
      );
      expect(isTaskOverdue(input, DateTime(2099)), isFalse);
    });

    test('a completed task is never overdue, even past its deadline', () {
      final input = TaskDeadlineInput(
        dueDate: DateTime(2020, 1, 1),
        dueTimeMinutes: 0,
        isCompleted: true,
      );
      expect(isTaskOverdue(input, DateTime(2026, 9, 8)), isFalse);
    });
  });

  group('daysOverdue', () {
    test('0 on the day it goes overdue, increments once per day after', () {
      final input = TaskDeadlineInput(
        dueDate: DateTime(2026, 9, 8),
        dueTimeMinutes: null,
        isCompleted: false,
      );
      expect(daysOverdue(input, DateTime(2026, 9, 9)), 0);
      expect(daysOverdue(input, DateTime(2026, 9, 10)), 1);
      expect(daysOverdue(input, DateTime(2026, 9, 13)), 4);
    });
  });

  group('taskReminderNotifyAt', () {
    final deadline = TaskDeadlineInput(
      dueDate: DateTime(2026, 9, 8),
      dueTimeMinutes: 18 * 60, // 6:00 PM
      isCompleted: false,
    );

    test('dueTime notifies exactly at the due moment', () {
      final input = TaskReminderInput(
        deadline: deadline,
        reminderType: TaskReminderType.dueTime,
        reminderOffsetMinutes: null,
        reminderAt: null,
      );
      expect(taskReminderNotifyAt(input), DateTime(2026, 9, 8, 18, 0));
    });

    test('offset notifies that many minutes before the due moment', () {
      final input = TaskReminderInput(
        deadline: deadline,
        reminderType: TaskReminderType.offset,
        reminderOffsetMinutes: 60,
        reminderAt: null,
      );
      expect(taskReminderNotifyAt(input), DateTime(2026, 9, 8, 17, 0));
    });

    test('custom notifies at the explicit reminderAt, ignoring the due date', () {
      final input = TaskReminderInput(
        deadline: deadline,
        reminderType: TaskReminderType.custom,
        reminderOffsetMinutes: null,
        reminderAt: DateTime(2026, 9, 1, 8, 0),
      );
      expect(taskReminderNotifyAt(input), DateTime(2026, 9, 1, 8, 0));
    });

    test('none never notifies', () {
      final input = TaskReminderInput(
        deadline: deadline,
        reminderType: TaskReminderType.none,
        reminderOffsetMinutes: null,
        reminderAt: null,
      );
      expect(taskReminderNotifyAt(input), isNull);
    });

    test('no due date never notifies, even with dueTime/offset selected', () {
      final noDueDate = TaskDeadlineInput(
        dueDate: null,
        dueTimeMinutes: null,
        isCompleted: false,
      );
      expect(
        taskReminderNotifyAt(TaskReminderInput(
          deadline: noDueDate,
          reminderType: TaskReminderType.dueTime,
          reminderOffsetMinutes: null,
          reminderAt: null,
        )),
        isNull,
      );
      expect(
        taskReminderNotifyAt(TaskReminderInput(
          deadline: noDueDate,
          reminderType: TaskReminderType.offset,
          reminderOffsetMinutes: 15,
          reminderAt: null,
        )),
        isNull,
      );
    });
  });
}
