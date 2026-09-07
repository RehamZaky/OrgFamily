import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TaskRepository(db, FakeNotificationService());
  });

  tearDown(() => db.close());

  test('completing a daily recurring task regenerates the next occurrence',
      () async {
    final dueDate = DateTime(2026, 1, 10, 9, 0);
    await repo.addTask(
      id: 't1',
      title: 'Water the plants',
      dueDate: dueDate,
      recurrence: TaskRecurrence.daily,
    );

    await repo.setCompleted('t1', true);

    final all = await db.select(db.tasks).get();
    expect(all.length, 2);

    final original = all.firstWhere((t) => t.id == 't1');
    expect(original.isCompleted, isTrue);

    final regenerated = all.firstWhere((t) => t.id != 't1');
    expect(regenerated.isCompleted, isFalse);
    expect(regenerated.title, 'Water the plants');
    expect(regenerated.dueDate, dueDate.add(const Duration(days: 1)));
    expect(regenerated.recurrence, TaskRecurrence.daily);
  });

  test('completing a monthly recurring task advances by one month', () async {
    final dueDate = DateTime(2026, 1, 31, 8, 0);
    await repo.addTask(
      id: 't2',
      title: 'Pay rent',
      dueDate: dueDate,
      recurrence: TaskRecurrence.monthly,
    );

    await repo.setCompleted('t2', true);

    final all = await db.select(db.tasks).get();
    final regenerated = all.firstWhere((t) => t.id != 't2');
    // DateTime normalizes day-31-of-February overflow into March.
    expect(regenerated.dueDate, DateTime(2026, 3, 3, 8, 0));
  });

  test('completing a non-recurring task does not create a new one', () async {
    await repo.addTask(id: 't3', title: 'One-off errand');
    await repo.setCompleted('t3', true);

    final all = await db.select(db.tasks).get();
    expect(all.length, 1);
  });
}
