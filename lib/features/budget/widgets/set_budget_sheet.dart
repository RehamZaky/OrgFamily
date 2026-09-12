import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../data/providers.dart';
import '../../../features/family/providers/family_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/budget_providers.dart';

Future<void> showSetBudgetSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SetBudgetSheet(),
  );
}

class _SetBudgetSheet extends ConsumerStatefulWidget {
  const _SetBudgetSheet();

  @override
  ConsumerState<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<_SetBudgetSheet> {
  late final _totalController = TextEditingController(
    text: () {
      final cents = ref.read(totalLimitCentsProvider);
      return cents == null ? '' : (cents / 100).toStringAsFixed(2);
    }(),
  );
  TransactionCategory _category = TransactionCategory.groceries;
  late final _categoryController = TextEditingController(
    text: () {
      final cents = ref.read(categoryLimitMapProvider)[_category];
      return cents == null ? '' : (cents / 100).toStringAsFixed(2);
    }(),
  );
  String? _categoryError;

  @override
  void dispose() {
    _totalController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _pickCategory() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final category = await showOptionPickerSheet<TransactionCategory>(
      context: context,
      title: l10n.transactionCategoryLabel,
      options: TransactionCategory.values,
      labelBuilder: (c) => c.label(l10n),
      iconBuilder: (c) => c.icon,
      selected: _category,
    );
    if (category == null) return;
    final cents = ref.read(categoryLimitMapProvider)[category];
    setState(() {
      _category = category;
      _categoryController.text = cents == null ? '' : (cents / 100).toStringAsFixed(2);
      _categoryError = null;
    });
  }

  Future<void> _pickCurrency() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(currencyCodeProvider);
    final code = await showOptionPickerSheet<String>(
      context: context,
      title: l10n.currency,
      options: supportedCurrencyCodes,
      labelBuilder: (c) => c,
      selected: current,
    );
    if (code == null || !mounted) return;
    if (!checkPermission(context, ref, FamilyAction.manageBudget)) return;
    await ref.read(budgetRepositoryProvider).setCurrencyCode(
          code,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );
  }

  Future<void> _editTotalBudget() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final cents = ref.read(totalLimitCentsProvider);
    _totalController.text = cents == null ? '' : (cents / 100).toStringAsFixed(2);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.setTotalBudget),
        content: Consumer(
          builder: (context, ref, _) {
            final currencyCode = ref.watch(currencyCodeProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickerRow(
                  icon: Icons.attach_money,
                  iconColor: context.colors.textSecondary,
                  label: l10n.currency,
                  value: currencyCode,
                  onTap: _pickCurrency,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _totalController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    prefixText: '$currencyCode ',
                    hintText: l10n.budgetLimitPlaceholder,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.saveChanges),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveTotal();
  }

  Future<void> _saveTotal() async {
    final amount = double.tryParse(_totalController.text.trim());
    if (amount == null || amount <= 0) return;
    if (!checkPermission(context, ref, FamilyAction.manageBudget)) return;
    await ref.read(budgetRepositoryProvider).setTotalLimit(
          (amount * 100).round(),
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _saveCategory() async {
    final amount = double.tryParse(_categoryController.text.trim());
    if (amount == null || amount <= 0) return;
    final amountCents = (amount * 100).round();

    final totalLimit = ref.read(totalLimitCentsProvider);
    if (totalLimit != null) {
      final otherCategoriesCents = ref.read(categoryLimitMapProvider)
          .entries
          .where((e) => e.key != _category)
          .fold(0, (sum, e) => sum + e.value);
      final overCents = otherCategoriesCents + amountCents - totalLimit;
      if (overCents > 0) {
        setState(() {
          _categoryError = AppLocalizations.of(context)!.budgetOverTotalWarning(
            formatCents(overCents, currencyCode: ref.read(currencyCodeProvider)),
          );
        });
        return;
      }
    }
    setState(() => _categoryError = null);

    if (!checkPermission(context, ref, FamilyAction.manageBudget)) return;
    await ref.read(budgetRepositoryProvider).setCategoryLimit(
          category: _category,
          limitCents: amountCents,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final totalLimit = ref.watch(totalLimitCentsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(l10n.setBudget,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(l10n.setTotalBudget,
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _editTotalBudget,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.edit_outlined,
                            size: 14, color: context.colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  totalLimit == null
                      ? l10n.noBudgetSet
                      : formatCents(totalLimit, currencyCode: currencyCode),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: totalLimit == null ? context.colors.textSecondary : null,
                  ),
                ),
                if (ref.watch(unallocatedBudgetCentsProvider) case final unallocated?) ...[
                  const SizedBox(height: 6),
                  Text(
                    unallocated < 0
                        ? l10n.budgetOverTotalWarning(
                            formatCents(-unallocated, currencyCode: currencyCode))
                        : l10n.budgetUnallocatedLabel(
                            formatCents(unallocated, currencyCode: currencyCode)),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: unallocated < 0 ? FontWeight.w600 : FontWeight.normal,
                      color: unallocated < 0 ? AppColors.priorityUrgent : context.colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(l10n.setCategoryBudget,
                    style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                const SizedBox(height: 6),
                PickerRow(
                  icon: _category.icon,
                  iconColor: _category.color,
                  label: l10n.transactionCategoryLabel,
                  value: _category.label(l10n),
                  onTap: _pickCategory,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoryController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.colors.background,
                          prefixText: '$currencyCode ',
                          hintText: l10n.budgetLimitPlaceholder,
                        ),
                        onChanged: (_) {
                          if (_categoryError != null) setState(() => _categoryError = null);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _saveCategory, child: Text(l10n.saveChanges)),
                  ],
                ),
                if (_categoryError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _categoryError!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.priorityUrgent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
