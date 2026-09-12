import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/detail_row.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../domain/task_status_calculator.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({
    super.key,
    this.existing,
    this.initialTitle,
    this.initialDueDate,
    this.initialPriority,
    this.initialAssigneeId,
  });

  final Task? existing;

  /// Carried over from the Quick Add sheet's "More options" link, so
  /// nothing the user already entered there is lost. Ignored when
  /// [existing] is set.
  final String? initialTitle;
  final DateTime? initialDueDate;
  final TaskPriority? initialPriority;
  final String? initialAssigneeId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  late final _titleController = TextEditingController(
      text: widget.existing?.title ?? widget.initialTitle);
  late final _descController =
      TextEditingController(text: widget.existing?.description);
  DateTime? _dueDate;
  int? _dueTimeMinutes;
  late TaskPriority _priority;
  late TaskCategory _category;
  late TaskRecurrence _recurrence;
  String? _assigneeId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final initialDue = e?.dueDate ?? widget.initialDueDate;
    _dueDate = initialDue == null
        ? null
        : DateTime(initialDue.year, initialDue.month, initialDue.day);
    _dueTimeMinutes = e?.dueTimeMinutes;
    _priority = e?.priority ?? widget.initialPriority ?? TaskPriority.normal;
    _category = e?.category ?? TaskCategory.other;
    _recurrence = e?.recurrence ?? TaskRecurrence.none;
    _assigneeId = e?.assigneeId ?? widget.initialAssigneeId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Bottom sheets (unlike Material dialogs) can restore focus to whatever
  /// text field was focused before they opened once they close, popping the
  /// keyboard back up even though we unfocused before opening — so we
  /// unfocus both before AND after, using the app-wide primary focus rather
  /// than just this scope's, which is the only combination that reliably
  /// keeps the keyboard down across all of showDatePicker/showTimePicker/
  /// showModalBottomSheet.
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _pickDate() async {
    _unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    _unfocus();
    if (date == null) return;
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _pickTime() async {
    if (_dueDate == null) return;
    _unfocus();
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTimeMinutes != null
          ? TimeOfDay(hour: _dueTimeMinutes! ~/ 60, minute: _dueTimeMinutes! % 60)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    _unfocus();
    if (time == null) return;
    setState(() => _dueTimeMinutes = time.hour * 60 + time.minute);
  }

  Future<void> _pickCategory() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final category = await showOptionPickerSheet<TaskCategory>(
      context: context,
      title: l10n.labelCategory,
      options: TaskCategory.values,
      labelBuilder: (c) => c.label(l10n),
      iconBuilder: (c) => c.icon,
      selected: _category,
    );
    _unfocus();
    if (category != null) setState(() => _category = category);
  }

  Future<void> _pickRecurrence() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final recurrence = await showOptionPickerSheet<TaskRecurrence>(
      context: context,
      title: l10n.labelRepeat,
      options: TaskRecurrence.values,
      labelBuilder: (r) => r.label(l10n),
      selected: _recurrence,
    );
    _unfocus();
    if (recurrence != null) setState(() => _recurrence = recurrence);
  }

  Future<void> _pickAssignee() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    const unassignedSentinel = '';
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.taskFormAssignTo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const MemberAvatar(),
              title: Text(l10n.unassigned),
              trailing: _assigneeId == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(unassignedSentinel),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  trailing: m.id == _assigneeId
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    _unfocus();
    if (result == null) return;
    setState(() => _assigneeId = result == unassignedSentinel ? null : result);
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.taskFormComingSoon(feature))),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final actingRole = ref.read(activeRoleProvider);
    final actingMemberId = ref.read(activeMemberIdProvider);
    final repo = ref.read(taskRepositoryProvider);
    if (widget.existing == null) {
      if (!checkPermission(context, ref, FamilyAction.createTask)) return;
      await repo.addTask(
        id: const Uuid().v4(),
        title: title,
        description:
            _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dueDate: _dueDate,
        dueTimeMinutes: _dueTimeMinutes,
        priority: _priority,
        category: _category,
        assigneeId: _assigneeId,
        recurrence: _recurrence,
        actingRole: actingRole,
        actingMemberId: actingMemberId,
      );
    } else {
      final updated = widget.existing!.copyWith(
        title: title,
        description: Value(
            _descController.text.trim().isEmpty ? null : _descController.text.trim()),
        dueDate: Value(_dueDate),
        dueTimeMinutes: Value(_dueTimeMinutes),
        priority: _priority,
        category: _category,
        assigneeId: Value(_assigneeId),
        recurrence: _recurrence,
      );
      final requiredAction =
          taskUpdateAction(widget.existing!, updated, actingMemberId);
      if (!checkPermission(context, ref, requiredAction)) return;
      await repo.updateTask(
        updated,
        actingRole: actingRole,
        actingMemberId: actingMemberId,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final assignee = members.where((m) => m.id == _assigneeId).firstOrNull;
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.taskFormEditTitle : l10n.taskFormNewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.taskFormQuestion,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: l10n.taskFormTitleHint,
              filled: true,
              fillColor: context.colors.surface,
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: !isEditing,
            maxLength: 100,
          ),
          const SizedBox(height: 8),
          DetailRowCard(
            children: [
              DetailRow(
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.primary,
                label: l10n.taskFormAssignTo,
                valueText: assignee?.name ?? l10n.unassigned,
                onTap: _pickAssignee,
              ),
              const Divider(height: 1),
              DetailRow(
                icon: _category.icon,
                iconColor: _category.color,
                label: l10n.labelCategory,
                valueText: _category.label(l10n),
                onTap: _pickCategory,
              ),
              const Divider(height: 1),
              DetailRow(
                icon: Icons.repeat_rounded,
                iconColor: AppColors.info,
                label: l10n.labelRepeat,
                valueText: _recurrence.label(l10n),
                onTap: _pickRecurrence,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailRowCard(
            children: [
              DetailRow(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.success,
                label: l10n.labelDueDate,
                onTap: _pickDate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dueDate == null
                          ? l10n.notSet
                          : '${_dueDate!.relativeDay}, ${_dueDate!.shortDate}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _dueDate = null;
                          _dueTimeMinutes = null;
                        }),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              DetailRow(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.priorityNormal,
                label: l10n.taskFormTimeLabel,
                onTap: _dueDate == null ? null : _pickTime,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dueTimeMinutes == null
                          ? l10n.taskTimeOptional
                          : _dueTimeMinutes!.timeOfDayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_dueTimeMinutes != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _dueTimeMinutes = null),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.priorityHigh.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded,
                      size: 16, color: AppColors.priorityHigh),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.labelPriority,
                          style: TextStyle(
                              fontSize: 12, color: context.colors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final p in TaskPriority.values) ...[
                            if (p != TaskPriority.values.first)
                              const SizedBox(width: 6),
                            Expanded(
                              child: _PriorityChip(
                                priority: p,
                                selected: p == _priority,
                                onTap: () => setState(() => _priority = p),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notes_rounded,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.taskFormNotesLabel,
                          style: TextStyle(
                              fontSize: 12, color: context.colors.textSecondary)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _descController,
                        decoration: InputDecoration(
                          hintText: l10n.taskFormNoteHint,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.notifications_outlined,
                  label: l10n.taskFormReminder,
                  onTap: () => _comingSoon(l10n.taskFormReminder),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.checklist_rounded,
                  label: l10n.taskFormChecklist,
                  onTap: () => _comingSoon(l10n.taskFormChecklist),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.attach_file_rounded,
                  label: l10n.taskFormAttachment,
                  onTap: () => _comingSoon(l10n.taskFormAttachment),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.account_tree_outlined,
                  label: l10n.taskFormSubtask,
                  onTap: () => _comingSoon(l10n.taskFormSubtask),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(isEditing ? l10n.saveChanges : l10n.taskFormCreateButton),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = priority.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(priority.icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              priority.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
