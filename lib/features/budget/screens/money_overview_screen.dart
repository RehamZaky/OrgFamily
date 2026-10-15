import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
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
                      icon: Icon(Icons.menu, color: context.colors.accent),
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0x14000000),
                  child: Icon(Icons.notifications_none, color: context.colors.accent),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.colors.heroCardGradient,
                ),
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
                                style: TextStyle(
                                    color: context.colors.onHeroSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 12),
                  Text(
                    l10n.netThisMonth(formatCents(income - expenses, currencyCode: currencyCode)),
                    style: TextStyle(color: context.colors.onHeroSecondary, fontSize: 12),
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
              _SingleCategoryCard(
                category: sortedCategories.single.key,
                amountCents: sortedCategories.single.value,
                currencyCode: currencyCode,
                l10n: l10n,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpendingDonutChart(
                    // A tiny category would be thinner than the gap between
                    // slices and vanish, so each one gets at least 2% of the
                    // ring; the list beside it keeps the exact figures.
                    sections: [
                      for (final e in sortedCategories)
                        DonutSection(
                          e.key.color,
                          math.max(e.value.toDouble(), totalSpent * 0.02),
                        ),
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
                              ? context.colors.danger
                              : context.colors.success,
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

/// One category's line beside the Spending by Category donut — icon and
/// name, then the amount and its share of the total underneath, so the
/// reader never has to compute the amount from the percentage themselves.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountCents,
    required this.totalCents,
    required this.currencyCode,
    required this.l10n,
  });

  final TransactionCategory category;
  final int amountCents;
  final int totalCents;
  final String currencyCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final percent = totalCents == 0 ? 0 : (amountCents / totalCents * 100).round();
    // Real spending that rounds to 0% reads as "<1%", kept left-to-right so
    // RTL doesn't mirror it into "%1>".
    final share = amountCents > 0 && percent == 0 ? '\u2066<1%\u2069' : '$percent%';
    const iconSize = 22.0;
    // There is little width beside the donut, so the amount and share sit
    // on a second line under the name instead of cutting the name short.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(category.icon, size: 12, color: category.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category.label(l10n), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: iconSize + 8),
            child: Row(
              children: [
                // Shrink a very large amount rather than cut digits off it.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formatCents(amountCents, currencyCode: currencyCode),
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(share,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spending by Category when the month has only one category: a compact
/// card naming it, with its amount shown once and 100% as a small hint —
/// a one-slice donut would say nothing.
class _SingleCategoryCard extends StatelessWidget {
  const _SingleCategoryCard({
    required this.category,
    required this.amountCents,
    required this.currencyCode,
    required this.l10n,
  });

  final TransactionCategory category;
  final int amountCents;
  final String currencyCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, size: 20, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    formatCents(amountCents, currencyCode: currencyCode),
                    maxLines: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.colors.track,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '100%',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
            ),
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
          border: Border.all(color: context.colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.colors.accent, size: 18),
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
              Text(label,
                  style: TextStyle(color: context.colors.onHeroSecondary, fontSize: 11)),
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
      BudgetWarningLevel.ok => context.colors.success,
      BudgetWarningLevel.approaching => context.colors.warning,
      BudgetWarningLevel.exceeded => context.colors.danger,
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
          border: Border.all(color: context.colors.borderSubtle),
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
                    style: TextStyle(
                        color: context.colors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ] else ...[
              Text(
                '${formatCents(spent, currencyCode: currencyCode)} / '
                '${formatCents(totalLimit, currencyCode: currencyCode)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: context.colors.track,
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
          border: Border.all(color: context.colors.borderSubtle),
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
                    style: TextStyle(
                        color: context.colors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
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
