import 'package:drift/drift.dart';

import '../../core/notifications/notification_service.dart';
import '../local/database.dart';
import '../local/tables/events_table.dart';

class EventRepository {
  EventRepository(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

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

  Future<void> addEvent({
    required String id,
    required String title,
    String? description,
    required DateTime startAt,
    DateTime? endAt,
    String? location,
    EventCategory category = EventCategory.other,
    String? memberId,
  }) async {
    await _db.into(_db.events).insert(
          EventsCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            startAt: startAt,
            endAt: Value(endAt),
            location: Value(location),
            category: Value(category),
            memberId: Value(memberId),
          ),
        );
    await _notifications.scheduleEventReminder(
      eventId: id,
      title: title,
      startAt: startAt,
    );
  }

  Future<void> updateEvent(Event event) async {
    await _db.update(_db.events).replace(event);
    await _notifications.scheduleEventReminder(
      eventId: event.id,
      title: event.title,
      startAt: event.startAt,
    );
  }

  Future<void> deleteEvent(String id) async {
    await (_db.delete(_db.events)..where((e) => e.id.equals(id))).go();
    await _notifications.cancelEventReminder(id);
  }
}
