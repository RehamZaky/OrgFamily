import 'package:flutter/material.dart';

import '../../../core/utils/date_format_x.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/task_status_calculator.dart';
import '../../../core/theme/app_color_scheme.dart';

/// What the reminder picker sheet returned — mirrors the three
/// [Tasks.reminderType]/[Tasks.reminderOffsetMinutes]/[Tasks.reminderAt]
/// columns it edits.
class ReminderSelection {
  const ReminderSelection({
    required this.type,
    this.offsetMinutes,
    this.reminderAt,
  });

  final TaskReminderType type;
  final int? offsetMinutes;
  final DateTime? reminderAt;
}

/// The offset presets shown in the sheet, minutes-before-due plus the
/// label key used to display them.
const _offsetPresets = [15, 30, 60, 1440];

String _offsetLabel(AppLocalizations l10n, int minutes) => switch (minutes) {
      15 => l10n.reminderOption15MinBefore,
      30 => l10n.reminderOption30MinBefore,
      60 => l10n.reminderOption1HourBefore,
      1440 => l10n.reminderOption1DayBefore,
      _ => l10n.reminderOption1HourBefore,
    };

/// "1 hour before", "At the due time", "No reminder", or the picked
/// date/time for a custom reminder — the single place both the picker sheet
/// and the task form's summary line read a reminder selection's label from.
String reminderSummaryLabel(
  AppLocalizations l10n, {
  required TaskReminderType type,
  int? offsetMinutes,
  DateTime? reminderAt,
}) {
  return switch (type) {
    TaskReminderType.none => l10n.reminderOptionNone,
    TaskReminderType.dueTime => l10n.reminderOptionDueTime,
    TaskReminderType.custom =>
      reminderAt == null ? l10n.reminderOptionCustom : reminderAt.relativeDayAndTime,
    TaskReminderType.offset => _offsetLabel(l10n, offsetMinutes ?? 0),
  };
}

/// Shows the reminder picker bottom sheet and returns the user's choice, or
/// null if they dismissed it without picking anything. Callers must have a
/// due date set before opening this — a reminder is always relative to (or,
/// for a custom pick, at least meaningful alongside) one; show
/// [AppLocalizations.reminderSelectDueDateFirst] instead of opening this if
/// there isn't one yet. [dueDate]/[dueTimeMinutes] are the form's *current*
/// (possibly unsaved) due date/time — needed to validate a preset/offset
/// doesn't land in the past and to compute a custom pick's default starting
/// point.
Future<ReminderSelection?> showReminderPickerSheet({
  required BuildContext context,
  required DateTime dueDate,
  required int? dueTimeMinutes,
  required TaskReminderType currentType,
  required int? currentOffsetMinutes,
  required DateTime? currentReminderAt,
}) {
  return showModalBottomSheet<ReminderSelection>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _ReminderPickerSheet(
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
      currentType: currentType,
      currentOffsetMinutes: currentOffsetMinutes,
      currentReminderAt: currentReminderAt,
    ),
  );
}

class _ReminderPickerSheet extends StatefulWidget {
  const _ReminderPickerSheet({
    required this.dueDate,
    required this.dueTimeMinutes,
    required this.currentType,
    required this.currentOffsetMinutes,
    required this.currentReminderAt,
  });

  final DateTime dueDate;
  final int? dueTimeMinutes;
  final TaskReminderType currentType;
  final int? currentOffsetMinutes;
  final DateTime? currentReminderAt;

  @override
  State<_ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<_ReminderPickerSheet> {
  String? _error;

  /// The due moment presets/offset are computed against. [taskReminderAt]
  /// only returns null for a null due date, which can't happen here: every
  /// caller of [showReminderPickerSheet] guarantees a due date is set
  /// before opening this sheet — see that function's doc comment.
  DateTime get _dueMoment => taskReminderAt(TaskDeadlineInput(
        dueDate: widget.dueDate,
        dueTimeMinutes: widget.dueTimeMinutes,
        isCompleted: false,
      ))!;

  bool _isPast(DateTime at) => !at.isAfter(DateTime.now());

  void _showPastError() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = l10n.reminderPastError);
  }

  void _pickDueTime() {
    if (_isPast(_dueMoment)) return _showPastError();
    Navigator.of(context).pop(const ReminderSelection(type: TaskReminderType.dueTime));
  }

  void _pickOffset(int minutes) {
    if (_isPast(_dueMoment.subtract(Duration(minutes: minutes)))) {
      return _showPastError();
    }
    Navigator.of(context)
        .pop(ReminderSelection(type: TaskReminderType.offset, offsetMinutes: minutes));
  }

  void _pickNone() {
    Navigator.of(context).pop(const ReminderSelection(type: TaskReminderType.none));
  }

  void _remindNow() {
    Navigator.of(context).pop(ReminderSelection(
      type: TaskReminderType.custom,
      reminderAt: DateTime.now().add(const Duration(minutes: 1)),
    ));
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final seed = widget.currentReminderAt ?? _dueMoment;
    final date = await showDatePicker(
      context: context,
      initialDate: seed.isBefore(now) ? now : seed,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (_isPast(picked)) return _showPastError();
    Navigator.of(context).pop(ReminderSelection(type: TaskReminderType.custom, reminderAt: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.currentType;

    Widget tile({
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return ListTile(
        title: Text(label),
        trailing: selected ? Icon(Icons.check, color: context.colors.accent) : null,
        onTap: onTap,
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.taskFormReminder,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: context.colors.danger, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _remindNow,
                      child: Text(l10n.reminderRemindNow),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  tile(
                    selected: current == TaskReminderType.dueTime,
                    label: l10n.reminderOptionDueTime,
                    onTap: _pickDueTime,
                  ),
                  for (final minutes in _offsetPresets)
                    tile(
                      selected:
                          current == TaskReminderType.offset && widget.currentOffsetMinutes == minutes,
                      label: _offsetLabel(l10n, minutes),
                      onTap: () => _pickOffset(minutes),
                    ),
                  tile(
                    selected: current == TaskReminderType.custom,
                    label: current == TaskReminderType.custom && widget.currentReminderAt != null
                        ? widget.currentReminderAt!.relativeDayAndTime
                        : l10n.reminderOptionCustom,
                    onTap: _pickCustom,
                  ),
                  tile(
                    selected: current == TaskReminderType.none,
                    label: l10n.reminderOptionNone,
                    onTap: _pickNone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
