import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../data/local/database.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/budget_calculator.dart';
import '../providers/budget_providers.dart';

enum _ReportsTab { spending, income, savings }

/// Last 6 calendar months up to and including [month], oldest first.
List<DateTime> _lastSixMonths(DateTime month) =>
    List.generate(6, (i) => DateTime(month.year, month.month - (5 - i)));

int _totalForMonth(List<BudgetTransaction> txns, DateTime month, _ReportsTab tab) {
  final range = monthRange(month);
  return switch (tab) {
    _ReportsTab.spending => expenseTotalCents(txns, range),
    _ReportsTab.income => incomeTotalCents(txns, range),
    _ReportsTab.savings => savingsTotalCents(txns, range),
  };
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportsTab _tab = _ReportsTab.spending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
    final categoryTotals = ref.watch(categoryTotalsCentsProvider);

    final months = _lastSixMonths(month);
    final values = [for (final m in months) _totalForMonth(txns, m, _tab)];
    final currentValue = values.last;
    final previousValue =
        _totalForMonth(txns, DateTime(month.year, month.month - 1), _tab);
    final maxY = ([...values, 1]).reduce((a, b) => a > b ? a : b).toDouble();

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = categoryTotals.values.fold(0, (sum, v) => sum + v);

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
            Text(l10n.reportsTitle, style: const TextStyle(fontSize: 16)),
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
          Row(
            children: [
              for (final t in _ReportsTab.values) ...[
                Expanded(
                  child: _TabChip(
                    label: switch (t) {
                      _ReportsTab.spending => l10n.reportsSpendingTab,
                      _ReportsTab.income => l10n.reportsIncomeTab,
                      _ReportsTab.savings => l10n.reportsSavingsTab,
                    },
                    selected: _tab == t,
                    onTap: () => setState(() => _tab = t),
                  ),
                ),
                if (t != _ReportsTab.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            switch (_tab) {
              _ReportsTab.spending => l10n.monthlySpending,
              _ReportsTab.income => l10n.monthlyIncome,
              _ReportsTab.savings => l10n.savings,
            },
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            formatCents(currentValue, currencyCode: currencyCode),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.MMM().format(months[i]),
                            style:
                                TextStyle(fontSize: 11, color: context.colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          color: i == values.length - 1
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.25),
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.topCategories,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (sortedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(l10n.noTransactionsYet,
                    style: TextStyle(color: context.colors.textSecondary)),
              ),
            )
          else
            for (final e in sortedCategories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.key.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(e.key.icon, size: 16, color: e.key.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.key.label(l10n),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '${(e.value / totalSpent * 100).round()}%',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatCents(e.value, currencyCode: currencyCode),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
          if (_tab == _ReportsTab.spending) ...[
            const SizedBox(height: 20),
            _InsightCard(currentValue: currentValue, previousValue: previousValue),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.currentValue, required this.previousValue});

  final int currentValue;
  final int previousValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final delta = previousValue == 0
        ? 0.0
        : ((currentValue - previousValue) / previousValue) * 100;
    final message = delta < -1
        ? l10n.insightLessSpending('${delta.abs().round()}')
        : delta > 1
            ? l10n.insightMoreSpending('${delta.round()}')
            : l10n.insightNoChange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
