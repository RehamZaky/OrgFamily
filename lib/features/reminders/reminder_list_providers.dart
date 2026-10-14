import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../data/repositories/family_settings_repository.dart';
import '../calendar/providers/event_providers.dart';
import '../family/providers/responsibility_providers.dart';
import '../settings/providers/reminder_providers.dart';
import '../tasks/providers/task_providers.dart';
import 'planned_reminders.dart';

/// Everything My reminders plans from — the same records and settings the
/// scheduler reads (`TaskRepository`, `EventRepository`,
/// `DailyResponsibilityReminders`), loading until each has arrived.
final phoneReminderInputsProvider = Provider.autoDispose<AsyncValue<PhoneReminderInputs>>((ref) {
  final owner = ref.watch(reminderOwnerProvider);
  final prefs = ref.watch(phoneReminderPreferencesProvider);
  final tasks = ref.watch(allTasksProvider);
  final events = ref.watch(allEventsProvider);
  final eventMembers = ref.watch(allEventMembersProvider);
  final chores = owner == null
      ? const AsyncData(<Responsibility>[])
      : ref.watch(responsibilitiesForMemberProvider(owner.id));
  final schedule = ref.watch(familyScheduleProvider);
  for (final AsyncValue<Object?> v in [tasks, events, eventMembers, chores, schedule]) {
    if (v case AsyncError(:final error, :final stackTrace)) return AsyncError(error, stackTrace);
  }
  if (!tasks.hasValue || !events.hasValue || !eventMembers.hasValue || !chores.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(PhoneReminderInputs(
    ownerId: owner?.id,
    tasks: tasks.requireValue,
    events: events.requireValue,
    eventMembers: eventMembers.requireValue,
    eventMinutesBefore: prefs.eventMinutes,
    dailyAtMinutes: prefs.dailyAtMinutes,
    ownerResponsibilities: chores.requireValue,
    schoolDays: (schedule.valueOrNull ?? FamilySchedule.defaults).schoolWeekdays,
  ));
});

/// Whether this phone may show notifications (null = can't tell). Read
/// again when My reminders opens, returns to the foreground, or asks.
final notificationPermissionProvider = FutureProvider.autoDispose<bool?>((ref) {
  return ref.watch(notificationServiceProvider).notificationsEnabled();
});
