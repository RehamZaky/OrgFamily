import 'package:drift/drift.dart';

/// The kind of local row a [SyncOutbox] entry points at — one per Firestore
/// sync adapter (see `docs/architecture.md` "Firestore sync").
enum SyncEntityType {
  familyProfile,
  familyMember,
  task,
  event,
  shoppingList,
  shoppingItem,
}

enum SyncOperation { upsert, delete }

enum SyncOutboxStatus { pending, retrying, failed }

/// A durable record of "this local write still needs to reach Firestore,"
/// written in the same Drift transaction as the entity change it describes
/// — see `docs/architecture.md` "Firestore sync" for why: Firestore's own
/// offline persistence can only queue a write it has already been handed,
/// which doesn't cover the app process dying between the local commit and
/// that handoff. `SyncEngine` drains this table; a row is removed once its
/// Firestore write is confirmed, or kept with `status = failed` (plus the
/// `lastError*` fields) if the failure is permanent rather than transient.
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Which family's queue this entry belongs to — draining must never cross
  /// families (e.g. after switching the signed-in account).
  TextColumn get familyId => text()();
  IntColumn get entityType => intEnum<SyncEntityType>()();
  TextColumn get entityId => text()();
  IntColumn get operation => intEnum<SyncOperation>()();
  IntColumn get status =>
      intEnum<SyncOutboxStatus>().withDefault(const Constant(0))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
