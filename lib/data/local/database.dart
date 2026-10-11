import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/budget_table.dart';
import 'tables/events_table.dart';
import 'tables/family_activities_table.dart';
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
    FamilyActivities,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 18;

  /// Whether [table] already has [column] — lets a migration step check
  /// before altering, so it's safe to resume after a partial failure (see
  /// the `from < 14` migration step's comment for why that's not just a
  /// hypothetical).
  Future<bool> _columnExists(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.data['name'] == column);
  }

  Future<bool> _tableExists(String table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(table)],
    ).get();
    return rows.isNotEmpty;
  }

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
            // to reach Firestore" queue.
            //
            // Every step here checks whether it already applied before
            // doing anything — not just for a hypothetical retry, but
            // because it's exactly what already happened once during
            // development: an earlier version of this migration crashed
            // partway through (SQLite's `ALTER TABLE ADD COLUMN`, unlike
            // `CREATE TABLE`, rejects a non-constant default), leaving some
            // columns added and others not on any device that hit it. This
            // makes the whole block safe to resume from that or any other
            // partial state, not just safe to run once cleanly.
            Future<void> addUpdatedAtWithBackfill(String table) async {
              if (await _columnExists(table, 'updated_at')) return;
              // The constant-default restriction means this column's
              // SQL-level default is a placeholder (0), not
              // currentDateAndTime — every insert path for these tables
              // must stamp updatedAt explicitly rather than relying on it
              // (see family_repository.dart/event_repository.dart/
              // shopping_repository.dart's addMember/addEvent/addList/
              // addItem).
              await customStatement(
                'ALTER TABLE $table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
              );
              await customStatement("UPDATE $table SET updated_at = strftime('%s', 'now')");
            }

            await addUpdatedAtWithBackfill('family_members');
            await addUpdatedAtWithBackfill('family_profile');
            await addUpdatedAtWithBackfill('events');
            await addUpdatedAtWithBackfill('shopping_lists');
            await addUpdatedAtWithBackfill('shopping_items');

            if (!await _columnExists('tasks', 'deleted_at')) {
              await m.addColumn(tasks, tasks.deletedAt);
            }
            if (!await _columnExists('family_members', 'deleted_at')) {
              await m.addColumn(familyMembers, familyMembers.deletedAt);
            }
            if (!await _columnExists('family_profile', 'initial_cloud_migration_completed_at')) {
              await m.addColumn(
                familyProfile,
                familyProfile.initialCloudMigrationCompletedAt,
              );
            }
            if (!await _columnExists('events', 'deleted_at')) {
              await m.addColumn(events, events.deletedAt);
            }
            if (!await _columnExists('shopping_lists', 'deleted_at')) {
              await m.addColumn(shoppingLists, shoppingLists.deletedAt);
            }
            if (!await _columnExists('shopping_items', 'deleted_at')) {
              await m.addColumn(shoppingItems, shoppingItems.deletedAt);
            }
            if (!await _tableExists('sync_outbox')) {
              await m.createTable(syncOutbox);
            }
          }
          if (from < 15) {
            // Local record of which uid joined this family via an invite on
            // this device — sync is now gated on "owner or invite-joined",
            // not just "signed in" (see family_profile_table.dart).
            if (!await _columnExists('family_profile', 'joined_uid')) {
              await m.addColumn(familyProfile, familyProfile.joinedUid);
            }
          }
          if (from < 16) {
            // Outbox rows now record which account made each change, and
            // only that account's changes drain automatically. Rows queued
            // before this have no recorded origin, so none of them can be
            // attributed safely — hold them all for a member to review
            // rather than upload them under whoever signs in next.
            if (!await _columnExists('sync_outbox', 'origin_uid')) {
              await m.addColumn(syncOutbox, syncOutbox.originUid);
            }
            await customStatement(
              'UPDATE sync_outbox SET status = ${SyncOutboxStatus.held.index}',
            );
          }
          if (from < 17) {
            // Responsibilities join Firestore sync, and initial
            // reconciliation becomes per collection (see
            // family_profile_table.dart's reconciledEntityTypes).
            if (!await _columnExists('responsibilities', 'updated_at')) {
              await customStatement(
                'ALTER TABLE responsibilities ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
              );
              await customStatement(
                "UPDATE responsibilities SET updated_at = strftime('%s', 'now')",
              );
            }
            if (!await _columnExists('responsibilities', 'deleted_at')) {
              await m.addColumn(responsibilities, responsibilities.deletedAt);
            }
            if (!await _columnExists('family_profile', 'reconciled_entity_types')) {
              await m.addColumn(familyProfile, familyProfile.reconciledEntityTypes);
            }
            // Families that already finished their (then all-at-once) first
            // pass have reconciled every collection that existed at the
            // time — record those, so only responsibilities gets a first
            // pass now.
            await customStatement(
              "UPDATE family_profile SET reconciled_entity_types = "
              "'familyProfile,familyMember,task,event,shoppingList,shoppingItem' "
              'WHERE initial_cloud_migration_completed_at IS NOT NULL',
            );
          }
          if (from < 18) {
            // V2.1 Family Activity log (family_activities_table.dart).
            if (!await _tableExists('family_activities')) {
              await m.createTable(familyActivities);
            }
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'org_family_db');
  }
}
