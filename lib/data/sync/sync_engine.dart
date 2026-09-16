import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables/sync_outbox_table.dart';
import 'outbox_failure_policy.dart';
import 'sync_adapter.dart';

/// Drives Firestore sync for every registered [SyncAdapter] — see
/// `docs/architecture.md` "Firestore sync" for the full design this
/// implements: outbox-backed durable push, tombstone-aware last-write-wins
/// pull, and pending-write-aware merging.
///
/// Injected into repositories the same way `NotificationService` already
/// is — always non-null, internally a no-op whenever sync isn't active
/// (no family linked yet, or this platform doesn't support Firebase at
/// all), so call sites never need to null-check it.
class SyncEngine {
  SyncEngine(this._db, FirebaseFirestore firestore, List<SyncAdapter> adapters)
      : _firestore = firestore,
        _adapters = {for (final a in adapters) a.entityType: a};

  /// A permanently-inert engine — every method is a no-op. For a platform
  /// that never calls `Firebase.initializeApp` at all (desktop, see
  /// `lib/core/auth/auth_config.dart`'s `isFirebaseAuthSupportedPlatform`),
  /// so repositories can still take a non-null `SyncEngine` unconditionally
  /// without ever touching `FirebaseFirestore.instance` there.
  SyncEngine.inert(this._db)
      : _firestore = null,
        _adapters = const {};

  final AppDatabase _db;
  final FirebaseFirestore? _firestore;
  final Map<SyncEntityType, SyncAdapter> _adapters;
  final List<StreamSubscription> _subscriptions = [];
  String? _activeFamilyId;

  String? get activeFamilyId => _activeFamilyId;

  /// Begins syncing against [familyId]: runs the initial reconciliation
  /// pass if needed, drains the outbox, and only then attaches a live
  /// listener per registered adapter — deliberately in that order, not
  /// listeners-first, since a listener attached before this device's
  /// membership exists remotely (i.e. before the family doc itself has
  /// been pushed) gets permanently denied by Firestore's security rules
  /// rather than just waiting. Idempotent — calling again with the same
  /// [familyId] is a no-op; a different one restarts against it.
  ///
  /// May be called from inside a Drift transaction (`recordLink` does
  /// exactly that) — the async work is dispatched via `Zone.root.run` so
  /// it runs detached from that transaction's zone, since Drift routes
  /// `_db`'s queries to the transaction's own executor for anything
  /// launched inside its zone, even unawaited, and that executor is
  /// invalid the moment the transaction itself closes.
  void start(String familyId) {
    if (_firestore == null) return;
    if (_activeFamilyId == familyId) return;
    stop();
    _activeFamilyId = familyId;
    Zone.root.run(() => unawaited(_activateSync(familyId)));
  }

  Future<void> _activateSync(String familyId) async {
    await _runInitialReconciliationIfNeeded(familyId);
    await drainNow();
    // A stop()/different start() may have run while the above awaited —
    // don't attach listeners for a family that's no longer the active one.
    if (_activeFamilyId != familyId) return;
    for (final adapter in _adapters.values) {
      _listen(adapter, familyId);
    }
  }

