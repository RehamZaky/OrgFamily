import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_settings_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/responsibility_providers.dart';
import '../providers/reminder_providers.dart';
import 'settings_group.dart';

// The V2.2 behaviour settings: time format, start tab, reminders (per
// profile on this phone) and the family schedule (shared, Owner-only).

/// A short explanation under a settings group.
class SettingsGroupHint extends StatelessWidget {
  const SettingsGroupHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 6, 0),
    child: Text(text, style: SettingsText.subtitle(context)),
  );
}

/// A bottom sheet listing [options]; returns the picked one wrapped in a
/// record (so a nullable value can be picked), or null if dismissed.
Future<(T,)?> showSettingsChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
  String? hint,
}) {
  return showModalBottomSheet<(T,)>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(title, style: SettingsText.title(context).copyWith(fontSize: 16)),
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                child: Text(hint, style: SettingsText.subtitle(context)),
              ),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                selected: value == selected,
                trailing: value == selected ? Icon(Icons.check, color: context.colors.accent) : null,
                onTap: () => Navigator.pop(context, (value,)),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _valueText(BuildContext context, String value) => Padding(
  padding: const EdgeInsetsDirectional.only(start: 8),
  child: Text(value, style: SettingsText.subtitle(context)),
);

class TimeFormatSettingRow extends ConsumerWidget {
  const TimeFormatSettingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsControlRow(
      icon: Icons.schedule_rounded,
      color: context.colors.accent,
      title: l10n.settingsTimeFormat,
      hint: l10n.settingsTimeFormatExample(formatTime(context, DateTime(2026, 1, 1, 15, 30))),
      control: SegmentedButton<TimeFormatPreference>(
        style: settingsSegmentedStyle(),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: TimeFormatPreference.system,
            label: Text(l10n.settingsTimeFormatSystem),
          ),
          ButtonSegment(value: TimeFormatPreference.h12, label: Text(l10n.settingsTimeFormat12)),
          ButtonSegment(value: TimeFormatPreference.h24, label: Text(l10n.settingsTimeFormat24)),
        ],
        selected: {ref.watch(timeFormatProvider)},
        onSelectionChanged: (s) => ref.read(timeFormatProvider.notifier).set(s.first),
      ),
    );
  }
}

String startTabLabel(AppLocalizations l10n, StartTab tab) => switch (tab) {
  StartTab.home => l10n.navHome,
  StartTab.tasks => l10n.navTasks,
  StartTab.calendar => l10n.navCalendar,
  StartTab.lists => l10n.navLists,
  StartTab.family => l10n.navFamily,
  StartTab.money => l10n.navBudget,
};

class StartTabSettingRow extends ConsumerWidget {
  const StartTabSettingRow({super.key, required this.canViewFinances});

  /// Money is only offered to profiles that can see it (it still opens on
  /// Home for anyone else, without losing a saved Money choice).
  final bool canViewFinances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tab = ref.watch(startTabProvider);
    return SettingsRow(
      icon: Icons.start_rounded,
      color: context.colors.accent,
      title: l10n.settingsStartTab,
      trailing: _valueText(context, startTabLabel(l10n, tab)),
      onTap: () async {
        final picked = await showSettingsChoiceSheet<StartTab>(
          context,
          title: l10n.settingsStartTab,
          selected: tab,
          options: [
            for (final t in StartTab.values)
              if (t != StartTab.money || canViewFinances) (t, startTabLabel(l10n, t)),
          ],
        );
        if (picked != null) ref.read(startTabProvider.notifier).set(picked.$1);
      },
    );
  }
}

/// Minutes-before options shared by the task and event reminder defaults
/// (the same choices as the task reminder picker).
List<(int?, String)> _minutesOptions(AppLocalizations l10n, {required bool atDueTime}) => [
  (null, l10n.reminderOptionNone),
  if (atDueTime) (0, l10n.reminderOptionDueTime),
  (15, l10n.reminderOption15MinBefore),
  (30, l10n.reminderOption30MinBefore),
  (60, l10n.reminderOption1HourBefore),
  (1440, l10n.reminderOption1DayBefore),
];

String _minutesLabel(AppLocalizations l10n, int? minutes, {required bool atDueTime}) =>
    _minutesOptions(l10n, atDueTime: atDueTime).where((o) => o.$1 == minutes).firstOrNull?.$2 ??
    l10n.reminderOptionNone;

/// Reminder choices of the profile using the phone now — each person on a
/// shared phone keeps their own.
class RemindersSettingsSection extends ConsumerWidget {
  const RemindersSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final member = ref.watch(reminderOwnerProvider);
    final notifier = ref.read(reminderPreferencesProvider(member?.id).notifier);
    final prefs = ref.watch(reminderPreferencesProvider(member?.id));
    final daily = prefs.dailyAtMinutes;
    final color = context.colors.warning;

