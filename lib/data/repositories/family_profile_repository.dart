import 'package:drift/drift.dart';

import '../local/database.dart';

/// Manages the single-row [FamilyProfile] table — family-level settings
/// that don't belong to any one [FamilyMember], starting with the photo
/// shown in the home screen header.
class FamilyProfileRepository {
  FamilyProfileRepository(this._db);

  final AppDatabase _db;

  static const _rowId = 1;

  Stream<String?> watchPhotoPath() {
    return (_db.select(_db.familyProfile)..where((p) => p.id.equals(_rowId)))
        .watchSingleOrNull()
        .map((row) => row?.photoPath);
  }

  Future<void> setPhotoPath(String? path) {
    return _db.into(_db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(id: const Value(_rowId), photoPath: Value(path)),
        );
  }
}
