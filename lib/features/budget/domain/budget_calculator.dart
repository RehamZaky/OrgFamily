import '../../../data/local/database.dart';
import '../../../data/local/tables/budget_table.dart';

/// The [start, end) instant range covering every date that falls in [month]
/// (only the year/month of [month] matter — day/time are ignored), for
/// filtering a transaction list down to "this month's" activity.
class MonthRange {
  const MonthRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
}

MonthRange monthRange(DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return MonthRange(start, end);
}

int expenseTotalCents(List<BudgetTransaction> txns, MonthRange range) {
  return txns
      .where((t) => t.type == TransactionType.expense && range.contains(t.date))
      .fold(0, (sum, t) => sum + t.amountCents);
}

int incomeTotalCents(List<BudgetTransaction> txns, MonthRange range) {
  return txns
      .where((t) => t.type == TransactionType.income && range.contains(t.date))
      .fold(0, (sum, t) => sum + t.amountCents);
}

/// Expense-only totals grouped by category, for the spending donut/legend
/// and the Budget screen's per-category rows. Categories with no spend in
/// [range] are simply absent from the result rather than mapped to zero.
Map<TransactionCategory, int> categoryTotalsCents(
  List<BudgetTransaction> txns,
  MonthRange range,
) {
  final totals = <TransactionCategory, int>{};
  for (final t in txns) {
    if (t.type != TransactionType.expense || !range.contains(t.date)) continue;
    totals[t.category] = (totals[t.category] ?? 0) + t.amountCents;
  }
  return totals;
}

/// Income minus expense for [range] — the Reports screen's "Savings" tab.
int savingsTotalCents(List<BudgetTransaction> txns, MonthRange range) {
  return incomeTotalCents(txns, range) - expenseTotalCents(txns, range);
}

enum BudgetWarningLevel { ok, approaching, exceeded }

/// [approaching] once spending reaches 80% of the limit, [exceeded] past
/// 100% — the thresholds the UI colors a progress bar by (green/orange/red).
/// A null or zero [limitCents] (no budget set yet) is always [ok] — there's
/// nothing to warn against.
BudgetWarningLevel warningLevel(int spentCents, int? limitCents) {
  if (limitCents == null || limitCents <= 0) return BudgetWarningLevel.ok;
  if (spentCents > limitCents) return BudgetWarningLevel.exceeded;
  if (spentCents >= limitCents * 0.8) return BudgetWarningLevel.approaching;
  return BudgetWarningLevel.ok;
}

/// Null when no limit is set yet (distinct from a limit of zero remaining).
int? remainingCents(int? limitCents, int spentCents) {
  if (limitCents == null) return null;
  return limitCents - spentCents;
}

/// Sum of every category's limit — how much of the total budget has been
/// assigned to a category so far. Categories are allowed to add up to less
/// than the total (leaving some "flexible" / unallocated) or more (over
/// budget); neither is enforced at the data layer.
int categoryLimitTotalCents(Map<TransactionCategory, int> categoryLimits) {
  return categoryLimits.values.fold(0, (sum, cents) => sum + cents);
}

/// [totalLimitCents] minus what's already assigned across categories. Null
/// when no total budget is set yet. Negative when category limits add up to
/// more than the total — the family has over-allocated.
int? unallocatedBudgetCents(int? totalLimitCents, int categoryLimitTotalCents) {
  if (totalLimitCents == null) return null;
  return totalLimitCents - categoryLimitTotalCents;
}