    Future<void> pickDailyTime() async {
      final initial = daily ?? 19 * 60;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      );
      if (time != null) {
        notifier.set(prefs.copyWith(dailyAtMinutes: () => time.hour * 60 + time.minute));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.add_task,
              color: color,
              title: l10n.settingsTaskReminder,
              trailing: _valueText(
                context,
                _minutesLabel(l10n, prefs.taskDefault, atDueTime: true),
              ),
              onTap: () async {
                final picked = await showSettingsChoiceSheet<int?>(
                  context,
                  title: l10n.settingsTaskReminder,
                  hint: l10n.settingsTaskReminderHint,
                  selected: prefs.taskDefault,
                  options: _minutesOptions(l10n, atDueTime: true),
                );
                if (picked != null) notifier.set(prefs.copyWith(taskDefault: () => picked.$1));
              },
            ),
            SettingsRow(
              icon: Icons.event_outlined,
              color: color,
              title: l10n.settingsEventReminder,
              trailing: _valueText(
                context,
                _minutesLabel(l10n, prefs.eventMinutes, atDueTime: false),
              ),
              onTap: () async {
                final picked = await showSettingsChoiceSheet<int?>(
                  context,
                  title: l10n.settingsEventReminder,
                  hint: l10n.settingsEventReminderHint,
                  selected: prefs.eventMinutes,
                  options: _minutesOptions(l10n, atDueTime: false),
                );
                if (picked != null) notifier.set(prefs.copyWith(eventMinutes: () => picked.$1));
              },
            ),
            SettingsRow(
              icon: Icons.task_alt,
              color: color,
              title: l10n.settingsDailyReminder,
              subtitle: daily == null
                  ? l10n.settingsDailyReminderOff
                  : formatTime(context, DateTime(2000, 1, 1, daily ~/ 60, daily % 60)),
              onTap: pickDailyTime,
              trailing: Switch(
                value: daily != null,
                onChanged: (on) => on
                    ? pickDailyTime()
                    : notifier.set(prefs.copyWith(dailyAtMinutes: () => null)),
              ),
            ),
          ],
        ),
        // The longer explanations for new tasks and events are in their
        // choice sheets; only what applies to the whole group stays here.
        if (member != null) SettingsGroupHint(l10n.settingsRemindersFor(member.name)),
        SettingsGroupHint(l10n.settingsDailyReminderHint),
      ],
    );
  }
}

/// Whether the signed-in **account** may change the family schedule — the
/// family Owner's, never decided by the acting profile.
final familyScheduleEditableProvider = FutureProvider<bool>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  return ref.watch(familySettingsRepositoryProvider).canEdit(uid);
});

/// School days and week start — shared by the whole family, Owner-only.
class FamilyScheduleSettingsSection extends ConsumerWidget {
  const FamilyScheduleSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final schedule = ref.watch(familyScheduleProvider).valueOrNull ?? FamilySchedule.defaults;
    final canEdit = ref.watch(familyScheduleEditableProvider).valueOrNull ?? false;
    final color = context.colors.success;

    Future<void> save(FamilySchedule next) => ref
        .read(familySettingsRepositoryProvider)
        .save(next, signedInUid: ref.read(authStateProvider).valueOrNull?.uid);

    // The week as the family sees it, from its first day.
    final days = [for (var i = 0; i < 7; i++) (schedule.weekStartDay - 1 + i) % 7 + 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            SettingsControlRow(
              icon: Icons.school_outlined,
              color: color,
              title: l10n.settingsSchoolDays,
              hint: l10n.settingsSchoolDaysHint,
              control: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in days)
                    FilterChip(
                      label: Text(weekdayShortName(d, locale)),
                      selected: schedule.schoolWeekdays.contains(d),
                      showCheckmark: false,
                      onSelected: canEdit
                          ? (on) => save(
                              FamilySchedule(
                                schoolWeekdays: on
                                    ? {...schedule.schoolWeekdays, d}
                                    : ({...schedule.schoolWeekdays}..remove(d)),
                                weekStartDay: schedule.weekStartDay,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            SettingsRow(
              icon: Icons.calendar_view_week_outlined,
              color: color,
              title: l10n.settingsWeekStart,
              trailing: _valueText(context, weekdayName(schedule.weekStartDay, locale)),
              onTap: canEdit
                  ? () async {
                      final picked = await showSettingsChoiceSheet<int>(
                        context,
                        title: l10n.settingsWeekStart,
                        selected: schedule.weekStartDay,
                        options: [for (final d in weekdaysSundayFirst) (d, weekdayName(d, locale))],
                      );
                      if (picked != null) {
                        await save(
                          FamilySchedule(
                            schoolWeekdays: schedule.schoolWeekdays,
                            weekStartDay: picked.$1,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
        SettingsGroupHint(l10n.settingsFamilyScheduleOwnerOnly),
      ],
    );
  }
}
