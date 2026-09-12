import 'package:drift/drift.dart';

import 'family_members_table.dart';

enum TransactionType { expense, income, transfer }

/// *Why* income came in — a separate axis from [Account], which tracks
/// *where* the money physically sits. Meaningful for income transactions
/// only; expense keeps using [TransactionCategory] for "what it was for".
enum IncomeSource { salary, freelance, business, bonus, gift, refund, other }
// Same append-only rule as TransactionCategory — ordinal is persisted.

/// The physical account money moved through. For expense/income this is
/// [BudgetTransactions.account] alone (paid from / received into); for a
/// transfer it's the pair [BudgetTransactions.account] (from) and
/// [BudgetTransactions.toAccount] (to) — so "Cash -> Bank" is representable
/// instead of a single vague "source".
enum Account { cash, bank, wallet, other }
// Same append-only rule as TransactionCategory — ordinal is persisted.

enum TransactionCategory {
  groceries,
  transport,
  bills,
  shopping,
  health,
  education,
  foodDrinks,
  other,
}
// New categories only ever get appended at the end — the ordinal is what's
// stored in the DB (see TransactionCategory's intEnum column below), so
// inserting or reordering values would silently reclassify every existing
// transaction.

class BudgetTransactions extends Table {
  TextColumn get id => text()();
  IntColumn get type =>
      intEnum<TransactionType>().withDefault(const Constant(0))();
  /// Integer minor units (cents), not a float — avoids rounding drift when
  /// summing a long-running ledger.
  IntColumn get amountCents => integer()();
  IntColumn get category =>
      intEnum<TransactionCategory>().withDefault(const Constant(7))();
  IntColumn get incomeSource =>
      intEnum<IncomeSource>().withDefault(const Constant(6))();
  IntColumn get account => intEnum<Account>().withDefault(const Constant(0))();
  /// Only meaningful when [type] is [TransactionType.transfer] — the
  /// destination account, with [account] itself acting as the source.
  IntColumn get toAccount => intEnum<Account>().withDefault(const Constant(0))();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get createdByMemberId =>
      text().nullable().references(FamilyMembers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One recurring limit per category, applied to every month until edited —
/// there's no per-month history. Keeps "set it once, it applies going
/// forward" behavior without building month-by-month versioning nobody
/// asked for yet.
class BudgetCategoryLimits extends Table {
  TextColumn get id => text()();
  IntColumn get category => intEnum<TransactionCategory>()();
  IntColumn get limitCents => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Singleton row (fixed id `'default'`) holding the total monthly budget —
/// same "recurring, not versioned per month" choice as
/// [BudgetCategoryLimits].
class BudgetSettings extends Table {
  TextColumn get id => text()();
  IntColumn get totalLimitCents => integer().nullable()();
  /// ISO 4217 code (e.g. `EGP`, `USD`) — the family's one shared currency,
  /// changeable from the Set Budget sheet. Defaults to EGP.
  TextColumn get currencyCode =>
      text().withDefault(const Constant('EGP'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
