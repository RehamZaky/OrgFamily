import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions/active_profile_provider.dart';
import '../../core/permissions/family_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../budget/widgets/add_transaction_sheet.dart';
import '../calendar/screens/event_form_screen.dart';
import '../notes/screens/note_form_screen.dart';
import '../shopping/screens/add_shopping_item_screen.dart';
import '../tasks/widgets/quick_add_task_sheet.dart';

void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canManageTransactions =
        canPerform(ref.watch(activeRoleProvider), FamilyAction.manageTransactions);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.quickAddTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAddOption(
                  icon: Icons.check_circle_outline,
                  label: l10n.quickAddTask,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    showQuickAddTaskSheet(context);
                  },
                ),
                _QuickAddOption(
                  icon: Icons.sticky_note_2_outlined,
                  label: l10n.quickAddNote,
                  color: Colors.amber.shade700,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NoteFormScreen()),
                    );
                  },
                ),
                _QuickAddOption(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.quickAddEvent,
                  color: AppColors.info,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EventFormScreen()),
                    );
                  },
                ),
                _QuickAddOption(
                  icon: Icons.shopping_cart_outlined,
                  label: l10n.quickAddShopping,
                  color: AppColors.success,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddShoppingItemScreen()),
                    );
                  },
                ),
                if (canManageTransactions)
                  _QuickAddOption(
                    icon: Icons.attach_money,
                    label: l10n.quickAddTransaction,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.of(context).pop();
                      showAddTransactionSheet(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  const _QuickAddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
