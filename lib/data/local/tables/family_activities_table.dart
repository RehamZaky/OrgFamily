import 'package:drift/drift.dart';

/// The family activity log (V2.1, docs/roadmap.md "Family Activity") — one
/// row per meaningful family action ("Mariam completed Feed the cat").
/// Synced to `families/{familyId}/activities/{id}`.
///
/// **Designed so V3 (child devices, approvals, rewards) needs no schema
/// change** — everything V3 adds fits in what's already here:
/// - [type] and [entityType] are open strings (`task.completed`,
///   later `task.submitted_for_approval`, `device.paired`,
///   `reward.redeemed`…), never enum indexes. Readers skip types they don't
///   know instead of failing, so older app versions keep working.
/// - Actor: [actorKind] (`adult` | `child` | `system`), [actorUid],
///   [actorMemberId], [actorDeviceId]. V2.1 only writes `adult`/`system`
///   and no device; V3 child devices fill in the rest.
/// - Lifecycle: nullable [state] (`pending` → `approved`/`rejected`) and
///   [relatedActivityId], so an approval links to the action it approves.
/// - Everything type-specific lives in [metadata] (JSON), versioned per row
///   by [schemaVersion].
///
/// [actorMemberId] is "on behalf of" data in V2.1: children have no
/// accounts yet, so on a shared phone it's whichever profile was acting.
/// Only [actorUid] is verified (by firestore.rules).
class FamilyActivities extends Table {
  /// Fixed when the action happens (in the same transaction as the change
  /// it records), so a sync retry re-sends the same document instead of
  /// creating a duplicate.
  TextColumn get id => text()();

  TextColumn get type => text()();
  TextColumn get actorKind => text().withDefault(const Constant('adult'))();
  TextColumn get actorUid => text().nullable()();
  TextColumn get actorMemberId => text().nullable()();
  TextColumn get actorDeviceId => text().nullable()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get state => text().nullable()();
  TextColumn get relatedActivityId => text().nullable()();

  /// Type-specific details as a JSON object — e.g. the task's title at
  /// the time, so the entry still reads right after the task is renamed
  /// or deleted.
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  /// This device's clock when the action happened — shown until the
  /// server's [occurredAt] arrives.
  DateTimeColumn get createdAt => dateTime()();

  /// Firestore's server time for the action, assigned on first upload —
  /// the authoritative order across devices (device clocks can be wrong).
  /// Null until synced.
  DateTimeColumn get occurredAt => dateTime().nullable()();

  /// Sync bookkeeping, as on every synced table.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
