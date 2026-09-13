import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../l10n/app_localizations.dart';
import '../../goals/providers/savings_goal_providers.dart';
import '../../goals/screens/goals_screen.dart';
import '../../goals/widgets/add_goal_sheet.dart';
import '../domain/budget_calculator.dart';
import '../providers/budget_providers.dart';
import '../widgets/set_budget_sheet.dart';
import '../widgets/spending_donut_chart.dart';
import 'budget_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

class MoneyOverviewScreen extends ConsumerWidget {
  const MoneyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final balance = ref.watch(totalBalanceCentsProvider);
    final income = ref.watch(monthIncomeTotalCentsProvider);
    final expenses = ref.watch(monthExpenseTotalCentsProvider);
    final categoryTotals = ref.watch(categoryTotalsCentsProvider);
    final recent = (ref.watch(allTransactionsProvider).valueOrNull ?? []).take(5).toList();

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = categoryTotals.values.fold(0, (sum, v) => sum + v);

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) => CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0x14000000),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.primary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.moneyOverviewTitle,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.moneyOverviewTagline,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0x14000000),
                  child: Icon(Icons.notifications_none, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickLink(
                    icon: Icons.receipt_long_outlined,
                    label: l10n.transactionsTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickLink(
                    icon: Icons.pie_chart_outline,
                    label: l10n.moneyTileBudget,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickLink(
                    icon: Icons.savings_outlined,
                    label: l10n.moneyTileGoals,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GoalsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickLink(
                    icon: Icons.bar_chart_outlined,
                    label: l10n.reportsTitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.totalBalance,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                              formatCents(balance, currencyCode: currencyCode),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        // The source art is a static illustration on an
                        // opaque light background (not a transparent
                        // animation), so it gets its own white badge here
                        // instead of floating loose on the purple card.
                        child: Lottie.asset('assets/lottie/wallet_detailed_lottie.json'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InlineStat(
                          icon: Icons.arrow_upward_rounded,
                          label: l10n.income,
                          value: formatCents(income, currencyCode: currencyCode),
                        ),
                      ),
                      Expanded(
                        child: _InlineStat(
                          icon: Icons.arrow_downward_rounded,
                          label: l10n.expenses,
                          value: formatCents(expenses, currencyCode: currencyCode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.netThisMonth(formatCents(income - expenses, currencyCode: currencyCode)),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.thisMonth,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _BudgetMiniCard()),
                SizedBox(width: 10),
                Expanded(child: _SavingsMiniCard()),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader(title: l10n.spendingByCategory),
            const SizedBox(height: 4),
            Text(l10n.thisMonth,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            if (sortedCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(l10n.noTransactionsYet,
                      style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else if (sortedCategories.length == 1)
              Column(
                children: [
                  Text(
                    formatCents(totalSpent, currencyCode: currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  Text(l10n.expenses,
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                  const SizedBox(height: 12),
                  for (final e in sortedCategories)
                    _CategoryRow(
                      category: e.key,
                      amountCents: e.value,
                      totalCents: totalSpent,
                      currencyCode: currencyCode,
                      l10n: l10n,
                    ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpendingDonutChart(
                    sections: [
                      for (final e in sortedCategories)
                        DonutSection(e.key.color, e.value.toDouble()),
                    ],
                    centerLabel: formatCents(totalSpent, currencyCode: currencyCode),
                    centerSubLabel: l10n.expenses,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in sortedCategories)
                          _CategoryRow(
                            category: e.key,
                            amountCents: e.value,
                            totalCents: totalSpent,
                            currencyCode: currencyCode,
                            l10n: l10n,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.recentTransactions,
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              ),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(l10n.noTransactionsYet,
                      style: TextStyle(color: context.colors.textSecondary)),
                ),
              )
            else
              for (final t in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: t.displayColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t.displayIcon, size: 18, color: t.displayColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(t.displayLabel(l10n),
                                style: TextStyle(
                                    fontSize: 12, color: context.colors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        t.type == TransactionType.expense
                            ? '- ${formatCents(t.amountCents, currencyCode: currencyCode)}'
                            : '+ ${formatCents(t.amountCents, currencyCode: currencyCode)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.type == TransactionType.expense
                              ? AppColors.priorityUrgent
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// One category's line in the Spending by Category list — icon, name,
/// amount, and its share of the total, so the reader never has to compute
/// the amount from the percentage themselves.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountCents,
    required this.totalCents,
    required this.currencyCode,
    required this.l10n,
    this.compact = false,
  });

  final TransactionCategory category;
  final int amountCents;
  final int totalCents;
  final String currencyCode;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percent = totalCents == 0 ? 0 : (amountCents / totalCents * 100).round();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
      child: Row(
        children: [
          Container(
            width: compact ? 22 : 32,
            height: compact ? 22 : 32,
            decoration: BoxDecoration(color: category.color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(category.icon, size: compact ? 12 : 16, color: category.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(category.label(l10n), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            formatCents(amountCents, currencyCode: currencyCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text('$percent%',
                textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Income/Expenses line inside the (purple) Total Balance card — white text
/// on the tinted-circle icon rather than a separate colored card, so this
/// reads as detail on the balance rather than a competing headline.
class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact "are we within budget?" card — the answer Family Finances should
/// surface immediately rather than only inside the Budget screen.
class _BudgetMiniCard extends ConsumerWidget {
  const _BudgetMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final totalLimit = ref.watch(totalLimitCentsProvider);
    final spent = ref.watch(monthExpenseTotalCentsProvider);
    final remaining = ref.watch(remainingBudgetCentsProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final level = warningLevel(spent, totalLimit);
    final color = switch (level) {
      BudgetWarningLevel.ok => AppColors.success,
      BudgetWarningLevel.approaching => AppColors.taskPriorityHigh,
      BudgetWarningLevel.exceeded => AppColors.priorityUrgent,
    };
    final fraction =
        totalLimit == null || totalLimit <= 0 ? 0.0 : (spent / totalLimit).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BudgetScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.budgetTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            if (totalLimit == null) ...[
              Text(
                l10n.noBudgetSetForMonth(DateFormat.MMMM().format(month)),
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  if (!checkPermission(context, ref, FamilyAction.manageBudget)) return;
                  showSetBudgetSheet(context);
                },
                child: Text(l10n.setBudget,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ] else ...[
              Text(
                '${formatCents(spent, currencyCode: currencyCode)} / '
                '${formatCents(totalLimit, currencyCode: currencyCode)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.budgetRemainingAmount(
                  formatCents(remaining ?? 0, currencyCode: currencyCode),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact savings summary — separate from the balance card's Income/
/// Expenses, since money saved into goals isn't simply income minus
/// expenses.
class _SavingsMiniCard extends ConsumerWidget {
  const _SavingsMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final goals = ref.watch(allGoalsProvider).valueOrNull ?? [];
    final totalSaved = ref.watch(totalSavedCentsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GoalsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.savings,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            if (goals.isEmpty) ...[
              Text(
                l10n.noGoalsYet,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  if (!checkPermission(context, ref, FamilyAction.manageSavingsGoals)) return;
                  showAddGoalSheet(context);
                },
                child: Text(l10n.addGoal,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ] else
              Text(
                l10n.goalsSavedSummary(
                  formatCents(totalSaved, currencyCode: currencyCode),
                  goals.length,
                ),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}
