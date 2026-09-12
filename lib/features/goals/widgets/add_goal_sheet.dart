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
import '../../../data/local/tables/savings_goals_table.dart';
import '../../../data/providers.dart';
import '../../../features/family/providers/family_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Add a goal, or edit [existing] in place when provided.
Future<void> showAddGoalSheet(BuildContext context, {SavingsGoal? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddGoalSheet(existing: existing),
  );
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet({this.existing});

  final SavingsGoal? existing;

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _targetController = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.targetCents / 100).toStringAsFixed(2),
  );
  late SavingsGoalIcon _icon = widget.existing?.icon ?? SavingsGoalIcon.other;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.existing?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _pickIcon() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final icon = await showOptionPickerSheet<SavingsGoalIcon>(
      context: context,
      title: l10n.goalTargetAmount,
      options: SavingsGoalIcon.values,
      labelBuilder: (i) => i.label(l10n),
      iconBuilder: (i) => i.icon,
      selected: _icon,
    );
    if (icon != null) setState(() => _icon = icon);
  }

  Future<void> _pickDate() async {
    _unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) setState(() => _targetDate = DateTime(date.year, date.month, date.day));
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      (double.tryParse(_targetController.text.trim()) ?? 0) > 0;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    if (name.isEmpty || target == null || target <= 0) return;
    if (!checkPermission(context, ref, FamilyAction.manageSavingsGoals)) return;

    final repo = ref.read(savingsGoalRepositoryProvider);
    final actingRole = ref.read(activeRoleProvider);
    final actingMemberId = ref.read(activeMemberIdProvider);
    final targetCents = (target * 100).round();

    final existing = widget.existing;
    if (existing == null) {
      await repo.addGoal(
        id: const Uuid().v4(),
        name: name,
        icon: _icon,
        targetCents: targetCents,
        targetDate: _targetDate,
        actingRole: actingRole,
        actingMemberId: actingMemberId,
      );
    } else {
      await repo.updateGoal(
        existing.copyWith(
          name: name,
          icon: _icon,
          targetCents: targetCents,
          targetDate: Value(_targetDate),
          savedCents: targetCents < existing.savedCents ? targetCents : existing.savedCents,
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
                  isEditing ? l10n.editGoal : l10n.addGoal,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.goalNameHint,
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  decoration: InputDecoration(
                    labelText: l10n.goalTargetAmount,
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                PickerRow(
                  icon: _icon.icon,
                  iconColor: _icon.color,
                  label: l10n.transactionCategoryLabel,
                  value: _icon.label(l10n),
                  onTap: _pickIcon,
                ),
                PickerRow(
                  icon: Icons.event_outlined,
                  iconColor: context.colors.textSecondary,
                  label: l10n.goalTargetDateOptional,
                  value: _targetDate == null ? l10n.goalTargetDateOptional : _targetDate!.shortDate,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(isEditing ? l10n.saveChanges : l10n.addGoal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
