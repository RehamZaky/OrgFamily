import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/events_table.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// An [Event] plus its [EventMembers] join-table rows, resolved together —
/// see [EventSyncAdapter] for why they travel as one Firestore doc.
class EventWithMembers {
  const EventWithMembers(this.event, this.memberIds);

  final Event event;
  final List<String> memberIds;
}

/// Mirrors [Events] to `families/{familyId}/events/{eventId}` — every
/// field except [Event.attachmentPath] (local-only, same reasoning as
/// [FamilyMember.photoPath]) and the legacy [Event.memberId] column
/// (superseded by [EventMembers], never read by new code). [EventMembers]
/// has no Firestore collection of its own: it's denormalized into a
/// `memberIds` array field on this doc, and reconstituted locally from
/// that array on every remote upsert — see `docs/architecture.md`
/// "Firestore sync".
class EventSyncAdapter implements SyncAdapter<EventWithMembers> {
  EventSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.event;

  @override
  String collectionPath(String familyId) => 'families/$familyId/events';

  @override
  bool get isSingleton => false;

  @override
  DateTime updatedAtOf(EventWithMembers row) => row.event.updatedAt;

  @override
  DateTime? deletedAtOf(EventWithMembers row) => row.event.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(EventWithMembers row) {
    final e = row.event;
    return {
      'title': e.title,
      'description': e.description,
      'startAt': e.startAt,
      'endAt': e.endAt,
      'location': e.location,
      'category': e.category.name,
      'colorValue': e.colorValue,
      'memberIds': row.memberIds,
      'createdAt': e.createdAt,
      'deletedAt': e.deletedAt,
    };
  }

  @override
  Future<EventWithMembers?> getLocalById(String id) async {
    // Deliberately unfiltered by deletedAt — see FamilyMemberSyncAdapter's
    // doc comment on getLocalById for why.
    final event = await (_db.select(_db.events)..where((e) => e.id.equals(id))).getSingleOrNull();
    if (event == null) return null;
    final memberRows =
        await (_db.select(_db.eventMembers)..where((m) => m.eventId.equals(id))).get();
    return EventWithMembers(event, memberRows.map((r) => r.memberId).toList());
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final rows = await _db.select(_db.events).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.transaction(() async {
      await _db.into(_db.events).insertOnConflictUpdate(
            EventsCompanion.insert(
              id: id,
              title: fields['title'] as String,
              description: Value(fields['description'] as String?),
              startAt: toDateOrNull(fields['startAt']) ?? DateTime.now(),
              endAt: Value(toDateOrNull(fields['endAt'])),
              location: Value(fields['location'] as String?),
              category: Value(EventCategory.values.byName(fields['category'] as String)),
              colorValue: Value(fields['colorValue'] as int?),
              createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
              updatedAt: Value(updatedAt),
              deletedAt: Value(toDateOrNull(fields['deletedAt'])),
            ),
          );
      final memberIds = (fields['memberIds'] as List?)?.cast<String>() ?? const <String>[];
      await (_db.delete(_db.eventMembers)..where((m) => m.eventId.equals(id))).go();
      if (memberIds.isNotEmpty) {
        await _db.batch((b) {
          b.insertAll(_db.eventMembers, [
            for (final memberId in memberIds)
              EventMembersCompanion.insert(eventId: id, memberId: memberId),
          ]);
        });
      }
    });
  }
}
