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
  /// Minutes since midnight, only when the user explicitly picked a time —
  /// null means "date only". Distinct from [dueDate] just being midnight,
  /// which would otherwise be ambiguous with a genuinely-chosen midnight
  /// deadline. Kept in sync with [dueDate]'s own time-of-day when set, so
  /// existing date-grouping/sorting code can keep reading [dueDate] as-is;
  /// this only exists for the overdue calculator and UI to tell "due
  /// exactly at 6pm" apart from "due sometime today".
  IntColumn get dueTimeMinutes => integer().nullable()();
  IntColumn get priority =>
      intEnum<TaskPriority>().withDefault(const Constant(1))();
  IntColumn get category =>
      intEnum<TaskCategory>().withDefault(const Constant(11))();
  TextColumn get assigneeId =>
      text().nullable().references(FamilyMembers, #id)();
  /// Who created this task — set once at insert and never touched again,
  /// regardless of who edits, reschedules, or completes it afterward. Used
  /// to decide who's allowed to delete it (see canDeleteTask): the
  /// assignee can complete or reschedule their own task, but shouldn't be
  /// able to make someone else's task disappear entirely.
  TextColumn get createdByMemberId =>
      text().nullable().references(FamilyMembers, #id)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  /// Who last marked this task done — cleared back to null if it's
  /// un-completed, mirroring [completedAt]. For the family activity feed
  /// ("Ahmed completed Buy groceries"), distinct from [assigneeId] since
  /// completion doesn't require being the assignee.
  TextColumn get completedByMemberId =>
      text().nullable().references(FamilyMembers, #id)();
  IntColumn get recurrence =>
      intEnum<TaskRecurrence>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
