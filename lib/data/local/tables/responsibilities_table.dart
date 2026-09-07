import 'package:drift/drift.dart';

import 'family_members_table.dart';

/// How often a responsibility (chore) recurs. `custom` stores the specific
/// weekdays in `Responsibilities.customWeekdays`.
enum ResponsibilityRecurrence { daily, schoolDays, custom }

class Responsibilities extends Table {
  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(FamilyMembers, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get recurrence => intEnum<ResponsibilityRecurrence>()
      .withDefault(const Constant(0))();

  /// Comma-separated `DateTime.weekday` values (1=Monday..7=Sunday), only
  /// used when [recurrence] is `custom`.
  TextColumn get customWeekdays => text().nullable()();

  /// Midnight of the day this was last marked done — "done today" is
  /// checked by comparing this to the current date, so no separate
  /// per-occurrence completion log is needed.
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
