import 'package:drift/drift.dart';

/// Family-wide settings (V2.2) — one row, synced to
/// `families/{familyId}/settings/{familyId}` and editable by the Owner only.
///
/// **No row means the defaults** (school days Sunday–Thursday, week starts
/// Sunday): nothing is created or uploaded until the Owner actually saves,
/// so existing families need no migration. See `FamilySchedule`.
class FamilySettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// `DateTime.weekday` numbers (Monday 1 … Sunday 7), comma-separated
  /// locally; a list of ints in Firestore. Decides when "school days"
  /// responsibilities are due — not the calendar's weekend shading.
  TextColumn get schoolWeekdays => text().withDefault(const Constant('7,1,2,3,4'))();

  /// `DateTime.weekday` the week starts on — calendar's first column and
  /// the start of every "this week" figure.
  IntColumn get weekStartDay => integer().withDefault(const Constant(DateTime.sunday))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
