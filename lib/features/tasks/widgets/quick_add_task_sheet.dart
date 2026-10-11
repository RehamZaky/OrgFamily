import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../screens/task_form_screen.dart';
import 'reminder_picker_sheet.dart';
import '../../settings/providers/reminder_providers.dart';
import '../domain/default_reminder.dart';

/// The fast path for adding a task: a full-width title field (with voice
/// input below it) plus the two shortcuts most tasks actually need — date
/// (defaulted to today) and assignee (defaulted to whoever's adding it).
/// Reminder and priority live under "More" instead of their own chips, and
/// that same menu's last item is the escape hatch into the full
/// [TaskFormScreen] when a task needs notes, a repeat schedule, etc.
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
  TaskReminderType _reminderType = TaskReminderType.dueTime;
  int? _reminderOffsetMinutes;
  DateTime? _reminderAt;
  bool _reminderPicked = false;
  String? _reminderError;
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Default a new task to the person creating it — otherwise it's
    // silently unassigned, which reads as "someone" in the family activity
    // feed and never counts toward that member's stats even after they
    // complete it themselves. Still overridable via the assignee picker.
    _assigneeId = ref.read(actingMemberProvider)?.id;
    // Default to today too — a quick-added task is almost always "do this
    // today", and defaulting it means the Add button only ever waits on
    // the title, not a second required decision. Still overridable via
    // the date picker; there's no "no due date" option from this fast
    // path anymore (the full editor still allows clearing it).
    final now = DateTime.now();
    _dueDate = DateTime(now.year, now.month, now.day);
    // The "default task reminder" setting; quick-add tasks are date-only.
    final d = defaultTaskReminder(
      ref.read(phoneReminderPreferencesProvider).taskDefault,
      dueTimeMinutes: null,
    );
    _reminderType = d.type;
    _reminderOffsetMinutes = d.offsetMinutes;
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
      _reminderError = null;
    });
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

  Future<void> _pickReminder() async {
    final dueDate = _dueDate;
    if (dueDate == null) {
      // A plain SnackBar would attach to the page's Scaffold underneath
      // this modal bottom sheet and render behind it, invisible to the
      // user — shown inline in the sheet itself instead.
      final l10n = AppLocalizations.of(context)!;
      setState(() => _reminderError = l10n.reminderSelectDueDateFirst);
      return;
    }
    _unfocus();
    final result = await showReminderPickerSheet(
      context: context,
      dueDate: dueDate,
      dueTimeMinutes: null,
      currentType: _reminderType,
      currentOffsetMinutes: _reminderOffsetMinutes,
      currentReminderAt: _reminderAt,
    );
    _unfocus();
    if (result == null) return;
    setState(() {
      _reminderPicked = true;
      _reminderType = result.type;
      _reminderOffsetMinutes = result.offsetMinutes;
      _reminderAt = result.reminderAt;
      _reminderError = null;
    });
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
                  ? Icon(Icons.check, color: context.colors.accent)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(unassignedSentinel),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  trailing: m.id == _assigneeId
                      ? Icon(Icons.check, color: context.colors.accent)
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
          reminderType: _reminderType,
          reminderOffsetMinutes: _reminderOffsetMinutes,
          reminderAt: _reminderAt,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(actingMemberIdProvider),
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
          initialReminderType: _reminderType,
          initialReminderOffsetMinutes: _reminderOffsetMinutes,
          initialReminderAt: _reminderAt,
          initialReminderIsDefault: !_reminderPicked,
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
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // The title is the one thing every quick-added task needs, so
              // it gets the full width of the sheet and room to wrap — not
              // squeezed beside the mic button the way it used to be.
              Text(l10n.taskFormQuestion,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.taskFormTitleHint,
                  filled: true,
                  fillColor: context.colors.background,
                  contentPadding: const EdgeInsets.all(16),
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Only the two decisions most tasks actually need are visible
              // by default — date (defaulted to today) and assignee
              // (defaulted to whoever's adding it). Reminder and priority
              // move under "More" instead of claiming their own chip, since
              // most quick-added tasks never touch either.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DropdownChip(
                    label: _dueDate!.relativeDay,
                    active: true,
                    onTap: _pickDate,
                  ),
                  _DropdownChip(
                    label: assignee?.name ?? l10n.quickAddTaskAssignShort,
                    active: assignee != null,
                    onTap: _pickAssignee,
                  ),
                  PopupMenuButton<_MoreAction>(
                    tooltip: '',
                    offset: const Offset(0, 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (action) => switch (action) {
                      _MoreAction.reminder => _pickReminder(),
                      _MoreAction.priority => _pickPriority(),
                      _MoreAction.fullEditor => _openFullEditor(),
                    },
                    itemBuilder: (context) => [
                      _buildMoreMenuItem(
                        context,
                        value: _MoreAction.reminder,
                        icon: Icons.notifications_outlined,
                        label: l10n.taskFormReminder,
                        valueLabel: _reminderType == TaskReminderType.dueTime
                            ? null
                            : reminderSummaryLabel(
                                l10n,
                                type: _reminderType,
                                offsetMinutes: _reminderOffsetMinutes,
                                reminderAt: _reminderAt,
                              ),
                      ),
                      _buildMoreMenuItem(
                        context,
                        value: _MoreAction.priority,
                        icon: (priority ?? TaskPriority.normal).icon,
                        label: l10n.labelPriority,
                        valueLabel: priority?.label(l10n),
                      ),
                      const PopupMenuDivider(),
                      _buildMoreMenuItem(
                        context,
                        value: _MoreAction.fullEditor,
                        icon: Icons.tune_rounded,
                        label: l10n.quickAddTaskMoreOptions,
                      ),
                    ],
                    child: _DropdownChip(
                      label: l10n.quickAddTaskMoreShort,
                      active: _reminderType != TaskReminderType.dueTime || priority != null,
                    ),
                  ),
                ],
              ),
              if (_reminderError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _reminderError!,
                  style: TextStyle(color: context.colors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? context.colors.danger : Colors.amber.shade800,
                    ),
                    label: Text(
                      l10n.quickAddTaskVoiceInput,
                      style: TextStyle(
                        color: _isListening ? context.colors.danger : Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed:
                        _titleController.text.trim().isEmpty ? null : _save,
                    child: Text(l10n.quickAddTaskAdd),
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

enum _MoreAction { reminder, priority, fullEditor }

/// One row inside the "More" popup menu — an icon, a label, and (when set)
/// the current value, so reminder/priority aren't just named but show their
/// state without needing their own chip in the row above.
PopupMenuItem<_MoreAction> _buildMoreMenuItem(
  BuildContext context, {
  required _MoreAction value,
  required IconData icon,
  required String label,
  String? valueLabel,
}) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.colors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (valueLabel != null) ...[
          const SizedBox(width: 8),
          Text(
            valueLabel,
            style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    ),
  );
}

/// A pill-shaped "value + dropdown caret" button — used for the date and
/// assignee shortcuts, and reused (with [onTap] omitted) as the visible
/// face of the "More" [PopupMenuButton], which provides its own tap
/// handling and shouldn't get a second, competing one from here.
class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.active,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: active ? context.colors.accent.withValues(alpha: 0.12) : context.colors.background,
        border: Border.all(color: active ? context.colors.accent : context.colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? context.colors.accent : context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: active ? context.colors.accent : context.colors.textSecondary,
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: pill);
  }
}
