import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/family_members_table.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [FamilyMembers] to `families/{familyId}/members/{memberId}` —
/// every field except [FamilyMember.photoPath] (local-only, see the
/// Firestore sync plan).
class FamilyMemberSyncAdapter implements SyncAdapter<FamilyMember> {
  FamilyMemberSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.familyMember;

  @override
  String collectionPath(String familyId) => 'families/$familyId/members';

  @override
  DateTime updatedAtOf(FamilyMember row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(FamilyMember row) => row.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(FamilyMember row) {
    return {
      'name': row.name,
      'avatarEmoji': row.avatarEmoji,
      'colorValue': row.colorValue,
      'role': row.role.name,
      'birthday': row.birthday,
      'grade': row.grade,
      'school': row.school,
      'notes': row.notes,
      'linkedUid': row.linkedUid,
      'createdAt': row.createdAt,
      'deletedAt': row.deletedAt,
    };
  }

  @override
  Future<FamilyMember?> getLocalById(String id) {
    // Deliberately unfiltered by deletedAt, unlike FamilyRepository's own
    // watchMembers/getMembers — a soft-deleted row still needs to be found
    // here so its tombstone can be pushed.
    return (_db.select(_db.familyMembers)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final rows = await _db.select(_db.familyMembers).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.familyMembers).insertOnConflictUpdate(
          FamilyMembersCompanion.insert(
            id: id,
            name: fields['name'] as String,
            avatarEmoji: Value(fields['avatarEmoji'] as String? ?? '👨'),
            colorValue: fields['colorValue'] as int,
            role: Value(FamilyRole.values.byName(fields['role'] as String)),
            birthday: Value(toDateOrNull(fields['birthday'])),
            grade: Value(fields['grade'] as String?),
            school: Value(fields['school'] as String?),
            notes: Value(fields['notes'] as String?),
            linkedUid: Value(fields['linkedUid'] as String?),
            createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt),
            deletedAt: Value(toDateOrNull(fields['deletedAt'])),
          ),
        );
  }
}
