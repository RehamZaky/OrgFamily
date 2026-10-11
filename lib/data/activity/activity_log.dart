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

  /// The one completion entry a task occurrence can have. Each occurrence
  /// of a recurring task is its own task (own id), so each gets its own.
  static String taskCompletionId(String taskId) => '${ActivityTypes.taskCompleted}:$taskId';

  /// The one completion entry a responsibility can have per local day.
  static String responsibilityCompletionId(String responsibilityId, DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = day.toLocal();
    return '${ActivityTypes.responsibilityCompleted}:$responsibilityId:'
        '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// [onceId]: a deterministic id for an action that may only ever be
  /// recorded once (see [taskCompletionId], [responsibilityCompletionId]).
  /// If this phone already has that entry — recorded here, or synced from
  /// another phone — nothing is recorded; untick and re-tick doesn't add a
  /// second. Two phones recording it before either has synced produce the
  /// same document, and the second to upload adopts the first's (see
  /// `SyncEngine._pushOne`).
  ///
  /// An entry of the same [type] about the same entity under another id —
  /// made before ids were deterministic, or by a phone on an older build —
  /// counts as already recorded too: any time for a task, within the local
  /// day [onceDay] for a responsibility.
  Future<void> record(
    AppDatabase db, {
    required String type,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
    String actorKind = ActorKinds.adult,
    String? onceId,
    DateTime? onceDay,
  }) async {
    final now = DateTime.now();
    final id = onceId ?? _uuid.v4();
    if (onceId != null) {
      final a = db.familyActivities;
      final day = onceDay?.toLocal();
      final dayStart = day == null ? null : DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart == null ? null : DateTime(day!.year, day.month, day.day + 1);
      final when = coalesce([a.occurredAt, a.createdAt]);
      final existing =
          await (db.selectOnly(a)
                ..addColumns([a.id])
                ..where(
                  a.id.equals(onceId) |
                      (a.type.equals(type) &
                          a.entityId.equals(entityId) &
                          (dayStart == null
                              ? const Constant(true)
                              : when.isBiggerOrEqualValue(dayStart) &
                                    when.isSmallerThanValue(dayEnd!))),
                )
                ..limit(1))
              .get();
      if (existing.isNotEmpty) return;
    }
    // An adult linked to a different account than the signed-in one (a
    // shared phone with someone else's profile picked) can't be vouched
    // for — firestore.rules would refuse the entry — so it's recorded as
    // "not known". Signed out, it's kept; review fixes it up on upload.
    var memberId = actorKind == ActorKinds.system ? null : _actorMemberId;
    if (memberId != null && _actorUid != null) {
      final mid = memberId;
      final member = await (db.select(
        db.familyMembers,
      )..where((m) => m.id.equals(mid))).getSingleOrNull();
      final linked = member?.linkedUid;
      if (linked != null && linked != _actorUid) memberId = null;
    }
    await db
        .into(db.familyActivities)
        .insert(
          FamilyActivitiesCompanion.insert(
            id: id,
            type: type,
            actorKind: Value(actorKind),
            actorUid: Value(_actorUid),
            actorMemberId: Value(memberId),
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
    String? onceId,
    DateTime? onceDay,
  }) async {
    final log = this;
    if (log == null) return;
    await log.record(
      db,
      type: type,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
      onceId: onceId,
      onceDay: onceDay,
    );
  }
}