  /// Detaches every listener and stops draining. Does not touch the
  /// outbox — queued rows stay put and resume once [start] is called again
  /// for the same family (see the "pause on sign-out" behavior in the
  /// Firestore sync plan).
  void stop() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    _activeFamilyId = null;
  }

  void _listen(SyncAdapter adapter, String familyId) {
    // Only ever called from start(), which already checked _firestore != null.
    if (adapter.isSingleton) {
      final sub = _firestore!
          .collection(adapter.collectionPath(familyId))
          .doc(familyId)
          .snapshots()
          .listen((doc) async {
        if (doc.metadata.hasPendingWrites) return;
        final data = doc.data();
        if (data == null) return;
        await _mergeIncoming(adapter, familyId, data);
      });
      _subscriptions.add(sub);
      return;
    }
    final sub = _firestore!
        .collection(adapter.collectionPath(familyId))
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        // Our own optimistic write echoing back — the eventual
        // server-timestamp round-trip in _pushOne is the authoritative
        // comparison for this entity, not this (possibly racing) snapshot.
        if (change.doc.metadata.hasPendingWrites) continue;
        final data = change.doc.data();
        if (data == null) continue;
        await _mergeIncoming(adapter, change.doc.id, data);
      }
    });
    _subscriptions.add(sub);
  }

  Future<void> _mergeIncoming(SyncAdapter adapter, String id, Map<String, dynamic> data) async {
    final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    // Still resolving its server timestamp — the listener fires again once
    // the write is acknowledged, with a real value.
    if (remoteUpdatedAt == null) return;
    if (await _hasPendingLocalWrite(adapter.entityType, id)) return;
    final local = await adapter.getLocalById(id);
    if (local == null || remoteUpdatedAt.isAfter(adapter.updatedAtOf(local))) {
      await adapter.applyRemoteUpsert(id, data, remoteUpdatedAt);
    }
  }

  /// The one-time V1-data upload/download pass — see the Firestore sync
  /// plan's "One shared merge function" section for why this only ever
  /// runs once per family-link, gated by
  /// `FamilyProfile.initialCloudMigrationCompletedAt`, and why after that
  /// flag is set, "missing remotely" is never again treated as "needs
  /// uploading" (that's what stops a deleted row from resurrecting on a
  /// later reconnect). Only marks the flag once every adapter has
  /// succeeded — a failure partway through (e.g. offline mid-pass) leaves
  /// it unset so the next [start] retries the whole thing, rather than
  /// silently skipping whatever didn't finish.
  Future<void> _runInitialReconciliationIfNeeded(String familyId) async {
    if (_firestore == null) return;
    final profile =
        await (_db.select(_db.familyProfile)..where((p) => p.id.equals(1))).getSingleOrNull();
    if (profile?.initialCloudMigrationCompletedAt != null) return;
    try {
      for (final adapter in _adapters.values) {
        await _reconcileAdapterFully(adapter, familyId);
      }
      await _db.into(_db.familyProfile).insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(1),
              initialCloudMigrationCompletedAt: Value(DateTime.now()),
            ),
          );
    } catch (_) {
      // Leave the flag unset — retried the next time start() runs.
    }
  }

  Future<void> _reconcileAdapterFully(SyncAdapter adapter, String familyId) async {
    if (adapter.isSingleton) {
      await _reconcileSingleton(adapter, familyId);
      return;
    }
    final localIds = await adapter.allLocalIds(familyId);
    final remoteSnap = await _firestore!.collection(adapter.collectionPath(familyId)).get();
    final remoteDocs = {for (final d in remoteSnap.docs) d.id: d.data()};

    for (final id in localIds) {
      final remote = remoteDocs.remove(id);
      if (remote == null) {
        // Genuinely never uploaded (this only runs pre-flag) — push it.
        final local = await adapter.getLocalById(id);
        if (local == null) continue;
        final data = Map<String, dynamic>.from(adapter.toFirestoreFields(local));
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection(adapter.collectionPath(familyId)).doc(id).set(data);
        continue;
      }
      final remoteUpdatedAt = (remote['updatedAt'] as Timestamp?)?.toDate();
      if (remoteUpdatedAt == null) continue;
      final local = await adapter.getLocalById(id);
      if (local == null || remoteUpdatedAt.isAfter(adapter.updatedAtOf(local))) {
        await adapter.applyRemoteUpsert(id, remote, remoteUpdatedAt);
      }
    }
    // Whatever's left has no local counterpart — pull it.
    for (final entry in remoteDocs.entries) {
      final remoteUpdatedAt = (entry.value['updatedAt'] as Timestamp?)?.toDate();
      if (remoteUpdatedAt == null) continue;
      await adapter.applyRemoteUpsert(entry.key, entry.value, remoteUpdatedAt);
    }
  }

  /// [_reconcileAdapterFully]'s counterpart for a singleton — a direct
  /// `.doc()` get instead of an unconstrained collection query, for the
  /// same reason [SyncAdapter.isSingleton]'s doc comment explains.
  Future<void> _reconcileSingleton(SyncAdapter adapter, String familyId) async {
    final docRef = _firestore!.collection(adapter.collectionPath(familyId)).doc(familyId);
    final remote = (await docRef.get()).data();
    if (remote == null) {
      final local = await adapter.getLocalById(familyId);
      if (local == null) return;
      final data = Map<String, dynamic>.from(adapter.toFirestoreFields(local));
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);
      return;
    }
    final remoteUpdatedAt = (remote['updatedAt'] as Timestamp?)?.toDate();
    if (remoteUpdatedAt == null) return;
    final local = await adapter.getLocalById(familyId);
    if (local == null || remoteUpdatedAt.isAfter(adapter.updatedAtOf(local))) {
      await adapter.applyRemoteUpsert(familyId, remote, remoteUpdatedAt);
    }
  }

  Future<bool> _hasPendingLocalWrite(SyncEntityType type, String entityId) async {
    final rows = await (_db.select(_db.syncOutbox)
          ..where((o) =>
              o.entityType.equalsValue(type) &
              o.entityId.equals(entityId) &
              (o.status.equalsValue(SyncOutboxStatus.pending) |
                  o.status.equalsValue(SyncOutboxStatus.retrying)))
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  /// Queues [entityId] to be pushed — call from inside the same
  /// `AppDatabase.transaction()` block as the entity write it describes,
  /// so the two commit atomically (see the Firestore sync plan's
  /// "Durability" section for why). A no-op if sync isn't active yet
  /// (nothing local has a family to push to).
  ///
  /// The follow-up drain is dispatched via `Zone.root.run`, the same
  /// escape [start] uses and for the same reason — this is always called
  /// from inside the caller's transaction, and an unawaited continuation
  /// launched inside that zone would otherwise try to keep using the
  /// transaction's executor after Drift has already closed it.
  Future<void> enqueueUpsert({
    required AppDatabase db,
    required SyncEntityType type,
    required String entityId,
  }) async {
    final familyId = _activeFamilyId;
    if (familyId == null) return;
    await db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            familyId: familyId,
            entityType: type,
            entityId: entityId,
            operation: SyncOperation.upsert,
          ),
        );
    Zone.root.run(() => unawaited(drainNow()));
  }

  /// The manual "Retry" action for the Settings sync status row: `failed`
  /// rows are deliberately excluded from [drainNow]'s automatic sweep (see
  /// "Outbox failure policy" in the Firestore sync plan — they're not
  /// retried forever), so a user-initiated retry has to explicitly put
  /// them back in the running by resetting their status before draining.
  Future<void> retryFailed() async {
    final familyId = _activeFamilyId;
    if (familyId == null) return;
    await (_db.update(_db.syncOutbox)
          ..where((o) =>
              o.familyId.equals(familyId) & o.status.equalsValue(SyncOutboxStatus.failed)))
        .write(const SyncOutboxCompanion(
      status: Value(SyncOutboxStatus.pending),
      attemptCount: Value(0),
      nextRetryAt: Value(null),
    ));
    await drainNow();
  }

  /// Attempts to push every due outbox row for the active family — call on
  /// boot, on reconnect, and (via [enqueueUpsert]) right after a write, for
  /// the common fast path. Safe to call anytime; a no-op if sync isn't
  /// active or nothing is due yet.
  Future<void> drainNow() async {
    final familyId = _activeFamilyId;
    if (familyId == null) return;
    final now = DateTime.now();
    final rows = await (_db.select(_db.syncOutbox)
          ..where((o) =>
              o.familyId.equals(familyId) &
              o.status.equalsValue(SyncOutboxStatus.failed).not() &
              (o.nextRetryAt.isNull() | o.nextRetryAt.isSmallerOrEqualValue(now))))
        .get();
    for (final row in rows) {
      await _pushOne(row);
    }
  }

  Future<void> _pushOne(SyncOutboxData row) async {
    final adapter = _adapters[row.entityType];
    if (adapter == null) {
      await _removeOutboxRow(row.id);
      return;
    }
    try {
      final local = await adapter.getLocalById(row.entityId);
      if (local == null) {
        // Nothing to push anymore (shouldn't normally happen — deletes are
        // soft — but never block the queue on it).
        await _removeOutboxRow(row.id);
        return;
      }
      final data = Map<String, dynamic>.from(adapter.toFirestoreFields(local));
      data['updatedAt'] = FieldValue.serverTimestamp();
      // Only ever reached via drainNow(), which only ever runs once
      // _activeFamilyId is set — which start() only does after confirming
      // _firestore != null.
      final docRef = _firestore!.collection(adapter.collectionPath(row.familyId)).doc(row.entityId);
      await docRef.set(data);
      final snap = await docRef.get();
      final resolved = snap.data();
      final resolvedUpdatedAt = (resolved?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      // Reconcile the local row's updatedAt to the server-assigned instant
      // (see the plan's "Conflict timestamps" section) via the same code
      // path a genuine remote change would use.
      await adapter.applyRemoteUpsert(row.entityId, resolved ?? data, resolvedUpdatedAt);
      await _removeOutboxRow(row.id);
    } catch (e) {
      await _recordFailure(row, e);
    }
  }

  Future<void> _removeOutboxRow(int id) =>
      (_db.delete(_db.syncOutbox)..where((o) => o.id.equals(id))).go();

  Future<void> _recordFailure(SyncOutboxData row, Object error) async {
    final kind = classifyOutboxFailure(error);
    final code = error is FirebaseException ? error.code : 'unknown';
    final attempt = row.attemptCount + 1;
    final now = DateTime.now();
    // Permanent, or an unclassified error that's failed enough times in a
    // row to stop assuming it'll resolve itself — surfaced to the user
    // rather than retried forever (see the plan's "Outbox failure policy").
    if (kind == FailureKind.permanent ||
        (kind == FailureKind.unknown && attempt >= unknownFailureRetryLimit)) {
      await (_db.update(_db.syncOutbox)..where((o) => o.id.equals(row.id))).write(
        SyncOutboxCompanion(
          status: const Value(SyncOutboxStatus.failed),
          attemptCount: Value(attempt),
          lastErrorCode: Value(code),
          lastErrorMessage: Value(error.toString()),
          lastAttemptAt: Value(now),
        ),
      );
      return;
    }
    await (_db.update(_db.syncOutbox)..where((o) => o.id.equals(row.id))).write(
      SyncOutboxCompanion(
        status: const Value(SyncOutboxStatus.retrying),
        attemptCount: Value(attempt),
        nextRetryAt: Value(now.add(backoffForAttempt(row.attemptCount))),
        lastErrorCode: Value(code),
        lastErrorMessage: Value(error.toString()),
        lastAttemptAt: Value(now),
      ),
    );
  }
}
