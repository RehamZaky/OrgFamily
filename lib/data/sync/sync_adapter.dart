import '../local/tables/sync_outbox_table.dart';

/// Bridges one synced Drift table to its Firestore collection — one
/// implementation per [SyncEntityType]. See `docs/architecture.md`
/// "Firestore sync" for the design this implements.
abstract class SyncAdapter<T> {
  SyncEntityType get entityType;

  /// Firestore collection path for this entity under the given family,
  /// e.g. `families/$familyId/tasks`.
  String collectionPath(String familyId);

  /// True only for [FamilyProfileSyncAdapter]. Firestore's security rules
  /// can evaluate a rule against one specific, known document's own data
  /// (a `get`) — but not against an unconstrained collection *query*
  /// whose rule depends on each result's own data (a `list`): it can't
  /// prove the rule holds for every document that collection could ever
  /// contain, and denies the whole query outright. A singleton is
  /// therefore always addressed via `.doc()`, never
  /// `.collection().get()/.snapshots()`, even though [collectionPath]
  /// still names its parent collection.
  bool get isSingleton => false;

  DateTime updatedAtOf(T row);
  DateTime? deletedAtOf(T row);

  /// Explicit named fields only — never a blind mirror of the Drift row.
  /// The engine adds `updatedAt` itself (as a server timestamp); adapters
  /// must not include it here.
  Map<String, dynamic> toFirestoreFields(T row);

  Future<T?> getLocalById(String id);

  /// Every local row's id for this entity, unfiltered by `deletedAt` (a
  /// tombstone still needs to be reconciled) — used only by the one-time
  /// initial reconciliation pass (see `docs/architecture.md` "Firestore
  /// sync") to diff the full local set against the full remote set.
  /// [familyId] is only meaningful for the [FamilyProfileSyncAdapter]
  /// singleton, which has no local id of its own to enumerate.
  Future<List<String>> allLocalIds(String familyId);

  /// Upserts [fields] (as read back from Firestore, `updatedAt` already
  /// resolved to [updatedAt]) into Drift — used both for a genuine remote
  /// change and to reconcile the local row after this device's own push
  /// resolves its server timestamp.
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt);
}
