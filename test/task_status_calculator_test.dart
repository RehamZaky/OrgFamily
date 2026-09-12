import 'package:flutter_test/flutter_test.dart';
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
}
