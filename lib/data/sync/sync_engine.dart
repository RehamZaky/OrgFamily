import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables/sync_outbox_table.dart';
import 'sync_adapter.dart';

enum _FailureKind { transient, permanent, unknown }

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
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];
  String? _activeFamilyId;

  String? get activeFamilyId => _activeFamilyId;

  /// Begins syncing against [familyId]: attaches a live listener per
  /// registered adapter's collection and starts draining any queued
  /// outbox rows for that family. Idempotent — calling again with the same
  /// [familyId] is a no-op; a different one restarts listeners against it.
  void start(String familyId) {
    if (_firestore == null) return;
    if (_activeFamilyId == familyId) return;
    stop();
    _activeFamilyId = familyId;
    for (final adapter in _adapters.values) {
      _listen(adapter, familyId);
    }
    unawaited(drainNow());
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
    unawaited(drainNow());
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
    final kind = _classify(error);
    final code = error is FirebaseException ? error.code : 'unknown';
    final attempt = row.attemptCount + 1;
    final now = DateTime.now();
    // Permanent, or an unclassified error that's failed enough times in a
    // row to stop assuming it'll resolve itself — surfaced to the user
    // rather than retried forever (see the plan's "Outbox failure policy").
    if (kind == _FailureKind.permanent || (kind == _FailureKind.unknown && attempt >= 3)) {
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
        nextRetryAt: Value(now.add(_backoffFor(row.attemptCount))),
        lastErrorCode: Value(code),
        lastErrorMessage: Value(error.toString()),
        lastAttemptAt: Value(now),
      ),
    );
  }

  _FailureKind _classify(Object error) {
    if (error is! FirebaseException) return _FailureKind.unknown;
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'resource-exhausted':
      case 'aborted':
      case 'internal':
      case 'cancelled':
        return _FailureKind.transient;
      case 'permission-denied':
      case 'invalid-argument':
      case 'not-found':
      case 'already-exists':
      case 'unauthenticated':
      case 'failed-precondition':
        return _FailureKind.permanent;
      default:
        return _FailureKind.unknown;
    }
  }

  /// ~5s → 15s → 1m → 5m → 15m → 30m → capped at 1h, plus up to 1s of
  /// jitter so multiple pending rows don't all retry in lockstep.
  Duration _backoffFor(int attemptCount) {
    const stepsSeconds = [5, 15, 60, 300, 900, 1800, 3600];
    final seconds = stepsSeconds[attemptCount.clamp(0, stepsSeconds.length - 1)];
    return Duration(seconds: seconds, milliseconds: Random().nextInt(1000));
  }
}
