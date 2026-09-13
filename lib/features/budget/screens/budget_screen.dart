import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../domain/budget_calculator.dart';
import '../providers/budget_providers.dart';
import '../widgets/category_budget_row.dart';
import '../widgets/set_budget_sheet.dart';
import '../widgets/spending_donut_chart.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final totalLimit = ref.watch(totalLimitCentsProvider);
    final spent = ref.watch(monthExpenseTotalCentsProvider);
    final remaining = ref.watch(remainingBudgetCentsProvider);
    final categoryTotals = ref.watch(categoryTotalsCentsProvider);
    final categoryLimits = ref.watch(categoryLimitMapProvider);
    final level = warningLevel(spent, totalLimit);
    final usedFraction =
        totalLimit == null || totalLimit <= 0 ? 0.0 : (spent / totalLimit).clamp(0.0, 1.0);

    // Every category with either spend or a limit set this month, spend
    // descending — categories with neither simply don't clutter the list.
    // Ties (e.g. multiple categories at $0 spent) fall back to declaration
    // order so the list doesn't reshuffle on every rebuild: List.sort isn't
    // stable, so an amount-only comparator lets tied rows jump around each
    // time the underlying transaction stream re-emits.
    final categories = {...categoryTotals.keys, ...categoryLimits.keys}.toList()
      ..sort((a, b) {
        final byAmount = (categoryTotals[b] ?? 0).compareTo(categoryTotals[a] ?? 0);
        return byAmount != 0 ? byAmount : a.index.compareTo(b.index);
      });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => ref.read(selectedBudgetMonthProvider.notifier).state =
                  DateTime(month.year, month.month - 1),
            ),
            Text(l10n.budgetTitle, style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => ref.read(selectedBudgetMonthProvider.notifier).state =
                  DateTime(month.year, month.month + 1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Center(child: Text(DateFormat.yMMMM().format(month))),
          const SizedBox(height: 16),
          Center(
            child: SpendingDonutChart(
              size: 160,
              sections: totalLimit == null || totalLimit <= 0
                  ? const []
                  : [
                      DonutSection(
                        switch (level) {
                          BudgetWarningLevel.ok => AppColors.success,
                          BudgetWarningLevel.approaching => AppColors.taskPriorityHigh,
                          BudgetWarningLevel.exceeded => AppColors.priorityUrgent,
                        },
                        spent.toDouble(),
                      ),
                      if (spent < totalLimit)
                        DonutSection(Colors.grey.shade200, (totalLimit - spent).toDouble()),
                    ],
              centerLabel: totalLimit == null
                  ? l10n.noBudgetSet
                  : l10n.budgetUsedPercent('${(usedFraction * 100).round()}'),
              centerSubLabel: totalLimit == null ? null : l10n.budgetUsedLabel,
            ),
          ),
          const SizedBox(height: 16),
          if (totalLimit != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AmountColumn(
                  label: '${formatCents(spent, currencyCode: currencyCode)} / '
                      '${formatCents(totalLimit, currencyCode: currencyCode)}',
                  sub: l10n.budgetUsedLabel,
                ),
                _AmountColumn(
                  label: formatCents(remaining ?? 0, currencyCode: currencyCode),
                  sub: l10n.budgetRemaining,
                  color: (remaining ?? 0) < 0 ? AppColors.priorityUrgent : AppColors.success,
                ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.categoryBudgets,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(l10n.noBudgetSet,
                    style: TextStyle(color: context.colors.textSecondary)),
              ),
            )
          else
            for (final c in categories)
              if (categoryLimits[c] != null)
                Dismissible(
                  key: ValueKey('budget-limit-${c.name}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    child: const Icon(Icons.delete_outline, color: AppColors.priorityUrgent),
                  ),
                  confirmDismiss: (_) async {
                    return checkPermission(context, ref, FamilyAction.manageBudget);
                  },
                  onDismissed: (_) => ref.read(budgetRepositoryProvider).deleteCategoryLimit(
                        c,
                        actingRole: ref.read(activeRoleProvider),
                        actingMemberId: ref.read(activeMemberIdProvider),
                      ),
                  child: CategoryBudgetRow(
                    category: c,
                    spentCents: categoryTotals[c] ?? 0,
                    limitCents: categoryLimits[c],
                    currencyCode: currencyCode,
                  ),
                )
              else
                CategoryBudgetRow(
                  category: c,
                  spentCents: categoryTotals[c] ?? 0,
                  limitCents: categoryLimits[c],
                  currencyCode: currencyCode,
                ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!checkPermission(context, ref, FamilyAction.manageBudget)) return;
              showSetBudgetSheet(context);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.setBudget),
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({required this.label, required this.sub, this.color});

  final String label;
  final String sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
      ],
    );
  }
}
