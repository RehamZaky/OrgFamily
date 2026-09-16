import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';

/// Mirrors the singleton [FamilyProfile] row to the family doc itself,
/// `families/{familyId}` — not a subcollection like every other adapter,
/// since there's exactly one of these per family. [isSingleton] tells
/// `SyncEngine` to always address it via `.doc()`, never an unconstrained
/// `.collection('families').get()/.snapshots()` — Firestore's security
/// rules can't prove a `resource.data`-dependent read rule holds for
/// every document a *query* over the whole collection could ever return
/// (there could be other families' docs in there too), and denies such a
/// query outright, even though a `get`/listen on one specific, known
/// document id works fine under the exact same rule.
///
/// Only `ownerUid` (and the `memberUids` derived from it) are synced here
/// — `photoPath` is local-only, and `familyId` is the doc id itself, not a
/// field. See the Firestore sync plan's "Security rules" section for why
/// `ownerUid`/`memberUids` are written as explicit, protected fields
/// rather than a blind mirror of the row.
///
/// Known gap (not solved by this pass — see the plan's note on
/// invitations): a second fresh-install device signing in with the same
/// Owner uid has no way to *discover* the existing cloud `familyId` before
/// its first local `AddMemberScreen` save, since `recordLink` only ever
/// reuses a `familyId` already present in its own local database. True
/// multi-device bootstrap needs a join/invitation flow, not just this
/// sync engine.
class FamilyProfileSyncAdapter implements SyncAdapter<FamilyProfileData> {
  FamilyProfileSyncAdapter(this._db);

  final AppDatabase _db;

  static const _rowId = 1;

  @override
  SyncEntityType get entityType => SyncEntityType.familyProfile;

  @override
  String collectionPath(String familyId) => 'families';

  @override
  bool get isSingleton => true;

  @override
  DateTime updatedAtOf(FamilyProfileData row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(FamilyProfileData row) => null;

  @override
  Map<String, dynamic> toFirestoreFields(FamilyProfileData row) {
    final ownerUid = row.ownerUid;
    return {
      if (ownerUid != null) 'ownerUid': ownerUid,
      if (ownerUid != null) 'memberUids': [ownerUid],
    };
  }

  @override
  Future<FamilyProfileData?> getLocalById(String id) {
    // Ignores [id] — there's only ever the one local row, and by the time
    // this is called it's already known to be this device's own family
    // (see the class doc comment).
    return (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
        .getSingleOrNull();
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async => [familyId];

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(
            id: const Value(_rowId),
            ownerUid: Value(fields['ownerUid'] as String?),
            updatedAt: Value(updatedAt),
          ),
        );
  }
}
