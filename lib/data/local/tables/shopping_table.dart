import 'package:drift/drift.dart';

import 'family_members_table.dart';

class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant('🛒'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Firestore sync bookkeeping — see `tasks_table.dart`'s `updatedAt`/
  /// `deletedAt` doc comments. Deleting a list now soft-deletes every item
  /// under it too (see `ShoppingRepository.deleteList`) rather than relying
  /// on the SQL cascade below, since a soft-delete never actually removes
  /// the list row for the cascade to trigger on.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get quantity => text().nullable()();
  BoolColumn get isPurchased => boolean().withDefault(const Constant(false))();
  TextColumn get addedById =>
      text().nullable().references(FamilyMembers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Firestore sync bookkeeping — see `tasks_table.dart`'s `updatedAt`/
  /// `deletedAt` doc comments.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
