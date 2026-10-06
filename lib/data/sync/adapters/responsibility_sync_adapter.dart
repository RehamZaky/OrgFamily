import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/responsibilities_table.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [Responsibilities] (per-member recurring chores) to
/// `families/{familyId}/responsibilities/{id}` — every field, so a chore
/// assigned on one phone and ticked "done today" on another stays the same
/// everywhere. `lastCompletedDate` is the whole completion state (there's
/// no per-day history yet — that's V3), so it's last-write-wins like any
/// other field.
class ResponsibilitySyncAdapter implements SyncAdapter<Responsibility> {
  ResponsibilitySyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.responsibility;

  @override
  String collectionPath(String familyId) => 'families/$familyId/responsibilities';

  @override
  bool get isSingleton => false;

  @override
  DateTime updatedAtOf(Responsibility row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(Responsibility row) => row.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(Responsibility row) {
    return {
      'memberId': row.memberId,
      'title': row.title,
      'recurrence': row.recurrence.name,
      'customWeekdays': row.customWeekdays,
      'lastCompletedDate': row.lastCompletedDate,
      'createdAt': row.createdAt,
      'deletedAt': row.deletedAt,
    };
  }

  @override
  Future<Responsibility?> getLocalById(String id) {
    // Deliberately unfiltered by deletedAt — see FamilyMemberSyncAdapter's
    // doc comment on getLocalById for why.
    return (_db.select(_db.responsibilities)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final rows = await _db.select(_db.responsibilities).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.responsibilities).insertOnConflictUpdate(
          ResponsibilitiesCompanion.insert(
            id: id,
            memberId: fields['memberId'] as String,
            title: fields['title'] as String,
            recurrence: Value(ResponsibilityRecurrence.values.firstWhere(
              (r) => r.name == fields['recurrence'],
              orElse: () => ResponsibilityRecurrence.daily,
            )),
            customWeekdays: Value(fields['customWeekdays'] as String?),
            lastCompletedDate: Value(toDateOrNull(fields['lastCompletedDate'])),
            createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt),
            deletedAt: Value(toDateOrNull(fields['deletedAt'])),
          ),
        );
  }
}
