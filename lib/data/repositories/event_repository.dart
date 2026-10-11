import 'package:drift/drift.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/events_table.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/sync_outbox_table.dart';
import '../activity/activity_log.dart';
import '../sync/sync_engine.dart';

class EventRepository {
  EventRepository(
    this._db,
    this._notifications,
    this._sync, {
    ActivityLog? activity,
    int? Function()? eventReminderMinutes,
  }) : _activity = activity,
       _eventReminderMinutes = eventReminderMinutes ?? (() => 15);

  final AppDatabase _db;
  final NotificationService _notifications;
  final SyncEngine _sync;
  final ActivityLog? _activity;

  /// This phone's "event reminder" setting for whoever is using it — minutes
  /// before the start, or null for none. Read at scheduling time, so a
  /// change applies from the next (re)schedule; [resyncReminders] applies
  /// it to every event at once. Only this phone's local notifications are
  /// affected — the shared event records never change.
  final int? Function() _eventReminderMinutes;

  Future<Event?> getById(String id) {
    return (_db.select(_db.events)..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Re-schedules every event's reminder from current DB state. Called
  /// after detecting a reboot (see [hasRebootedSinceLastCheck] in
  /// boot_detector.dart) as a correctness backstop on top of the native
  /// BOOT_COMPLETED replay, which replays a snapshot rather than live data.
  Future<void> resyncReminders() async {
    final events = await (_db.select(_db.events)..where((e) => e.deletedAt.isNull())).get();
    for (final e in events) {
      await _notifications.scheduleEventReminder(
        eventId: e.id,
        title: e.title,
        startAt: e.startAt,
        minutesBefore: _eventReminderMinutes(),
      );
    }
  }

  Stream<List<Event>> watchAll() {
    return (_db.select(_db.events)
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.startAt)]))
        .watch();
  }

  Stream<List<Event>> watchUpcoming({int days = 7}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final until = startOfDay.add(Duration(days: days));
    return (_db.select(_db.events)
          ..where((e) =>
              e.deletedAt.isNull() &
              e.startAt.isBiggerOrEqualValue(startOfDay) &
              e.startAt.isSmallerThanValue(until))
          ..orderBy([(e) => OrderingTerm.asc(e.startAt)]))
        .watch();
  }

  /// Who's attached to [eventId] — empty means unassigned, one means a
  /// single-person event, two or more a shared/family event.
  Stream<List<String>> watchMembersForEvent(String eventId) {
    return (_db.select(_db.eventMembers)..where((m) => m.eventId.equals(eventId)))
        .watch()
        .map((rows) => rows.map((r) => r.memberId).toList());
  }

  /// Every event's member ids at once, keyed by event id — for screens that
  /// need to filter/bucket a whole list of events by assignee without
  /// subscribing to one stream per event.
  Stream<Map<String, List<String>>> watchAllEventMembers() {
    return _db.select(_db.eventMembers).watch().map((rows) {
      final map = <String, List<String>>{};
      for (final r in rows) {
        map.putIfAbsent(r.eventId, () => []).add(r.memberId);
      }
      return map;
    });
  }

  Future<void> _setMembers(String eventId, List<String> memberIds) async {
    await (_db.delete(_db.eventMembers)..where((m) => m.eventId.equals(eventId))).go();
    if (memberIds.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.eventMembers, [
        for (final memberId in memberIds)
          EventMembersCompanion.insert(eventId: eventId, memberId: memberId),
      ]);
    });
  }

  Future<void> addEvent({
    required String id,
    required String title,
    String? description,
    required DateTime startAt,
    DateTime? endAt,
    String? location,
    EventCategory category = EventCategory.other,
    List<String> memberIds = const [],
    int? colorValue,
    String? attachmentPath,
    FamilyRole actingRole = FamilyRole.owner,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageCalendar)) {
      throw FamilyPermissionException(FamilyAction.manageCalendar, actingRole);
    }
    await _db.transaction(() async {
      await _db.into(_db.events).insert(
            EventsCompanion.insert(
              id: id,
              title: title,
              description: Value(description),
              startAt: startAt,
              endAt: Value(endAt),
              location: Value(location),
              category: Value(category),
              colorValue: Value(colorValue),
              attachmentPath: Value(attachmentPath),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _setMembers(id, memberIds);
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.event, entityId: id);
      await _activity.maybeRecord(_db,
          type: ActivityTypes.eventCreated,
          entityType: SyncEntityType.event.name,
          entityId: id,
          metadata: {'title': title, 'startAt': startAt.toIso8601String()});
    });
    await _notifications.scheduleEventReminder(
      eventId: id,
      title: title,
      startAt: startAt,
      minutesBefore: _eventReminderMinutes(),
    );
  }

  Future<void> updateEvent(
    Event event, {
    List<String> memberIds = const [],
    FamilyRole actingRole = FamilyRole.owner,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageCalendar)) {
      throw FamilyPermissionException(FamilyAction.manageCalendar, actingRole);
    }
    await _db.transaction(() async {
      await _db.update(_db.events).replace(event.copyWith(updatedAt: DateTime.now()));
      await _setMembers(event.id, memberIds);
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.event, entityId: event.id);
      await _activity.maybeRecord(_db,
          type: ActivityTypes.eventChanged,
          entityType: SyncEntityType.event.name,
          entityId: event.id,
          metadata: {'title': event.title, 'startAt': event.startAt.toIso8601String()});
    });
    await _notifications.scheduleEventReminder(
      eventId: event.id,
      title: event.title,
      startAt: event.startAt,
      minutesBefore: _eventReminderMinutes(),
    );
  }

  Future<void> deleteEvent(String id, {FamilyRole actingRole = FamilyRole.owner}) async {
    if (!canPerform(actingRole, FamilyAction.manageCalendar)) {
      throw FamilyPermissionException(FamilyAction.manageCalendar, actingRole);
    }
    // Soft-delete the event itself (see tasks_table.dart's deletedAt doc
    // comment) so the tombstone can propagate through Firestore sync;
    // eventMembers has no sync identity of its own (denormalized into the
    // event's memberIds on push) so clearing it outright here is fine —
    // note this also means the pushed tombstone's memberIds comes back
    // empty, which is fine since a deleted event's members don't matter.
    final now = DateTime.now();
    final event = await getById(id);
    await _db.transaction(() async {
      await (_db.delete(_db.eventMembers)..where((m) => m.eventId.equals(id))).go();
      await (_db.update(_db.events)..where((e) => e.id.equals(id)))
          .write(EventsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.event, entityId: id);
      if (event != null) {
        await _activity.maybeRecord(_db,
            type: ActivityTypes.eventCancelled,
            entityType: SyncEntityType.event.name,
            entityId: id,
            metadata: {'title': event.title, 'startAt': event.startAt.toIso8601String()});
      }
    });
    await _notifications.cancelEventReminder(id);
  }
}
