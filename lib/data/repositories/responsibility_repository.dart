import 'package:drift/drift.dart';

import '../../core/permissions/family_permissions.dart';
import '../../features/family/responsibility_schedule.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/responsibilities_table.dart';
import '../local/tables/sync_outbox_table.dart';
import '../activity/activity_log.dart';
import '../sync/sync_engine.dart';

/// Per-member recurring chores. Deliberately separate from tasks (see
/// docs/roadmap.md "Responsibilities"): no due time, reminders or overdue —
/// just whether it's done today. Synced like tasks: every write stamps
/// `updatedAt` and queues an outbox row in the same transaction, and
/// deletion is a soft-delete tombstone.
///
/// Permissions are enforced here, the single authority for gated mutations
/// (see family_permissions.dart): managing chores is Owner/Adult only, and a
/// Child may tick only their own.
class ResponsibilityRepository {
  ResponsibilityRepository(
    this._db,
    this._sync, {
    ActivityLog? activity,
    DateTime Function()? clock,
  }) : _activity = activity,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final SyncEngine _sync;
  final ActivityLog? _activity;
  final DateTime Function() _clock;

  Stream<List<Responsibility>> watchForMember(String memberId) {
    return (_db.select(_db.responsibilities)
          ..where((r) => r.memberId.equals(memberId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .watch();
  }

  Future<void> addResponsibility({
    required String id,
    required String memberId,
    required String title,
    required ResponsibilityRecurrence recurrence,
    List<int>? customWeekdays,
    FamilyRole actingRole = FamilyRole.owner,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageResponsibilities)) {
      throw FamilyPermissionException(FamilyAction.manageResponsibilities, actingRole);
    }
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.responsibilities).insert(
            ResponsibilitiesCompanion.insert(
              id: id,
              memberId: memberId,
              title: title,
              recurrence: Value(recurrence),
              customWeekdays: Value(customWeekdays?.join(',')),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.responsibility, entityId: id);
    });
  }

  /// Ticks or unticks "done today". A responsibility assigned to
  /// [actingMemberId] needs only [FamilyAction.completeOwnResponsibility]
  /// (which a Child has); anyone else's needs
  /// [FamilyAction.completeAnyResponsibility].
  Future<void> setCompletedToday(
    String id,
    bool completed, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    final row = await (_db.select(_db.responsibilities)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final action = row.memberId == actingMemberId
        ? FamilyAction.completeOwnResponsibility
        : FamilyAction.completeAnyResponsibility;
    if (!canPerform(actingRole, action)) {
      throw FamilyPermissionException(action, actingRole);
    }
    final now = _clock();
    await _db.transaction(() async {
      await (_db.update(_db.responsibilities)..where((r) => r.id.equals(id))).write(
        ResponsibilitiesCompanion(
          lastCompletedDate: Value(completed ? now : null),
          updatedAt: Value(now),
        ),
      );
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.responsibility, entityId: id);
      if (completed && !isDoneOn(row, now)) {
        await _activity.maybeRecord(_db,
            type: ActivityTypes.responsibilityCompleted,
            entityType: SyncEntityType.responsibility.name,
            entityId: id,
            metadata: {'title': row.title, 'memberId': row.memberId},
            onceId: ActivityLog.responsibilityCompletionId(id, now),
            onceDay: now);
      }
    });
  }

  Future<void> deleteResponsibility(
    String id, {
    FamilyRole actingRole = FamilyRole.owner,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageResponsibilities)) {
      throw FamilyPermissionException(FamilyAction.manageResponsibilities, actingRole);
    }
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.responsibilities)..where((r) => r.id.equals(id)))
          .write(ResponsibilitiesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.responsibility, entityId: id);
    });
  }
}
