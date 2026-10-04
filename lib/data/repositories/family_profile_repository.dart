import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/sync_outbox_table.dart';
import '../sync/sync_engine.dart';

/// Manages the single-row [FamilyProfile] table — family-level settings
/// that don't belong to any one [FamilyMember], starting with the photo
/// shown in the home screen header. Also carries `familyId`/`ownerUid`
/// (V2 Auth) — see docs/architecture.md "Family identity and
/// authentication".
class FamilyProfileRepository {
  FamilyProfileRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  static const _rowId = 1;

  Stream<String?> watchPhotoPath() {
    return (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
        .watchSingleOrNull()
        .map((row) => row?.photoPath);
  }

  Future<void> setPhotoPath(String? path, {FamilyRole actingRole = FamilyRole.owner}) {
    if (!canPerform(actingRole, FamilyAction.manageFamilySettings)) {
      throw FamilyPermissionException(FamilyAction.manageFamilySettings, actingRole);
    }
    return _db.into(_db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(id: const Value(_rowId), photoPath: Value(path)),
        );
  }

  Stream<FamilyProfileData?> watchProfile() {
    return (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
        .watchSingleOrNull();
  }

  /// Called once, right after `FamilyRepository.linkMember` — generates a
  /// stable `familyId` if this local family doesn't have one yet (never
  /// regenerated on later logins/logouts), and sets `ownerUid` **only**
  /// when [isOwner] is true, i.e. the member who just linked is actually
  /// `role == owner` locally. An Adult linking first still gets a
  /// `familyId` generated, but `ownerUid` stays null until the Owner
  /// links too — see docs/architecture.md.
  ///
  /// The existing-row read and the write it decides from must happen
  /// inside the *same* transaction — a double-tap on the calling screen's
  /// Save button (or any other double call) fires this twice back to
  /// back, and if the read happened before either transaction started,
  /// both calls could see "no familyId yet", both mint their own
  /// `Uuid().v4()`, and whichever write commits last would silently pin
  /// this device's family to a *different* id than the one `_sync.start`
  /// was already called with a moment earlier by the other call. Drift
  /// serializes transactions against the same database, so doing the read
  /// inside one means the second call's read is guaranteed to see the
  /// first call's already-committed write, not a stale "not linked yet".
  Future<void> recordLink({required String uid, required bool isOwner}) async {
    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
              .getSingleOrNull();
      final familyId = existing?.familyId ?? const Uuid().v4();
      await _db.into(_db.familyProfile).insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(_rowId),
              familyId: Value(familyId),
              ownerUid: isOwner ? Value(uid) : Value(existing?.ownerUid),
              updatedAt: Value(DateTime.now()),
            ),
          );
      // Sync only ever activates once the true local Owner has linked —
      // the Firestore family doc can only be *created* by the Owner's own
      // uid (see firestore.rules), so an Adult linking first still gets
      // familyId bookkeeping above, but sync stays dormant until the
      // Owner links too.
      if (isOwner) {
        _sync.start(familyId);
        await _sync.enqueueUpsert(
          db: _db,
          type: SyncEntityType.familyProfile,
          entityId: familyId,
        );
      }
    });
  }

  /// Called once, right after [uid]'s device has successfully claimed a
  /// [FamilyInviteRepository] invite for [familyId] — sets this device's
  /// local `familyId` to the *joined* family (never mints a new one,
  /// unlike [recordLink]) and starts sync so the initial reconciliation
  /// pass pulls down the rest of that family's data. `ownerUid` is
  /// deliberately left untouched (null, on a fresh device) — only the
  /// real Owner's own [recordLink] ever sets it, since only they can have
  /// created the Firestore family doc. This device's sync activation
  /// instead comes from having a local member linked to [uid] — see
  /// `activeSyncFamilyIdProvider`'s doc comment in `providers.dart` and
  /// docs/architecture.md "Family invitations".
  ///
  /// `updatedAt` is deliberately stamped far in the past, not "now" —
  /// this row has no genuine local edit to a synced field (`ownerUid` is
  /// null; `familyId` isn't synced at all, it's the doc id), so it must
  /// never win last-write-wins against the real family doc's `ownerUid`,
  /// which was set once at family-creation time. Stamping "now" here (the
  /// original bug) made the local row look newer than that already-old
  /// remote write, so `SyncEngine`'s "apply only if the remote is newer"
  /// check (`_mergeIncoming`/`_reconcileSingleton`) would never apply it —
  /// this device's `ownerUid` would silently stay null forever, breaking
  /// the very invariant `activeSyncFamilyIdProvider`'s doc comment assumes
  /// ("a joiner's local ownerUid only ever arrives through sync").
  Future<void> recordJoin({required String familyId, required String uid}) async {
    await _db.into(_db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(
            id: const Value(_rowId),
            familyId: Value(familyId),
            joinedUid: Value(uid),
            updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
          ),
        );
    _sync.start(familyId);
  }

  /// Records that [uid] holds an invite grant for this device's *existing*
  /// family — for an adult who claimed an invite on a device that already
  /// has the family locally (e.g. the Owner's phone), or for a device whose
  /// join predates the local `joinedUid` marker and was confirmed against
  /// Firestore's `joinedUids/{uid}` instead. Unlike [recordJoin], touches
  /// nothing but the marker: familyId is already right and `updatedAt`
  /// must keep its real value for last-write-wins.
  Future<void> markJoined(String uid) {
    return (_db.update(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
        .write(FamilyProfileCompanion(joinedUid: Value(uid)));
  }
}
