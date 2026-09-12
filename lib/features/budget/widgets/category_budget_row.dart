import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/budget_calculator.dart';

/// icon, name, "spent / limit", and a progress bar colored by
/// [warningLevel] — used on the Budget screen's category list and (in a
/// tighter layout) the Overview screen's legend.
class CategoryBudgetRow extends StatelessWidget {
  const CategoryBudgetRow({
    super.key,
    required this.category,
    required this.spentCents,
    required this.limitCents,
    required this.currencyCode,
    this.onTap,
  });

  final TransactionCategory category;
  final int spentCents;
  final int? limitCents;
  final String currencyCode;
  final VoidCallback? onTap;

  Color _barColor(BudgetWarningLevel level) => switch (level) {
        BudgetWarningLevel.ok => AppColors.success,
        BudgetWarningLevel.approaching => AppColors.taskPriorityHigh,
        BudgetWarningLevel.exceeded => AppColors.priorityUrgent,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final limit = limitCents;
    final level = warningLevel(spentCents, limit);
    final fraction = limit == null || limit <= 0 ? 0.0 : (spentCents / limit).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 18, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category.label(l10n),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        limit == null
                            ? formatCents(spentCents, currencyCode: currencyCode)
                            : '${formatCents(spentCents, currencyCode: currencyCode)} / '
                                '${formatCents(limit, currencyCode: currencyCode)}',
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: limit == null ? null : fraction,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_barColor(level)),
                    ),
                  ),
                  if (limit != null && level != BudgetWarningLevel.ok) ...[
                    const SizedBox(height: 4),
                    Text(
                      level == BudgetWarningLevel.exceeded
                          ? l10n.warningOverBudget
                          : l10n.warningApproachingLimit,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _barColor(level),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
