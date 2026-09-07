import 'package:drift/drift.dart';

import 'family_members_table.dart';

enum TaskPriority { low, normal, high, urgent }

enum TaskRecurrence { none, daily, weekly, monthly }

enum TaskCategory {
  home,
  shopping,
  finance,
  school,
  car,
  chores,
  family,
  events,
  appointments,
  errands,
  work,
  other,
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority =>
      intEnum<TaskPriority>().withDefault(const Constant(1))();
  IntColumn get category =>
      intEnum<TaskCategory>().withDefault(const Constant(11))();
  TextColumn get assigneeId =>
      text().nullable().references(FamilyMembers, #id)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get recurrence =>
      intEnum<TaskRecurrence>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
