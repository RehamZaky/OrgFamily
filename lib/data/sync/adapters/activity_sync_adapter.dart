import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, FieldValue, Query, Timestamp;
import 'package:drift/drift.dart' hide Query;

import '../../local/database.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [FamilyActivities] to `families/{familyId}/activities/{id}`.
///
/// `occurredAt` is the authoritative order across devices: a server
/// timestamp assigned on the first upload. Until then it's null locally,
/// so the first push sends a `serverTimestamp()` sentinel; the engine reads
/// the stored document back after pushing, which brings the real server
/// time into the local row, and every later push resends that value — so
/// it's set once and never moves.
///
/// `metadata` is a Firestore map in the cloud and JSON text locally.
///
/// Only the last [syncWindow] is kept in sync (see [WindowedSyncAdapter]);
/// older entries stay in the cloud and on the phones that already have them.
class ActivitySyncAdapter implements SyncAdapter<FamilyActivity>, WindowedSyncAdapter {
  ActivitySyncAdapter(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  static const syncWindow = Duration(days: 30);

  @override
  Query<Map<String, dynamic>> window(CollectionReference<Map<String, dynamic>> collection) {
    return collection.where(
      'occurredAt',
      isGreaterThanOrEqualTo: Timestamp.fromDate(_clock().subtract(syncWindow)),
    );
  }

  @override
  SyncEntityType get entityType => SyncEntityType.activity;

  @override
  String collectionPath(String familyId) => 'families/$familyId/activities';

  @override
  bool get isSingleton => false;

  @override
  DateTime updatedAtOf(FamilyActivity row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(FamilyActivity row) => null;

  @override
  Map<String, dynamic> toFirestoreFields(FamilyActivity row) {
    Object? metadata;
    try {
      metadata = jsonDecode(row.metadata);
    } catch (_) {
      metadata = const <String, Object?>{};
    }
    return {
      'type': row.type,
      'actorKind': row.actorKind,
      'actorUid': row.actorUid,
      'actorMemberId': row.actorMemberId,
      'actorDeviceId': row.actorDeviceId,
      'entityType': row.entityType,
      'entityId': row.entityId,
      'state': row.state,
      'relatedActivityId': row.relatedActivityId,
      'metadata': metadata,
      'schemaVersion': row.schemaVersion,
      'createdAt': row.createdAt,
      'occurredAt': row.occurredAt ?? FieldValue.serverTimestamp(),
    };
  }

  @override
  Future<FamilyActivity?> getLocalById(String id) {
    return (_db.select(_db.familyActivities)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Only the window's: reconciliation compares these against the
  /// windowed remote set, and an older local entry missing from it isn't
  /// "never uploaded" — it's just outside the window.
  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final cutoff = _clock().subtract(syncWindow);
    final rows = await (_db.select(
      _db.familyActivities,
    )..where((a) => a.occurredAt.isBiggerOrEqualValue(cutoff) | a.occurredAt.isNull())).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    final metadata = fields['metadata'];
    return _db
        .into(_db.familyActivities)
        .insertOnConflictUpdate(
          FamilyActivitiesCompanion.insert(
            id: id,
            type: fields['type'] as String? ?? '',
            actorKind: Value(fields['actorKind'] as String? ?? 'adult'),
            actorUid: Value(fields['actorUid'] as String?),
            actorMemberId: Value(fields['actorMemberId'] as String?),
            actorDeviceId: Value(fields['actorDeviceId'] as String?),
            entityType: fields['entityType'] as String? ?? '',
            entityId: fields['entityId'] as String? ?? '',
            state: Value(fields['state'] as String?),
            relatedActivityId: Value(fields['relatedActivityId'] as String?),
            metadata: Value(metadata is Map ? jsonEncode(metadata) : '{}'),
            schemaVersion: Value((fields['schemaVersion'] as num?)?.toInt() ?? 1),
            createdAt: toDateOrNull(fields['createdAt']) ?? updatedAt,
            occurredAt: Value(toDateOrNull(fields['occurredAt'])),
            updatedAt: updatedAt,
          ),
        );
  }
}
