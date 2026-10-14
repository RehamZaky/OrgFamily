import 'package:org_family/core/notifications/notification_service.dart';

/// No-op stand-in for tests — avoids touching real platform notification
/// channels, which aren't available under `flutter_test`.
class FakeNotificationService implements NotificationService {
  @override
  void Function(String type, String id)? onNotificationTapped;

  @override
  Future<void> init() async {}

  @override
  Future<void> handlePendingLaunch() async {}

  /// What [notificationsEnabled] reports; [requestNotificationPermission]
  /// sets it to [grantOnRequest].
  bool? enabled = true;
  bool? grantOnRequest = true;
  int permissionRequests = 0;

  @override
  Future<bool?> notificationsEnabled() async => enabled;

  @override
  Future<bool?> requestNotificationPermission() async {
    permissionRequests++;
    return enabled = grantOnRequest;
  }

  /// Task reminders currently scheduled: task id → when.
  final taskReminders = <String, DateTime>{};

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    taskReminders[taskId] = dueDate;
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async => taskReminders.remove(taskId);

  @override
  Future<void> scheduleTaskOverdueFollowup({
    required String taskId,
    required String title,
    required String body,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancelTaskOverdueFollowup(String taskId) async {}

  /// Event reminders currently scheduled: event id → minutes before, and
  /// event id → when.
  final eventReminders = <String, int>{};
  final eventReminderTimes = <String, DateTime>{};

  @override
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime startAt,
    int? minutesBefore = 15,
  }) async {
    if (minutesBefore == null) {
      eventReminders.remove(eventId);
      eventReminderTimes.remove(eventId);
    } else {
      eventReminders[eventId] = minutesBefore;
      eventReminderTimes[eventId] = startAt.subtract(Duration(minutes: minutesBefore));
    }
  }

  @override
  Future<void> cancelEventReminder(String eventId) async {
    eventReminders.remove(eventId);
    eventReminderTimes.remove(eventId);
  }

  /// Daily responsibilities reminders currently scheduled, by slot.
  final dailyReminders = <int, ({String title, String body, DateTime at})>{};

  @override
  Future<void> scheduleDailyResponsibilityReminder({
    required int slot,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    dailyReminders[slot] = (title: title, body: body, at: at);
  }

  @override
  Future<void> cancelDailyResponsibilityReminders() async => dailyReminders.clear();
}
