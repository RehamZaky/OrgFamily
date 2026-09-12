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

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}

  @override
  Future<void> scheduleTaskOverdueFollowup({
    required String taskId,
    required String title,
    required String body,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancelTaskOverdueFollowup(String taskId) async {}

  @override
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime startAt,
  }) async {}

  @override
  Future<void> cancelEventReminder(String eventId) async {}
}
