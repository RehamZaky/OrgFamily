import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/events_table.dart';
import 'tables/family_members_table.dart';
import 'tables/family_profile_table.dart';
import 'tables/notes_table.dart';
import 'tables/responsibilities_table.dart';
import 'tables/shopping_table.dart';
import 'tables/tasks_table.dart';

part 'database.g.dart';

/// Default shopping list categories seeded for every new family database, so
/// there's always somewhere obvious to add items — users can still create
/// more lists beyond these.
const defaultShoppingCategories = [
  ('default-grocery', 'Groceries', '🛒'),
  ('default-vacation', 'Vacation packing', '🏖️'),
  ('default-school', 'School supplies', '🏫'),
  ('default-car', 'Car', '🚗'),
  ('default-home', 'Home purchases', '🏠'),
  ('default-gifts', 'Gifts', '🎁'),
];

@DriftDatabase(
  tables: [
    FamilyMembers,
    Tasks,
    Events,
    ShoppingLists,
    ShoppingItems,
    Responsibilities,
    Notes,
    FamilyProfile,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(familyMembers, familyMembers.photoPath);
            await m.addColumn(familyMembers, familyMembers.birthday);
            await m.addColumn(familyMembers, familyMembers.grade);
            await m.addColumn(familyMembers, familyMembers.school);
            await m.addColumn(familyMembers, familyMembers.notes);
          }
          if (from < 3) {
            await m.createTable(responsibilities);
          }
          if (from < 4) {
            await m.createTable(notes);
          }
          if (from < 5) {
            await m.createTable(familyProfile);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'org_family_db');
  }
}
