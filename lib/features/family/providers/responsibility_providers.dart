import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/database.dart';
import '../../../data/local/tables/responsibilities_table.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_settings_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../responsibility_schedule.dart';
import 'family_providers.dart';

final responsibilitiesForMemberProvider =
    StreamProvider.family<List<Responsibility>, String>((ref, memberId) {
  return ref.read(responsibilityRepositoryProvider).watchForMember(memberId);
});

/// The acting member's responsibilities due today — Home's "My
/// responsibilities". Empty when nobody's acting (an unresolved identity).
final myResponsibilitiesDueTodayProvider = Provider<List<Responsibility>>((ref) {
  final memberId = ref.watch(actingMemberIdProvider);
  if (memberId == null) return const [];
  final all = ref.watch(responsibilitiesForMemberProvider(memberId)).valueOrNull ?? const [];
  final today = DateTime.now();
  final schoolDays = ref.watch(familyScheduleProvider).valueOrNull?.schoolWeekdays ??
      FamilySchedule.defaults.schoolWeekdays;
  return [for (final r in all) if (isDueOn(r, today, schoolDays: schoolDays)) r];
});

/// A date in the week of a given `DateTime.weekday` value, for formatting
/// its localized name.
DateTime _dayWithWeekday(int weekday) => DateTime(2024, 1, weekday); // 2024-01-01 is a Monday

/// Localized weekday name, e.g. "Monday" / "الاثنين".
String weekdayName(int weekday, String locale) =>
    DateFormat.EEEE(locale).format(_dayWithWeekday(weekday));

/// Localized short weekday name, e.g. "Mon".
String weekdayShortName(int weekday, String locale) =>
    DateFormat.E(locale).format(_dayWithWeekday(weekday));

/// Weekdays in the order this family's week runs: Sunday first.
const weekdaysSundayFirst = [
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
];

/// Human-readable schedule text, e.g. "Daily", "School days (Sun–Thu)", or
/// "Every Monday, Wednesday" for a custom set of weekdays.
String responsibilityScheduleLabel(Responsibility r, AppLocalizations l10n, String locale) {
  switch (r.recurrence) {
    case ResponsibilityRecurrence.daily:
      return l10n.responsibilityDaily;
    case ResponsibilityRecurrence.schoolDays:
      return l10n.responsibilitySchoolDays;
    case ResponsibilityRecurrence.custom:
      final days = scheduledWeekdays(r);
      if (days.isEmpty) return l10n.responsibilityCustom;
      final ordered = [for (final d in weekdaysSundayFirst) if (days.contains(d)) d];
      // Arabic lists use the Arabic comma.
      final separator = locale.startsWith('ar') ? '، ' : ', ';
      return l10n.responsibilityEvery(
        ordered.map((d) => weekdayName(d, locale)).join(separator),
      );
  }
}
