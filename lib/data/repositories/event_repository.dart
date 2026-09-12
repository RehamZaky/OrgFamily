import 'package:drift/drift.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/events_table.dart';
import '../local/tables/family_members_table.dart';

class EventRepository {
  EventRepository(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  Future<Event?> getById(String id) {
    return (_db.select(_db.events)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  /// Re-schedules every event's reminder from current DB state. Called
  /// after detecting a reboot (see [hasRebootedSinceLastCheck] in
  /// boot_detector.dart) as a correctness backstop on top of the native
  /// BOOT_COMPLETED replay, which replays a snapshot rather than live data.
  Future<void> resyncReminders() async {
    final events = await _db.select(_db.events).get();
    for (final e in events) {
      await _notifications.scheduleEventReminder(
        eventId: e.id,
        title: e.title,
        startAt: e.startAt,
      );
    }
  }

  Stream<List<Event>> watchAll() {
    return (_db.select(_db.events)
          ..orderBy([(e) => OrderingTerm.asc(e.startAt)]))
        .watch();
  }

  Stream<List<Event>> watchUpcoming({int days = 7}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final until = startOfDay.add(Duration(days: days));
    return (_db.select(_db.events)
          ..where((e) =>
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
          ),
        );
    await _setMembers(id, memberIds);
    await _notifications.scheduleEventReminder(
      eventId: id,
      title: title,
      startAt: startAt,
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
    await _db.update(_db.events).replace(event);
    await _setMembers(event.id, memberIds);
    await _notifications.scheduleEventReminder(
      eventId: event.id,
      title: event.title,
      startAt: event.startAt,
    );
  }

  Future<void> deleteEvent(String id, {FamilyRole actingRole = FamilyRole.owner}) async {
    if (!canPerform(actingRole, FamilyAction.manageCalendar)) {
      throw FamilyPermissionException(FamilyAction.manageCalendar, actingRole);
    }
    await (_db.delete(_db.eventMembers)..where((m) => m.eventId.equals(id))).go();
    await (_db.delete(_db.events)..where((e) => e.id.equals(id))).go();
    await _notifications.cancelEventReminder(id);
  }
}
