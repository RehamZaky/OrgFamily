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
  /// Superseded by the [EventMembers] join table (an event can now have
  /// more than one person attached) — kept only so a pre-migration event's
  /// single assignee survives as data; new code should read/write
  /// EventMembers instead, never this column.
  TextColumn get memberId =>
      text().nullable().references(FamilyMembers, #id)();
  /// Overrides the category's default color when set — lets a family pick
  /// a specific event a distinct color instead of always following its
  /// category.
  IntColumn get colorValue => integer().nullable()();
  /// Local file path to a single attached photo (e.g. a ticket, invite, or
  /// flyer) — same on-device storage pattern as member/family photos.
  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many: which family members are attached to which event. An
/// event with zero rows here is unassigned; one row is a single-person
/// event; two or more is a shared/family event.
class EventMembers extends Table {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get memberId => text().references(FamilyMembers, #id)();

  @override
  Set<Column> get primaryKey => {eventId, memberId};
}
