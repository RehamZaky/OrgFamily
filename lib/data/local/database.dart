import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/budget_table.dart';
import 'tables/events_table.dart';
import 'tables/family_members_table.dart';
import 'tables/family_profile_table.dart';
import 'tables/notes_table.dart';
import 'tables/responsibilities_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/shopping_table.dart';
import 'tables/sync_outbox_table.dart';
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
    EventMembers,
    ShoppingLists,
    ShoppingItems,
    Responsibilities,
    Notes,
    FamilyProfile,
    BudgetTransactions,
    BudgetCategoryLimits,
    BudgetSettings,
    SavingsGoals,
    SyncOutbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 14;

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
          if (from < 6) {
            await m.addColumn(tasks, tasks.dueTimeMinutes);
          }
          if (from < 7) {
            await m.addColumn(tasks, tasks.createdByMemberId);
            await m.addColumn(tasks, tasks.completedByMemberId);
          }
          if (from < 8) {
            await m.addColumn(events, events.colorValue);
            await m.addColumn(events, events.attachmentPath);
            await m.createTable(eventMembers);
            // Carry each pre-migration event's single assignee over into
            // the new join table, so switching to multi-person doesn't
            // silently un-assign existing events.
            await customStatement(
              'INSERT INTO event_members (event_id, member_id) '
              'SELECT id, member_id FROM events WHERE member_id IS NOT NULL',
            );
          }
          if (from < 9) {
            await m.createTable(budgetTransactions);
            await m.createTable(budgetCategoryLimits);
            await m.createTable(budgetSettings);
            await m.createTable(savingsGoals);
          }
          if (from < 10) {
            // `source` was replaced by IncomeSource + Account in the from <
            // 11 step below, so it no longer exists as a Dart column to
            // reference here — added via raw SQL to keep this historical
            // step buildable.
            await customStatement(
              'ALTER TABLE budget_transactions ADD COLUMN source INTEGER NOT NULL DEFAULT 4',
            );
          }
          if (from < 11) {
            // Source (a single "payment method" field) is replaced by
            // IncomeSource (why income came in) + Account (where the money
            // physically sits) — see budget_table.dart.
            await m.addColumn(budgetTransactions, budgetTransactions.incomeSource);
            await m.addColumn(budgetTransactions, budgetTransactions.account);
            await m.addColumn(budgetTransactions, budgetTransactions.toAccount);
            await m.dropColumn(budgetTransactions, 'source');
          }
          if (from < 12) {
            // V2 Auth: links an Owner/Adult FamilyMember to a Firebase
            // uid, and gives the family a stable id — see
            // docs/architecture.md "Family identity and authentication".
            // Purely additive, nullable columns: every existing row (and
            // every pre-Auth local family) keeps working unchanged.
            await m.addColumn(familyMembers, familyMembers.linkedUid);
            await m.addColumn(familyProfile, familyProfile.familyId);
            await m.addColumn(familyProfile, familyProfile.ownerUid);
          }
          if (from < 13) {
            // Reminder picker: a task's notification time can now differ
            // from its due date/time (a preset offset before due, an
            // explicit custom moment, or none at all) instead of always
            // firing exactly at the due time. reminderType's default
            // (dueTime) preserves every existing task's current behavior.
            await m.addColumn(tasks, tasks.reminderType);
            await m.addColumn(tasks, tasks.reminderOffsetMinutes);
            await m.addColumn(tasks, tasks.reminderAt);
          }
          if (from < 14) {
            // Firestore sync (see docs/architecture.md "Firestore sync"):
            // updatedAt drives last-write-wins conflict resolution,
            // deletedAt is a soft-delete tombstone (needed because "missing
            // remotely" is otherwise ambiguous between "never uploaded" and
            // "was deleted" once there are two persisted copies of the
            // data), and SyncOutbox is the durable "this write still needs
            // to reach Firestore" queue. Every existing row gets `updatedAt
            // = now` via the column default below, which is a reasonable
            // starting point — none of them have synced yet anyway.
            await m.addColumn(tasks, tasks.deletedAt);
            await m.addColumn(familyMembers, familyMembers.updatedAt);
            await m.addColumn(familyMembers, familyMembers.deletedAt);
            await m.addColumn(familyProfile, familyProfile.updatedAt);
            await m.addColumn(
              familyProfile,
              familyProfile.initialCloudMigrationCompletedAt,
            );
            await m.addColumn(events, events.updatedAt);
            await m.addColumn(events, events.deletedAt);
            await m.addColumn(shoppingLists, shoppingLists.updatedAt);
            await m.addColumn(shoppingLists, shoppingLists.deletedAt);
            await m.addColumn(shoppingItems, shoppingItems.updatedAt);
            await m.addColumn(shoppingItems, shoppingItems.deletedAt);
            await m.createTable(syncOutbox);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'org_family_db');
  }
}
