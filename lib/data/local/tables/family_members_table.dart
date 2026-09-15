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
  // The Firebase uid this member is linked to, once an Owner/Adult signs
  // in and claims this row — see docs/architecture.md "Family identity
  // and authentication". Always null for Child members; also null for an
  // Owner/Adult who hasn't linked an account yet (including every
  // pre-V2-Auth local family on upgrade).
  TextColumn get linkedUid => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
