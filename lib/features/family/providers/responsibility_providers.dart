import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/local/tables/responsibilities_table.dart';
import '../../../data/providers.dart';

final responsibilitiesForMemberProvider =
    StreamProvider.family<List<Responsibility>, String>((ref, memberId) {
  return ref.read(responsibilityRepositoryProvider).watchForMember(memberId);
});

const _weekdayNames = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// Human-readable schedule text, e.g. "Daily", "Every School Day", or
/// "Every Monday, Wednesday, Friday" for a custom set of weekdays.
String responsibilityScheduleLabel(Responsibility r) {
  switch (r.recurrence) {
    case ResponsibilityRecurrence.daily:
      return 'Daily';
    case ResponsibilityRecurrence.schoolDays:
      return 'Every School Day';
    case ResponsibilityRecurrence.custom:
      final days = (r.customWeekdays ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList()
        ..sort();
      if (days.isEmpty) return 'Custom';
      return 'Every ${days.map((d) => _weekdayNames[d]).join(', ')}';
  }
}
