import 'package:drift/drift.dart';

enum FamilyRole { owner, adult, child }

class FamilyMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarEmoji => text().withDefault(const Constant('👨'))();
  TextColumn get photoPath => text().nullable()();
  IntColumn get colorValue => integer()();
  IntColumn get role =>
      intEnum<FamilyRole>().withDefault(const Constant(1))();
  DateTimeColumn get birthday => dateTime().nullable()();
  TextColumn get grade => text().nullable()();
  TextColumn get school => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
