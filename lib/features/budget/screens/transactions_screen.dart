import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/budget_table.dart';
import '../../../data/providers.dart';
import '../../../features/family/providers/family_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/budget_providers.dart';
import '../widgets/add_transaction_sheet.dart';

enum _TypeFilter { all, income, expense, transfer }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _searching = false;
  String _query = '';
  _TypeFilter _filter = _TypeFilter.all;

  bool _matchesFilter(BudgetTransaction t) {
    return switch (_filter) {
      _TypeFilter.all => true,
      _TypeFilter.income => t.type == TransactionType.income,
      _TypeFilter.expense => t.type == TransactionType.expense,
      _TypeFilter.transfer => t.type == TransactionType.transfer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final txnsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.transactionsSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.transactionsTitle),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                for (final f in _TypeFilter.values) ...[
                  Expanded(
                    child: _TabChip(
                      label: switch (f) {
                        _TypeFilter.all => l10n.transactionFilterAll,
                        _TypeFilter.income => l10n.transactionTypeIncome,
                        _TypeFilter.expense => l10n.transactionTypeExpense,
                        _TypeFilter.transfer => l10n.transactionTypeTransfer,
                      },
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
                  if (f != _TypeFilter.values.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final query = _query.trim().toLowerCase();
                final txns = all.where((t) {
                  if (!_matchesFilter(t)) return false;
                  if (query.isEmpty) return true;
                  return t.title.toLowerCase().contains(query) ||
                      (t.note?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (txns.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: context.colors.textSecondary),
                          const SizedBox(height: 12),
                          Text(l10n.noTransactionsYet,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(l10n.transactionsEmptyHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.colors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                final groups = <String, List<BudgetTransaction>>{};
                for (final t in txns) {
                  final label = t.date.isToday
                      ? l10n.today
                      : t.date.isYesterday
                          ? l10n.yesterday
                          : t.date.fullDate;
                  groups.putIfAbsent(label, () => []).add(t);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                      for (final t in entry.value)
                        _TransactionTile(transaction: t, currencyCode: currencyCode),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction, required this.currencyCode});

  final BudgetTransaction transaction;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = transaction;
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (!checkPermission(context, ref, FamilyAction.manageTransactions)) return false;
        return true;
      },
      onDismissed: (_) => ref.read(budgetRepositoryProvider).deleteTransaction(
            t.id,
            actingRole: ref.read(activeRoleProvider),
            actingMemberId: ref.read(activeMemberIdProvider),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => showAddTransactionSheet(context, existing: t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.displayColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.displayIcon, size: 20, color: t.displayColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(t.displayLabel(l10n),
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    Text(t.date.timeLabel,
                        style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
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
