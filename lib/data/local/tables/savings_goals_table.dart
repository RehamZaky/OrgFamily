import 'package:drift/drift.dart';

import 'family_members_table.dart';

enum SavingsGoalIcon { vacation, gadget, emergency, education, home, car, gift, other }
// New icons only ever get appended at the end — same ordinal-safety rule as
// TransactionCategory in budget_table.dart.

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get icon =>
      intEnum<SavingsGoalIcon>().withDefault(const Constant(7))();
  IntColumn get targetCents => integer()();
  /// Manually updated by a "Contribute" action — deliberately not derived
  /// from BudgetTransactions. Linking goal contributions to the expense
  /// ledger is a reasonable future step, but keeping them independent for
  /// now avoids reconciliation logic nobody asked for.
  IntColumn get savedCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get createdByMemberId =>
      text().nullable().references(FamilyMembers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
