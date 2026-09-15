import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../screens/task_form_screen.dart';

/// The fast path for adding a task: title (+ voice, once wired up) plus
/// four one-tap shortcuts, with "More options" as the escape hatch into the
/// full [TaskFormScreen] when a task actually needs assignment, notes, a
/// repeat schedule, etc.
Future<void> showQuickAddTaskSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QuickAddTaskSheet(),
  );
}

class _QuickAddTaskSheet extends ConsumerStatefulWidget {
  const _QuickAddTaskSheet();

  @override
  ConsumerState<_QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<_QuickAddTaskSheet> {
  final _titleController = TextEditingController();
  final _speech = SpeechToText();
  DateTime? _dueDate;
  TaskPriority? _priority;
  String? _assigneeId;
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Default a new task to the person creating it — otherwise it's
    // silently unassigned, which reads as "someone" in the family activity
    // feed and never counts toward that member's stats even after they
    // complete it themselves. Still overridable via the assignee picker.
    _assigneeId = ref.read(currentMemberProvider)?.id;
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechEnabled = available);
  }

  @override
  void dispose() {
    if (_speech.isListening) _speech.stop();
    _titleController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  /// Matches the app's current display language to a locale the device's
  /// speech recognizer actually offers (Android/iOS locale ids don't
  /// reliably match Flutter's own locale codes), so Arabic-speaking users
  /// get Arabic recognition and English-speaking users get English,
  /// following whichever language OrgFamily itself is currently set to.
  String? _matchLocale(List<LocaleName> locales, String languageCode) {
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(languageCode.toLowerCase())) {
        return l.localeId;
      }
    }
    return null;
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechEnabled) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.quickAddTaskVoiceUnavailable)));
      return;
    }
    _unfocus();
    final languageCode = Localizations.localeOf(context).languageCode;
    final locales = await _speech.locales();
    if (!mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _titleController.text = result.recognizedWords;
          _titleController.selection =
              TextSelection.collapsed(offset: _titleController.text.length);
        });
      },
      listenOptions: SpeechListenOptions(
        localeId: _matchLocale(locales, languageCode),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _comingSoon(String feature) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taskFormComingSoon(feature))),
    );
  }

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
    setState(() => _dueDate = DateTime(date.year, date.month, date.day));
  }

  Future<void> _pickPriority() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final priority = await showOptionPickerSheet<TaskPriority>(
      context: context,
      title: l10n.labelPriority,
      options: TaskPriority.values,
      labelBuilder: (p) => p.label(l10n),
      iconBuilder: (p) => p.icon,
      selected: _priority ?? TaskPriority.normal,
    );
    _unfocus();
    if (priority != null) setState(() => _priority = priority);
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (!checkPermission(context, ref, FamilyAction.createTask)) return;
    await ref.read(taskRepositoryProvider).addTask(
          id: const Uuid().v4(),
          title: title,
          dueDate: _dueDate,
          priority: _priority ?? TaskPriority.normal,
          assigneeId: _assigneeId,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _openFullEditor() {
    final title = _titleController.text.trim();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          initialTitle: title.isEmpty ? null : title,
          initialDueDate: _dueDate,
          initialPriority: _priority,
          initialAssigneeId: _assigneeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = {
      for (final m in ref.watch(familyMembersProvider).valueOrNull ?? [])
        m.id: m
    };
    final assignee = members[_assigneeId];
    final priority = _priority;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _toggleListening,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _isListening
                          ? AppColors.priorityHigh.withValues(alpha: 0.15)
                          : Colors.amber.shade100,
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening
                            ? AppColors.priorityHigh
                            : Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.taskFormTitleHint,
                        filled: true,
                        fillColor: context.colors.background,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ShortcutChip(
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.success,
                    label: _dueDate == null
                        ? l10n.quickAddTaskDateShort
                        : _dueDate!.relativeDay,
                    active: _dueDate != null,
                    onTap: _pickDate,
                  ),
                  _ShortcutChip(
                    icon: Icons.notifications_outlined,
                    color: AppColors.info,
                    label: l10n.taskFormReminder,
                    active: false,
                    onTap: () => _comingSoon(l10n.taskFormReminder),
                  ),
                  _ShortcutChip(
                    icon: (priority ?? TaskPriority.normal).icon,
                    color: AppColors.priorityHigh,
                    label: priority == null
                        ? l10n.labelPriority
                        : priority.label(l10n),
                    active: priority != null,
                    onTap: _pickPriority,
                  ),
                  _ShortcutChip(
                    icon: Icons.people_alt_outlined,
                    color: AppColors.primary,
                    label: assignee?.name ?? l10n.quickAddTaskAssignShort,
                    active: assignee != null,
                    onTap: _pickAssignee,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _openFullEditor,
                    child: Text(l10n.quickAddTaskMoreOptions),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed:
                        _titleController.text.trim().isEmpty ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.quickAddTaskAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: active ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: active ? color : context.colors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? color : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
