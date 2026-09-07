import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables/family_members_table.dart';

class FamilyRepository {
  FamilyRepository(this._db);

  final AppDatabase _db;

  Stream<List<FamilyMember>> watchMembers() {
    return (_db.select(_db.familyMembers)
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  Future<List<FamilyMember>> getMembers() => _db.select(_db.familyMembers).get();

  Future<void> addMember({
    required String id,
    required String name,
    required String avatarEmoji,
    required int colorValue,
    required FamilyRole role,
    String? photoPath,
    DateTime? birthday,
    String? grade,
    String? school,
    String? notes,
  }) {
    return _db.into(_db.familyMembers).insert(
          FamilyMembersCompanion.insert(
            id: id,
            name: name,
            avatarEmoji: Value(avatarEmoji),
            photoPath: Value(photoPath),
            colorValue: colorValue,
            role: Value(role),
            birthday: Value(birthday),
            grade: Value(grade),
            school: Value(school),
            notes: Value(notes),
          ),
        );
  }

  Future<void> updateMember(FamilyMember member) {
    return _db.update(_db.familyMembers).replace(member);
  }

  Future<void> deleteMember(String id) {
    return (_db.delete(_db.familyMembers)..where((m) => m.id.equals(id))).go();
  }
}
