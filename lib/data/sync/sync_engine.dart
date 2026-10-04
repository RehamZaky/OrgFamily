import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Expression;
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

  /// The verified member uid sync is running as — set by [start] together
  /// with [_activeFamilyId]. Only outbox rows this uid made drain on their
  /// own.
  String? _activeUid;

  /// Whoever is signed in right now, syncing or not — recorded as the
  /// origin of changes queued while sync is off. See [setSignedInUid].
  String? _signedInUid;

  Timer? _listenerRetryTimer;
  int _listenerRetryAttempt = 0;
  final _accessDenied = StreamController<void>.broadcast();

  // Reentrancy guard for [drainNow] — see its doc comment for why a plain
  // "already running, do nothing" early-return isn't safe here.
  bool _draining = false;
  bool _drainRequestedAgain = false;

  final _listenerErrorChanges = StreamController<String?>.broadcast();
  String? _listenerError;

  String? get activeFamilyId => _activeFamilyId;
  String? get activeUid => _activeUid;

  /// Fires whenever Firestore answers `permission-denied` to a listener or
  /// a push — the signal for the app to re-check this account's family
  /// membership (it may have been revoked) rather than keep trying.
  Stream<void> get accessDenied => _accessDenied.stream;

  /// Kept current by the app on every auth change, so changes made while
  /// sync is off still record who made them.
  void setSignedInUid(String? uid) => _signedInUid = uid;

  /// The error code (e.g. `permission-denied`) that stopped a live
  /// listener for the active family, or null while all are healthy.
  /// Firestore ends a listener's stream after an error, so this stays set
  /// until the next [start]/[stop] rather than clearing on its own.
  String? get listenerError => _listenerError;

  /// Emits whenever [listenerError] changes — for Settings' sync status.
  Stream<String?> get listenerErrorChanges => _listenerErrorChanges.stream;

  void _setListenerError(String? code) {
    if (_listenerError == code) return;
    _listenerError = code;
    _listenerErrorChanges.add(code);
  }

  /// A listener's `onError` — without one, every denied or failed
  /// listener surfaces as an unhandled async exception instead of a sync
  /// status the user can see.
  ///
  /// Firestore ends a listener's stream after an error, so this also tears
  /// the remaining listeners down and schedules all of them to reattach
  /// with backoff — a denial or transient fault must not leave live
  /// updates permanently stopped. (Plain connectivity loss never lands
  /// here: Firestore keeps listeners alive offline and resumes them
  /// itself.) A `permission-denied` additionally fires [accessDenied] so
  /// membership is re-verified; if it really was revoked, the app stops
  /// sync altogether and the pending retry is cancelled by [stop].
  void _onListenerError(Object error) {
    final code = error is FirebaseException ? error.code : 'unknown';
    _setListenerError(code);
    if (code == 'permission-denied') _accessDenied.add(null);
    final familyId = _activeFamilyId;
    if (familyId == null || _listenerRetryTimer != null) return;
    _cancelListeners();
    final delay = listenerRetryDelay(_listenerRetryAttempt++);
    _listenerRetryTimer = Timer(delay, () {
      _listenerRetryTimer = null;
      if (_activeFamilyId == familyId) _attachListeners(familyId);
    });
  }

  /// A snapshot arrived, so the listeners are healthy again.
  void _onListenerHealthy() {
    if (_listenerError == null) return;
    _listenerRetryAttempt = 0;
    _setListenerError(null);
  }

  /// Reattaches errored listeners right away instead of waiting out the
  /// backoff — for app resume, alongside [drainNow].
  void reconnectNow() {
    final familyId = _activeFamilyId;
    if (familyId == null || _listenerRetryTimer == null) return;
    _listenerRetryTimer!.cancel();
    _listenerRetryTimer = null;
    _attachListeners(familyId);
  }

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
  ///
  /// [uid] must be an account the family admits (its owner or an
  /// invite-joined member) — see `cloudAccessProvider`.
  void start(String familyId, String uid) {
    if (_firestore == null) return;
    if (_activeFamilyId == familyId && _activeUid == uid) return;
    stop();
    _activeFamilyId = familyId;
    _activeUid = uid;
    _signedInUid = uid;
    Zone.root.run(() => unawaited(_activateSync(familyId, uid)));
  }

  Future<void> _activateSync(String familyId, String uid) async {
    await _runInitialReconciliationIfNeeded(familyId);
    await drainNow();
    // A stop()/different start() may have run while the above awaited —
    // don't attach listeners for a family that's no longer the active one.
    if (_activeFamilyId != familyId) return;
    _attachListeners(familyId);
    await _writeMembershipIndex(familyId, uid);
  }

  void _attachListeners(String familyId) {
    for (final adapter in _adapters.values) {
      _listen(adapter, familyId);
    }
  }

  void _cancelListeners() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }

  /// Records `users/{uid}.familyId` — how this account finds its family
  /// again from a new device without another invite (see
  /// `CloudMembershipRepository.lookupFamily`). Written only once sync is
  /// running, by which point the family doc exists and the rules can
  /// confirm the membership the record claims. Best-effort: a failure is
  /// simply retried the next time sync starts.
  Future<void> _writeMembershipIndex(String familyId, String uid) async {
    try {
      await _firestore!.collection('users').doc(uid).set({
        'familyId': familyId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Detaches every listener and stops draining. Does not touch the
  /// outbox — queued rows stay put and resume once [start] is called again
  /// for the same family (see the "pause on sign-out" behavior in the
  /// Firestore sync plan).
  void stop() {
    _cancelListeners();
    _listenerRetryTimer?.cancel();
    _listenerRetryTimer = null;
    _listenerRetryAttempt = 0;
    _activeFamilyId = null;
    _activeUid = null;
    _setListenerError(null);
  }

  void _listen(SyncAdapter adapter, String familyId) {
    // Only ever called from start(), which already checked _firestore != null.
    if (adapter.isSingleton) {
      final sub = _firestore!
          .collection(adapter.collectionPath(familyId))
          .doc(familyId)
          .snapshots()
          .listen((doc) async {
        _onListenerHealthy();
        if (doc.metadata.hasPendingWrites) return;
        final data = doc.data();
        if (data == null) return;
        try {
          await _mergeIncoming(adapter, familyId, data);
        } catch (_) {
          // A singleton has nothing to "drop siblings" for, but stays
          // consistent with the collection branch below rather than
          // crashing the whole listener over one bad merge.
        }
      }, onError: _onListenerError);
      _subscriptions.add(sub);
      return;
    }
    final sub = _firestore!
        .collection(adapter.collectionPath(familyId))
        .snapshots()
        .listen((snapshot) async {
      _onListenerHealthy();
      for (final change in snapshot.docChanges) {
        // Our own optimistic write echoing back — the eventual
        // server-timestamp round-trip in _pushOne is the authoritative
        // comparison for this entity, not this (possibly racing) snapshot.
        if (change.doc.metadata.hasPendingWrites) continue;
        final data = change.doc.data();
        if (data == null) continue;
        try {
          await _mergeIncoming(adapter, change.doc.id, data);
        } catch (_) {
          // One malformed/unexpected remote document (e.g. a field this
          // build doesn't know how to decode) must not stop every sibling
          // change in the same snapshot batch from being applied — Firestore
          // only redelivers a doc when it changes again, so letting this
          // propagate could lose a legitimate sibling update indefinitely.
        }
      }
    }, onError: _onListenerError);
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
        // A stop()/different start() may have run while a previous
        // adapter's pass awaited — bail out rather than keep reconciling
        // (and, worse, eventually marking migration-complete for) a family
        // that's no longer the active one. See the final check below for
        // why this alone isn't sufficient.
        if (_activeFamilyId != familyId) return;
        await _reconcileAdapterFully(adapter, familyId);
      }
      // The loop above can only ever *return early* on a family switch,
      // never race past this final check — but re-check anyway right
      // before the write, since the switch could just as easily have
      // happened during the very last adapter's own await. Writing this
      // flag for a family that isn't [familyId] anymore would wrongly mark
      // *this* family's migration complete without ever having reconciled
      // it (this single-row table has no per-family scoping of its own).
      if (_activeFamilyId != familyId) return;
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

  /// True if [entityId] has *any* outbox row at all, `failed` included —
  /// not just `pending`/`retrying`. A `failed` local write is still a real
  /// local edit nobody's resolved yet; if this returned false for it, an
  /// incoming remote change would look "safe" to apply over it in
  /// [_mergeIncoming], silently discarding that edit before the user ever
  /// gets a chance to retry it. Blocking the merge instead leaves the
  /// local edit in place — visibly stuck (Settings' "Cloud sync" card
  /// shows it) rather than silently gone — until the user retries and
  /// either it wins for real, or a subsequent legitimate remote update
  /// arrives and there's no longer a failed row to block it.
  Future<bool> _hasPendingLocalWrite(SyncEntityType type, String entityId) async {
    final rows = await (_db.select(_db.syncOutbox)
          ..where((o) => o.entityType.equalsValue(type) & o.entityId.equals(entityId))
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  /// Queues [entityId] to be pushed — call from inside the same
  /// `AppDatabase.transaction()` block as the entity write it describes,
  /// so the two commit atomically (see the Firestore sync plan's
  /// "Durability" section for why).
  ///
  /// While syncing, the row is queued under the syncing account and
  /// drained right away. While *not* syncing but the family is already in
  /// the cloud (signed out, or signed in as an account the family hasn't
  /// admitted), the change is still recorded — as [SyncOutboxStatus.held],
  /// with whoever was signed in as its origin — so it's never silently
  /// lost, but also never uploaded until a member reviews it (see
  /// [uploadHeld]/[discardHeld]). A no-op only when there's no cloud family
  /// to sync to yet: before the first link, the initial reconciliation
  /// pass uploads every local row anyway.
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
    if (_firestore == null) return;
    final activeFamilyId = _activeFamilyId;
    var familyId = activeFamilyId;
    if (familyId == null) {
      final profile =
          await (db.select(db.familyProfile)..where((p) => p.id.equals(1))).getSingleOrNull();
      if (profile?.familyId == null || profile?.initialCloudMigrationCompletedAt == null) {
        return;
      }
      familyId = profile!.familyId!;
    }
    final syncing = activeFamilyId != null;
    await db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            familyId: familyId,
            entityType: type,
            entityId: entityId,
            operation: SyncOperation.upsert,
            status: Value(syncing ? SyncOutboxStatus.pending : SyncOutboxStatus.held),
            originUid: Value(syncing ? _activeUid : _signedInUid),
          ),
        );
    if (syncing) Zone.root.run(() => unawaited(drainNow()));
  }

  /// Rows of the active family that only drain once a member decides to:
  /// [SyncOutboxStatus.held] ones, plus any queued under a different
  /// account than the one syncing now (e.g. the owner's unsent changes on
  /// a shared phone, after someone else signs in). Signing in never makes
  /// another account's changes upload on its own.
  Expression<bool> _needsReview($SyncOutboxTable o, String familyId, String uid) =>
      o.familyId.equals(familyId) &
      (o.status.equalsValue(SyncOutboxStatus.held) |
          o.originUid.isNull() |
          o.originUid.equals(uid).not());

  /// "Upload": the syncing member takes the reviewed changes on as their
  /// own and they drain like any other.
  Future<void> uploadHeld() async {
    final familyId = _activeFamilyId;
    final uid = _activeUid;
    if (familyId == null || uid == null) return;
    await (_db.update(_db.syncOutbox)..where((o) => _needsReview(o, familyId, uid))).write(
      SyncOutboxCompanion(
        status: const Value(SyncOutboxStatus.pending),
        originUid: Value(uid),
        attemptCount: const Value(0),
        nextRetryAt: const Value(null),
      ),
    );
    await drainNow();
  }

  /// "Keep on this device": drops the reviewed changes from the queue. The
  /// edits themselves stay in the local database; they just won't upload.
  Future<void> discardHeld() async {
    final familyId = _activeFamilyId;
    final uid = _activeUid;
    if (familyId == null || uid == null) return;
    await (_db.delete(_db.syncOutbox)..where((o) => _needsReview(o, familyId, uid))).go();
  }

  /// The manual "Retry" action for the Settings sync status row: `failed`
  /// rows are deliberately excluded from [drainNow]'s automatic sweep (see
  /// "Outbox failure policy" in the Firestore sync plan — they're not
  /// retried forever), so a user-initiated retry has to explicitly put
  /// them back in the running by resetting their status before draining.
  Future<void> retryFailed() async {
    final familyId = _activeFamilyId;
    final uid = _activeUid;
    if (familyId == null || uid == null) return;
    await (_db.update(_db.syncOutbox)
          ..where((o) =>
              o.familyId.equals(familyId) &
              o.originUid.equals(uid) &
              o.status.equalsValue(SyncOutboxStatus.failed)))
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
  ///
  /// [start]'s own await and [enqueueUpsert]'s post-write kick can easily
  /// overlap — e.g. a write lands right as `start()` is draining the
  /// backlog. Two overlapping drains would both read the same "due" rows
  /// before either's [_pushOne] removes them, race each other's push of
  /// the same entity, and (since whichever `.set()` reaches the server
  /// last wins, regardless of which local snapshot was actually newer)
  /// can let a staler write clobber a fresher one in Firestore. Only one
  /// drain pass runs at a time; a call that arrives mid-drain doesn't
  /// start a second one but isn't dropped either — it schedules exactly
  /// one more pass right after the current one finishes, so whatever
  /// became due while draining still gets picked up promptly rather than
  /// waiting for some later trigger.
  Future<void> drainNow() async {
    if (_draining) {
      _drainRequestedAgain = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainRequestedAgain = false;
        await _drainOnce();
      } while (_drainRequestedAgain);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainOnce() async {
    final familyId = _activeFamilyId;
    final uid = _activeUid;
    if (familyId == null || uid == null) return;
    final now = DateTime.now();
    final rows = await (_db.select(_db.syncOutbox)
          ..where((o) =>
              o.familyId.equals(familyId) &
              o.originUid.equals(uid) &
              o.status.isInValues([SyncOutboxStatus.pending, SyncOutboxStatus.retrying]) &
              (o.nextRetryAt.isNull() | o.nextRetryAt.isSmallerOrEqualValue(now))))
        .get();
    for (final row in rows) {
      // Mirrors _runInitialReconciliationIfNeeded's per-adapter guard — a
      // sign-out/family-switch mid-drain (stop() sets _activeFamilyId to
      // something else) must stop this loop from continuing to push
      // [familyId]'s backlog using a family that's no longer active,
      // rather than only checking once before the whole batch was read.
      if (_activeFamilyId != familyId) return;
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
    if (code == 'permission-denied') _accessDenied.add(null);
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

/// How long to wait before reattaching listeners after the [attempt]th
/// consecutive listener error: 5s, 15s, 1m, then every 5m.
Duration listenerRetryDelay(int attempt) {
  const stepsSeconds = [5, 15, 60, 300];
  return Duration(seconds: stepsSeconds[attempt.clamp(0, stepsSeconds.length - 1)]);
}
