import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels local reminders for tasks and events. No backend
/// involved — everything is scheduled on-device via
/// `flutter_local_notifications`, matching V1's local-first constraint.
///
/// Notification ids are derived deterministically from the entity's uuid so
/// re-scheduling (on edit) and cancelling (on delete/complete) can address
/// the same notification without needing to store a separate int id.
/// Tasks and events are kept in disjoint id ranges to avoid collisions.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _androidChannelId = 'org_family_reminders';
  static const _androidChannelName = 'Reminders';
  static const _windowsAppUserModelId = 'OrgFamily.FamilyOrganizer';
  static const _windowsGuid = 'a3f1d9e2-6b7c-4e4a-9c3e-2f6b1d8a7c50';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Falls back to UTC if the platform timezone can't be resolved —
      // reminders still fire, just anchored to UTC instead of local time.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open OrgFamily'),
        windows: WindowsInitializationSettings(
          appName: 'OrgFamily',
          appUserModelId: _windowsAppUserModelId,
          guid: _windowsGuid,
        ),
      ),
    );
    _initialized = true;
  }

  /// Checks (and if needed, requests) notification permission every time a
  /// reminder is scheduled — rather than caching after the first attempt —
  /// so a user who denies it once still gets asked again next time instead
  /// of reminders silently going nowhere forever.
  Future<void> _ensurePermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final alreadyEnabled = await android?.areNotificationsEnabled();
      if (alreadyEnabled == true) return;
      await android?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  int _taskNotificationId(String id) => (id.hashCode & 0x3fffffff) * 2;
  int _eventNotificationId(String id) => (id.hashCode & 0x3fffffff) * 2 + 1;

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    await init();
    await _ensurePermission();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'Reminders for due tasks and upcoming events',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  Future<void> _cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime dueDate,
  }) {
    return _schedule(
      id: _taskNotificationId(taskId),
      title: title,
      body: body,
      at: dueDate,
    );
  }

  Future<void> cancelTaskReminder(String taskId) =>
      _cancel(_taskNotificationId(taskId));

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime startAt,
  }) {
    return _schedule(
      id: _eventNotificationId(eventId),
      title: title,
      body: 'Starting in 15 minutes',
      at: startAt.subtract(const Duration(minutes: 15)),
    );
  }

  Future<void> cancelEventReminder(String eventId) =>
      _cancel(_eventNotificationId(eventId));
}
