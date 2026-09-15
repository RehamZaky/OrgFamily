import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';

/// Manages the single-row [FamilyProfile] table — family-level settings
/// that don't belong to any one [FamilyMember], starting with the photo
/// shown in the home screen header. Also carries `familyId`/`ownerUid`
/// (V2 Auth) — see docs/architecture.md "Family identity and
/// authentication".
class FamilyProfileRepository {
  FamilyProfileRepository(this._db);

  final AppDatabase _db;

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
  Future<void> recordLink({required String uid, required bool isOwner}) async {
    final existing =
        await (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
            .getSingleOrNull();
    final familyId = existing?.familyId ?? const Uuid().v4();
    await _db.into(_db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(
            id: const Value(_rowId),
            familyId: Value(familyId),
            ownerUid: isOwner ? Value(uid) : Value(existing?.ownerUid),
          ),
        );
  }
}
