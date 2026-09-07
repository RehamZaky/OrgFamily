import 'package:drift/drift.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get body => text()();

  /// Index into [AppColors.notePalette] (core/theme/app_colors.dart) —
  /// stored as an index rather than a raw color int so the palette can be
  /// retuned later without a migration.
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
