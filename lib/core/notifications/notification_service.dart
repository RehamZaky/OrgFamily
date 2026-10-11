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
///
/// Rescheduling after a reboot or app update is handled by the plugin's own
/// native receivers (registered in AndroidManifest.xml for
/// `BOOT_COMPLETED`/`MY_PACKAGE_REPLACED`/`QUICKBOOT_POWERON`), which replay
/// whatever was last scheduled. Since that replay is a snapshot rather than
/// a live read of the database, `main()` additionally calls
/// `TaskRepository.resyncReminders()` / `EventRepository.resyncReminders()`
/// on every app start, so a task/event edited while the app was closed
/// still gets the up-to-date reminder rather than a stale one.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;

  static const _androidChannelId = 'org_family_reminders';
  static const _androidChannelName = 'Reminders';
  static const _windowsAppUserModelId = 'OrgFamily.FamilyOrganizer';
  static const _windowsGuid = 'a3f1d9e2-6b7c-4e4a-9c3e-2f6b1d8a7c50';

  /// Set by the app shell once the navigator is mounted. Called with
  /// (`'task'` or `'event'`, entity id) whenever a reminder notification is
  /// tapped — including the cold-start case, via [handlePendingLaunch].
  void Function(String type, String id)? onNotificationTapped;

  Future<void> init() async {
    // Local timezone is re-resolved on every init() call (not just the
    // first), so a device timezone change mid-session — travel, or the OS
    // switching for DST — is picked up by the next reminder that gets
    // scheduled, rather than staying pinned to whatever was true at app
    // start. The plugin registration itself only needs to happen once.
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Falls back to UTC if the platform timezone can't be resolved —
      // reminders still fire, just anchored to UTC instead of local time.
    }

    if (_pluginInitialized) return;
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
      onDidReceiveNotificationResponse: (response) => _dispatch(response.payload),
    );
    _pluginInitialized = true;
  }

  /// Handles the case where the app was launched *by* tapping a
  /// notification (it wasn't already running to receive the tap via
  /// [onDidReceiveNotificationResponse]). Call once, after the first frame
  /// so [onNotificationTapped] has somewhere to navigate to.
  Future<void> handlePendingLaunch() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      _dispatch(details?.notificationResponse?.payload);
    }
  }

  void _dispatch(String? payload) {
    if (payload == null) return;
    final i = payload.indexOf(':');
    if (i < 0) return;
    onNotificationTapped?.call(payload.substring(0, i), payload.substring(i + 1));
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

  // Four disjoint ids per entity (task due, event start, task overdue
  // follow-up, +1 spare) so none of these can ever collide with another.
  // Masked to 29 bits, not 30: `* 4 + 3` (the highest of the four) must
  // still fit a signed 32-bit int, which flutter_local_notifications
  // requires — 30 bits masked in would let `* 4` overflow past 2^31-1 for
  // roughly half of all hashCodes, throwing an unhandled platform-channel
  // ArgumentError the moment a task/event with an unlucky hashCode got a
  // reminder scheduled or cancelled.
  int _taskNotificationId(String id) => (id.hashCode & 0x1fffffff) * 4;
  int _eventNotificationId(String id) => (id.hashCode & 0x1fffffff) * 4 + 1;
  int _taskOverdueFollowupId(String id) => (id.hashCode & 0x1fffffff) * 4 + 2;

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    try {
      await init();
      await _ensurePermission();
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
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
    } catch (_) {
      // Best-effort, like the timezone resolution above: the task/event
      // itself is already saved by the time this runs (see
      // TaskRepository/EventRepository — the DB write happens first), so a
      // plugin/permission hiccup here must not surface as a save failure
      // and leave the caller's form stuck open re-throwing on every retry.
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await init();
      await _plugin.cancel(id: id);
    } catch (_) {
      // Best-effort, same reasoning as _schedule's catch above — a
      // cancel failure must never block whatever task/event write
      // triggered it (e.g. every addTask/updateTask call, regardless of
      // whether that entity has a due date, cancels first to clear any
      // stale reminder).
    }
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
      payload: 'task:$taskId',
    );
  }

  Future<void> cancelTaskReminder(String taskId) =>
      _cancel(_taskNotificationId(taskId));

  /// The single, non-repeating nudge sent if a task is still incomplete
  /// some time after it went overdue — see [taskOverdueFollowupAt] in
  /// task_status_calculator.dart for exactly when.
  Future<void> scheduleTaskOverdueFollowup({
    required String taskId,
    required String title,
    required String body,
    required DateTime at,
  }) {
    return _schedule(
      id: _taskOverdueFollowupId(taskId),
      title: title,
      body: body,
      at: at,
      payload: 'task:$taskId',
    );
  }

  Future<void> cancelTaskOverdueFollowup(String taskId) =>
      _cancel(_taskOverdueFollowupId(taskId));

  /// [minutesBefore] comes from this phone's "event reminder" setting;
  /// null means no reminder (any scheduled one is cancelled).
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime startAt,
    int? minutesBefore = 15,
  }) async {
    final id = _eventNotificationId(eventId);
    if (minutesBefore == null) return _cancel(id);
    return _schedule(
      id: id,
      title: title,
      body: minutesBefore == 0 ? 'Starting now' : 'Starting in $minutesBefore minutes',
      at: startAt.subtract(Duration(minutes: minutesBefore)),
      payload: 'event:$eventId',
    );
  }

  Future<void> cancelEventReminder(String eventId) =>
      _cancel(_eventNotificationId(eventId));

  /// How many days ahead the daily responsibilities reminder is planned
  /// (see `DailyResponsibilityReminders`), and the slots it cycles through.
  static const dailyReminderSlots = 8;

  // The "+3" spare id of the first few entity slots — never used by any
  // task or event (those use +0/+1/+2), so these can't collide.
  int _dailyReminderId(int slot) => slot * 4 + 3;

  /// One day's responsibilities reminder. [slot] is fixed per date, so
  /// planning again replaces rather than duplicates.
  Future<void> scheduleDailyResponsibilityReminder({
    required int slot,
    required String title,
    required String body,
    required DateTime at,
  }) {
    return _schedule(
      id: _dailyReminderId(slot),
      title: title,
      body: body,
      at: at,
      payload: 'responsibilities:today',
    );
  }

  Future<void> cancelDailyResponsibilityReminders() async {
    for (var slot = 0; slot < dailyReminderSlots; slot++) {
      await _cancel(_dailyReminderId(slot));
    }
  }
}
