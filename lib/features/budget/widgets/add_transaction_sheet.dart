import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../data/providers.dart';
import '../../../features/family/providers/family_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Add a transaction, or edit [existing] in place when provided.
Future<void> showAddTransactionSheet(BuildContext context, {BudgetTransaction? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTransactionSheet(existing: existing),
  );
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet({this.existing});

  final BudgetTransaction? existing;

  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  late final _amountController = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.amountCents / 100).toStringAsFixed(2),
  );
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _noteController = TextEditingController(text: widget.existing?.note ?? '');
  late TransactionType _type = widget.existing?.type ?? TransactionType.expense;
  late TransactionCategory _category = widget.existing?.category ?? TransactionCategory.other;
  late IncomeSource _incomeSource = widget.existing?.incomeSource ?? IncomeSource.salary;
  late Account _account = widget.existing?.account ?? Account.cash;
  late Account _toAccount = widget.existing?.toAccount ?? Account.bank;
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _pickType() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final type = await showOptionPickerSheet<TransactionType>(
      context: context,
      title: l10n.transactionTypeLabel,
      options: TransactionType.values,
      labelBuilder: (t) => t.label(l10n),
      selected: _type,
    );
    if (type != null) setState(() => _type = type);
  }

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
    if (category != null) setState(() => _category = category);
  }

  Future<void> _pickIncomeSource() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final source = await showOptionPickerSheet<IncomeSource>(
      context: context,
      title: l10n.transactionIncomeSourceLabel,
      options: IncomeSource.values,
      labelBuilder: (s) => s.label(l10n),
      iconBuilder: (s) => s.icon,
      selected: _incomeSource,
    );
    if (source != null) setState(() => _incomeSource = source);
  }

  /// Where the money is paid from (expense), received into (income), or
  /// moved from (transfer) — the label changes with [_type] since it's the
  /// same underlying [_account] field playing a different role each time.
  String _accountLabel(AppLocalizations l10n) => switch (_type) {
        TransactionType.income => l10n.transactionReceivedIntoLabel,
        TransactionType.transfer => l10n.transactionFromAccountLabel,
        TransactionType.expense => l10n.transactionPaidFromLabel,
      };

  Future<void> _pickAccount() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final account = await showOptionPickerSheet<Account>(
      context: context,
      title: _accountLabel(l10n),
      options: Account.values,
      labelBuilder: (a) => a.label(l10n),
      iconBuilder: (a) => a.icon,
      selected: _account,
    );
    if (account != null) setState(() => _account = account);
  }

  Future<void> _pickToAccount() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final account = await showOptionPickerSheet<Account>(
      context: context,
      title: l10n.transactionToAccountLabel,
      options: Account.values,
      labelBuilder: (a) => a.label(l10n),
      iconBuilder: (a) => a.icon,
      selected: _toAccount,
    );
    if (account != null) setState(() => _toAccount = account);
  }

  Future<void> _pickDate() async {
    _unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _date = DateTime(date.year, date.month, date.day));
  }

  int? get _amountCents {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return null;
    return (amount * 100).round();
  }

  bool get _canSave => _amountCents != null && _titleController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final amountCents = _amountCents;
    final title = _titleController.text.trim();
    if (amountCents == null || title.isEmpty) return;
    if (!checkPermission(context, ref, FamilyAction.manageTransactions)) return;

    final repo = ref.read(budgetRepositoryProvider);
    final actingRole = ref.read(activeRoleProvider);
    final actingMemberId = ref.read(activeMemberIdProvider);
    final note = _noteController.text.trim();
    // Income/transfer entries don't carry a meaningful category, and
    // expense/transfer don't carry a meaningful income source — pin the
    // inapplicable one to .other so it stays inert rather than showing a
    // stale pick from a previous edit. A non-transfer's "to account" is
    // pinned to the same account as "from" (a no-op transfer) since it's
    // not shown or editable for that type.
    final category = _type == TransactionType.expense ? _category : TransactionCategory.other;
    final incomeSource = _type == TransactionType.income ? _incomeSource : IncomeSource.other;
    final toAccount = _type == TransactionType.transfer ? _toAccount : _account;

    final existing = widget.existing;
    if (existing == null) {
      await repo.addTransaction(
        id: const Uuid().v4(),
        type: _type,
        amountCents: amountCents,
        category: category,
        incomeSource: incomeSource,
        account: _account,
        toAccount: toAccount,
        title: title,
        note: note.isEmpty ? null : note,
        date: _date,
        actingRole: actingRole,
        actingMemberId: actingMemberId,
      );
    } else {
      await repo.updateTransaction(
        existing.copyWith(
          type: _type,
          amountCents: amountCents,
          category: category,
          incomeSource: incomeSource,
          account: _account,
          toAccount: toAccount,
          title: title,
          note: Value(note.isEmpty ? null : note),
          date: _date,
        ),
        actingRole: actingRole,
        actingMemberId: actingMemberId,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existing != null;

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
                Text(
                  isEditing ? l10n.editTransaction : l10n.addTransaction,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  autofocus: !isEditing,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  decoration: InputDecoration(
                    labelText: l10n.transactionAmount,
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.transactionTitleHint,
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                PickerRow(
                  icon: Icons.swap_vert,
                  iconColor: context.colors.textSecondary,
                  label: l10n.transactionTypeLabel,
                  value: _type.label(l10n),
                  onTap: _pickType,
                ),
                if (_type == TransactionType.expense)
                  PickerRow(
                    icon: _category.icon,
                    iconColor: _category.color,
                    label: l10n.transactionCategoryLabel,
                    value: _category.label(l10n),
                    onTap: _pickCategory,
                  ),
                if (_type == TransactionType.income)
                  PickerRow(
                    icon: _incomeSource.icon,
                    iconColor: context.colors.textSecondary,
                    label: l10n.transactionIncomeSourceLabel,
                    value: _incomeSource.label(l10n),
                    onTap: _pickIncomeSource,
                  ),
                PickerRow(
                  icon: _account.icon,
                  iconColor: context.colors.textSecondary,
                  label: _accountLabel(l10n),
                  value: _account.label(l10n),
                  onTap: _pickAccount,
                ),
                if (_type == TransactionType.transfer)
                  PickerRow(
                    icon: _toAccount.icon,
                    iconColor: context.colors.textSecondary,
                    label: l10n.transactionToAccountLabel,
                    value: _toAccount.label(l10n),
                    onTap: _pickToAccount,
                  ),
                PickerRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: context.colors.textSecondary,
                  label: l10n.transactionDateLabel,
                  value: _date.relativeDay,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.transactionNoteLabel,
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(isEditing ? l10n.saveChanges : l10n.addTransaction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
