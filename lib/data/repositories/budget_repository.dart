import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/budget_table.dart';
import '../local/tables/family_members_table.dart';

/// Fixed id for the singleton [BudgetSettings] row — there's only ever one,
/// holding the family's total monthly budget.
const _budgetSettingsId = 'default';

class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  Future<BudgetTransaction?> getTransactionById(String id) {
    return (_db.select(_db.budgetTransactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<BudgetTransaction>> watchTransactions({TransactionType? type}) {
    final query = _db.select(_db.budgetTransactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (type != null) {
      query.where((t) => t.type.equalsValue(type));
    }
    return query.watch();
  }

  Future<void> addTransaction({
    required String id,
    required TransactionType type,
    required int amountCents,
    required TransactionCategory category,
    required IncomeSource incomeSource,
    required Account account,
    required Account toAccount,
    required String title,
    String? note,
    required DateTime date,
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageTransactions)) {
      throw FamilyPermissionException(FamilyAction.manageTransactions, actingRole);
    }
    await _db.into(_db.budgetTransactions).insert(
          BudgetTransactionsCompanion.insert(
            id: id,
            type: Value(type),
            amountCents: amountCents,
            category: Value(category),
            incomeSource: Value(incomeSource),
            account: Value(account),
            toAccount: Value(toAccount),
            title: title,
            note: Value(note),
            date: date,
            createdByMemberId: Value(actingMemberId),
          ),
        );
  }

  Future<void> updateTransaction(
    BudgetTransaction txn, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageTransactions)) {
      throw FamilyPermissionException(FamilyAction.manageTransactions, actingRole);
    }
    await _db.update(_db.budgetTransactions).replace(
          txn.copyWith(updatedAt: DateTime.now()),
        );
  }

  Future<void> deleteTransaction(
    String id, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageTransactions)) {
      throw FamilyPermissionException(FamilyAction.manageTransactions, actingRole);
    }
    await (_db.delete(_db.budgetTransactions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<BudgetCategoryLimit>> watchCategoryLimits() {
    return _db.select(_db.budgetCategoryLimits).watch();
  }

  /// Upserts the limit for [category] — one row per category, so this
  /// replaces whatever limit already existed for it rather than adding a
  /// second one.
  Future<void> setCategoryLimit({
    required TransactionCategory category,
    required int limitCents,
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageBudget)) {
      throw FamilyPermissionException(FamilyAction.manageBudget, actingRole);
    }
    final existing = await (_db.select(_db.budgetCategoryLimits)
          ..where((l) => l.category.equalsValue(category)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.budgetCategoryLimits)..where((l) => l.id.equals(existing.id)))
          .write(BudgetCategoryLimitsCompanion(
        limitCents: Value(limitCents),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await _db.into(_db.budgetCategoryLimits).insert(
            BudgetCategoryLimitsCompanion.insert(
              id: const Uuid().v4(),
              category: category,
              limitCents: limitCents,
            ),
          );
    }
  }

  Future<void> deleteCategoryLimit(
    TransactionCategory category, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageBudget)) {
      throw FamilyPermissionException(FamilyAction.manageBudget, actingRole);
    }
    await (_db.delete(_db.budgetCategoryLimits)..where((l) => l.category.equalsValue(category)))
        .go();
  }

  Stream<BudgetSetting?> watchSettings() {
    return (_db.select(_db.budgetSettings)..where((s) => s.id.equals(_budgetSettingsId)))
        .watchSingleOrNull();
  }

  Future<void> setTotalLimit(
    int limitCents, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageBudget)) {
      throw FamilyPermissionException(FamilyAction.manageBudget, actingRole);
    }
    await _db.into(_db.budgetSettings).insertOnConflictUpdate(
          BudgetSettingsCompanion.insert(
            id: _budgetSettingsId,
            totalLimitCents: Value(limitCents),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> setCurrencyCode(
    String currencyCode, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageBudget)) {
      throw FamilyPermissionException(FamilyAction.manageBudget, actingRole);
    }
    await _db.into(_db.budgetSettings).insertOnConflictUpdate(
          BudgetSettingsCompanion.insert(
            id: _budgetSettingsId,
            currencyCode: Value(currencyCode),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
