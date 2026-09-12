import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../data/providers.dart';
import '../domain/budget_calculator.dart';

final allTransactionsProvider = StreamProvider<List<BudgetTransaction>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchTransactions();
});

final categoryLimitsProvider = StreamProvider<List<BudgetCategoryLimit>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchCategoryLimits();
});

final budgetSettingsProvider = StreamProvider<BudgetSetting?>((ref) {
  return ref.watch(budgetRepositoryProvider).watchSettings();
});

/// The month Overview/Budget/Reports are currently showing — defaults to
/// the current month. Held as the first instant of that month, matching
/// [monthRange]'s input.
final selectedBudgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final _selectedMonthRangeProvider = Provider<MonthRange>((ref) {
  return monthRange(ref.watch(selectedBudgetMonthProvider));
});

final monthExpenseTotalCentsProvider = Provider<int>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return expenseTotalCents(txns, ref.watch(_selectedMonthRangeProvider));
});

final monthIncomeTotalCentsProvider = Provider<int>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return incomeTotalCents(txns, ref.watch(_selectedMonthRangeProvider));
});

final categoryTotalsCentsProvider = Provider<Map<TransactionCategory, int>>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return categoryTotalsCents(txns, ref.watch(_selectedMonthRangeProvider));
});

/// Map from category to its recurring limit, for quick lookup by the
/// Budget screen's per-category rows.
final categoryLimitMapProvider = Provider<Map<TransactionCategory, int>>((ref) {
  final limits = ref.watch(categoryLimitsProvider).valueOrNull ?? [];
  return {for (final l in limits) l.category: l.limitCents};
});

final totalLimitCentsProvider = Provider<int?>((ref) {
  return ref.watch(budgetSettingsProvider).valueOrNull?.totalLimitCents;
});

final categoryLimitTotalCentsProvider = Provider<int>((ref) {
  return categoryLimitTotalCents(ref.watch(categoryLimitMapProvider));
});

/// Total budget minus what's already assigned to categories — the "Flexible
/// / unallocated" amount shown on the Set Budget sheet. Negative when
/// category limits add up to more than the total.
final unallocatedBudgetCentsProvider = Provider<int?>((ref) {
  return unallocatedBudgetCents(
    ref.watch(totalLimitCentsProvider),
    ref.watch(categoryLimitTotalCentsProvider),
  );
});

/// Falls back to EGP (matching [BudgetSettings.currencyCode]'s own column
/// default) before the settings row has ever been written.
final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(budgetSettingsProvider).valueOrNull?.currencyCode ?? 'EGP';
});

final remainingBudgetCentsProvider = Provider<int?>((ref) {
  return remainingCents(
    ref.watch(totalLimitCentsProvider),
    ref.watch(monthExpenseTotalCentsProvider),
  );
});

/// All-time income minus all-time expenses — the Overview screen's "Total
/// Balance" card, not scoped to the selected month.
final totalBalanceCentsProvider = Provider<int>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  var balance = 0;
  for (final t in txns) {
    if (t.type == TransactionType.income) balance += t.amountCents;
    if (t.type == TransactionType.expense) balance -= t.amountCents;
  }
  return balance;
});
