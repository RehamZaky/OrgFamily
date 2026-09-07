// Disabled for now — tapping a task now opens TaskFormScreen directly
// instead of this read-only view. Kept here, commented out, in case the
// read-only detail view comes back later.
/*
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import 'task_form_screen.dart';

/// Read-only view of a task — tapping a task tile lands here instead of
/// straight into the edit form. Every field except notes is edit-only via
/// the "Edit" action, which opens [TaskFormScreen]; notes can be added
/// directly from this screen since that's just appending text, not
/// changing the task's other properties.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late final _notesController = TextEditingController(
    text: widget.task.description,
  );
  late String? _savedNotes = widget.task.description;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _notesDirty => _notesController.text.trim() != (_savedNotes ?? '');

  Future<void> _saveNotes() async {
    final notes = _notesController.text.trim();
    await ref
        .read(taskRepositoryProvider)
        .updateTask(
          widget.task.copyWith(
            description: Value(notes.isEmpty ? null : notes),
          ),
        );
    setState(() => _savedNotes = notes.isEmpty ? null : notes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskDetailsNotesSaved),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final task = widget.task;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final assignee = members.where((m) => m.id == task.assigneeId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetailsScreenTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskFormScreen(existing: task)),
            ),
            child: Text(l10n.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GestureDetector(
              //   onTap: () => ref
              //       .read(taskRepositoryProvider)
              //       .setCompleted(task.id, !task.isCompleted),
              //   child: Icon(
              //     task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              //     color: task.isCompleted ? AppColors.success : task.priority.color,
              //     size: 30,
              //   ),
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? context.colors.textSecondary
                        : context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.labelNotes,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (_notesDirty)
                TextButton(onPressed: _saveNotes, child: Text(l10n.save)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
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
            child: TextField(
              controller: _notesController,
              minLines: 8,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.taskDetailsNotesHint,
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => setState(() {}),
              onTapOutside: (_) {
                if (_notesDirty) _saveNotes();
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.primary,
                  label: l10n.labelAssignedTo,
                  child: Row(
                    children: [
                      MemberAvatar(member: assignee, radius: 12),
                      const SizedBox(width: 8),
                      Text(
                        assignee?.name ?? l10n.unassigned,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: task.category.icon,
                  iconColor: task.category.color,
                  label: l10n.labelCategory,
                  valueText: task.category.label(l10n),
                ),
                if (task.recurrence != TaskRecurrence.none) ...[
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.repeat_rounded,
                    iconColor: AppColors.info,
                    label: l10n.labelRepeat,
                    valueText: task.recurrence.label(l10n),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.success,
                  label: l10n.labelDueDate,
                  valueText: task.dueDate == null
                      ? l10n.notSet
                      : task.dueDate!.relativeDayAndTime,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: task.priority.icon,
                  iconColor: task.priority.color,
                  label: l10n.labelPriority,
                  valueText: task.priority.label(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.valueText,
    this.child,
  }) : assert(valueText != null || child != null);

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? valueText;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          const Spacer(),
          child ??
              Text(
                valueText!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
        ],
      ),
    );
  }
}
*/
