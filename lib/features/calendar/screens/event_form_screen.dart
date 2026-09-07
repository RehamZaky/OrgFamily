import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/events_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({
    super.key,
    this.initialDate,
    this.existing,
    this.initialMemberId,
  });

  final DateTime? initialDate;
  final Event? existing;
  final String? initialMemberId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  late final _titleController =
      TextEditingController(text: widget.existing?.title);
  late final _locationController =
      TextEditingController(text: widget.existing?.location);
  late DateTime _startAt;
  late EventCategory _category;
  String? _memberId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _startAt = e.startAt;
      _category = e.category;
      _memberId = e.memberId;
    } else {
      final base = widget.initialDate ?? DateTime.now();
      _startAt = DateTime(base.year, base.month, base.day, 9, 0);
      _category = EventCategory.other;
      _memberId = widget.initialMemberId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
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

  Future<void> _pickDateTime() async {
    _unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    _unfocus();
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    _unfocus();
    if (time == null) return;
    setState(() {
      _startAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickCategory() async {
    _unfocus();
    final l10n = AppLocalizations.of(context)!;
    final category = await showOptionPickerSheet<EventCategory>(
      context: context,
      title: l10n.labelCategory,
      options: EventCategory.values,
      labelBuilder: (c) => c.label(l10n),
      iconBuilder: (c) => c.icon,
      selected: _category,
    );
    _unfocus();
    if (category != null) setState(() => _category = category);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final location =
        _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final repo = ref.read(eventRepositoryProvider);
    if (widget.existing == null) {
      await repo.addEvent(
        id: const Uuid().v4(),
        title: title,
        startAt: _startAt,
        location: location,
        category: _category,
        memberId: _memberId,
      );
    } else {
      await repo.updateEvent(widget.existing!.copyWith(
        title: title,
        startAt: _startAt,
        location: Value(location),
        category: _category,
        memberId: Value(_memberId),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.eventFormDeleteTitle),
        content: Text(l10n.eventFormDeleteBody(widget.existing!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.priorityHigh),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(eventRepositoryProvider).deleteEvent(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  static const _fieldRadius = 14.0;

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.eventFormEditTitle : l10n.eventFormNewTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        titleSpacing: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: l10n.delete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_outlined, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            isEditing ? l10n.eventFormSubtitleEdit : l10n.eventFormSubtitleNew,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldRow(
                  icon: Icons.title_rounded,
                  label: l10n.labelTitle,
                  field: TextField(
                    controller: _titleController,
                    decoration: _fieldDecoration(l10n.eventFormTitleHint),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: !isEditing,
                  ),
                ),
                const SizedBox(height: 20),
                _FieldRow(
                  icon: Icons.location_on_outlined,
                  label: l10n.eventFormLocationLabel,
                  field: TextField(
                    controller: _locationController,
                    decoration: _fieldDecoration(l10n.eventFormLocationHint),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldRow(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.labelDateTime,
                  field: InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(_fieldRadius),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_startAt.month}/${_startAt.day}/${_startAt.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                              width: 1, height: 20, color: Colors.grey.shade300),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(TimeOfDay.fromDateTime(_startAt).format(context),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldRow(
                  icon: Icons.sell_outlined,
                  label: l10n.labelCategory,
                  field: InkWell(
                    onTap: _pickCategory,
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(_fieldRadius),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_category.label(l10n))),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldRow(
                  icon: Icons.people_alt_outlined,
                  label: l10n.labelWho,
                  field: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _memberId = null),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: _memberId == null
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              child: const Icon(Icons.people_outline, size: 18),
                            ),
                          ),
                          ...members.map((m) {
                            final selected = m.id == _memberId;
                            return GestureDetector(
                              onTap: () => setState(() => _memberId = m.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: AppColors.primary, width: 2)
                                      : null,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: MemberAvatar(member: m, radius: 18),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.eventFormWhoHint,
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.event_available_outlined),
            label: Text(isEditing ? l10n.eventFormSaveChangesButton : l10n.eventFormSaveButton),
          ),
        ],
      ),
    );
  }
}

/// Icon-in-rounded-square + label-above-field row, matching the "New Event"
/// design's layout (distinct from [PickerRow], which is icon-in-circle with
/// an inline label/value/chevron — this one stacks an editable field below
/// the label instead).
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.label, required this.field});

  final IconData icon;
  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              field,
            ],
          ),
        ),
      ],
    );
  }
}
