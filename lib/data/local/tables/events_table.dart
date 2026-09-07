import 'package:drift/drift.dart';

import 'family_members_table.dart';

enum EventCategory {
  birthday,
  school,
  appointment,
  work,
  travel,
  home,
  family,
  other,
}

class Events extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get category =>
      intEnum<EventCategory>().withDefault(const Constant(7))();
  TextColumn get memberId =>
      text().nullable().references(FamilyMembers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
