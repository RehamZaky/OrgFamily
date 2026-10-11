import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables/sync_outbox_table.dart';
import '../sync/sync_engine.dart';

/// Activity `type`s V2.1 records. Open strings, not an enum — V3 adds more
/// (e.g. `task.submitted_for_approval`, `device.paired`) without a schema
/// change, and readers skip types they don't recognise.
abstract final class ActivityTypes {
  static const taskCreated = 'task.created';
  static const taskAssigned = 'task.assigned';
  static const taskCompleted = 'task.completed';
  static const eventCreated = 'event.created';
  static const eventChanged = 'event.changed';
  static const eventCancelled = 'event.cancelled';
  static const shoppingItemAdded = 'shopping_item.added';
  static const shoppingItemPurchased = 'shopping_item.purchased';
  static const shoppingItemRemoved = 'shopping_item.removed';
  static const memberJoined = 'member.joined';
  static const responsibilityCompleted = 'responsibility.completed';

  /// Every type this version knows how to show.
  static const known = {
    taskCreated,
    taskAssigned,
    taskCompleted,
    eventCreated,
    eventChanged,
    eventCancelled,
    shoppingItemAdded,
    shoppingItemPurchased,
    shoppingItemRemoved,
    memberJoined,
    responsibilityCompleted,
  };
}

/// Who/what performed an action — see family_activities_table.dart.
abstract final class ActorKinds {
  static const adult = 'adult';
  static const child = 'child'; // V3: written by paired child devices
  static const system = 'system';
}

/// Records family activity. Repositories call [record] from inside the
/// same Drift transaction as the change it describes, so the entry and the
/// change commit together, and the entry's id is fixed right then — a
/// sync retry re-sends the same document rather than duplicating it.
///
/// Deliberately limited to meaningful family actions (tasks, events,
/// shopping, members, responsibilities); never screen views, and never
/// Money — financial activity gets its own permission-gated history.
class ActivityLog {
  ActivityLog(this._sync);

  final SyncEngine _sync;
  static const _uuid = Uuid();

  String? _actorUid;
  String? _actorMemberId;

  /// Kept current by the app (`RootScaffold`): the signed-in account and
  /// the profile it's acting as. The member is "on behalf of" data in
  /// V2.1 — see family_activities_table.dart.
  void setActor({String? uid, String? memberId}) {
    _actorUid = uid;
    _actorMemberId = memberId;
  }

  Future<void> record(
    AppDatabase db, {
    required String type,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
    String actorKind = ActorKinds.adult,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await db
        .into(db.familyActivities)
        .insert(
          FamilyActivitiesCompanion.insert(
            id: id,
            type: type,
            actorKind: Value(actorKind),
            actorUid: Value(_actorUid),
            actorMemberId: Value(actorKind == ActorKinds.system ? null : _actorMemberId),
            entityType: entityType,
            entityId: entityId,
            metadata: Value(jsonEncode(metadata)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _sync.enqueueUpsert(db: db, type: SyncEntityType.activity, entityId: id);
  }
}

/// [ActivityLog.record] for repositories that may have no log (tests, and
/// code paths constructed without one) — a no-op then.
extension ActivityLogX on ActivityLog? {
  Future<void> maybeRecord(
    AppDatabase db, {
    required String type,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) async {
    final log = this;
    if (log == null) return;
    await log.record(
      db,
      type: type,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
  }
}
