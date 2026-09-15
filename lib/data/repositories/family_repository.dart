import 'package:drift/drift.dart';

import '../../core/permissions/family_permissions.dart';
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
    // The Firebase uid this member should be linked to at creation time —
    // used by the sign-up flow (the new Owner links themselves
    // immediately) and by "add an Adult with their own account". Never
    // set for Child members. See docs/architecture.md "Family identity
    // and authentication".
    String? linkedUid,
    FamilyRole actingRole = FamilyRole.owner,
  }) {
    if (!canPerform(actingRole, FamilyAction.manageMembers)) {
      throw FamilyPermissionException(FamilyAction.manageMembers, actingRole);
    }
    return _db.transaction(() async {
      if (role == FamilyRole.owner) await _demoteOtherOwners(exceptId: id);
      await _db.into(_db.familyMembers).insert(
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
              linkedUid: Value(linkedUid),
            ),
          );
    });
  }

  /// Every Owner/Adult member not yet linked to a Firebase account — the
  /// candidates shown by the post-sign-in "which of these are you?"
  /// picker on an upgraded V1 install. Children never appear here (see
  /// `linkMember` below).
  Stream<List<FamilyMember>> watchUnlinkedAdults() {
    return (_db.select(_db.familyMembers)
          ..where((m) => m.linkedUid.isNull() & m.role.equalsValue(FamilyRole.child).not()))
        .watch();
  }

  /// Links an *existing* Owner/Adult member to a signed-in Firebase
  /// account — the "which of these are you?" step for an upgraded V1
  /// install, or an Adult linking their own account later from Settings.
  /// Deliberately narrower than `updateMember`: it only ever touches
  /// `linkedUid`, so it can't accidentally overwrite anything else about
  /// the member, and it refuses to link a Child (children stay
  /// credential-free by design).
  Future<void> linkMember(String id, String uid) async {
    final member = await (_db.select(_db.familyMembers)..where((m) => m.id.equals(id)))
        .getSingle();
    if (member.role == FamilyRole.child) {
      throw StateError('Child members are never linked to a Firebase account.');
    }
    await (_db.update(_db.familyMembers)..where((m) => m.id.equals(id)))
        .write(FamilyMembersCompanion(linkedUid: Value(uid)));
  }

  Future<void> updateMember(
    FamilyMember member, {
    FamilyRole actingRole = FamilyRole.owner,
  }) {
    if (!canPerform(actingRole, FamilyAction.manageMembers)) {
      throw FamilyPermissionException(FamilyAction.manageMembers, actingRole);
    }
    return _db.transaction(() async {
      if (member.role == FamilyRole.owner) {
        await _demoteOtherOwners(exceptId: member.id);
      }
      await _db.update(_db.familyMembers).replace(member);
    });
  }

  /// Enforces "at most one Owner" — the app treats the Owner as "you" for
  /// greetings/defaults ([currentMemberProvider]), so two Owners at once
  /// makes that pick ambiguous. Demotes everyone else currently marked
  /// Owner to Adult whenever a member is (re)assigned the role.
  Future<void> _demoteOtherOwners({required String exceptId}) async {
    final members = await getMembers();
    for (final m in members) {
      if (m.id != exceptId && m.role == FamilyRole.owner) {
        await (_db.update(_db.familyMembers)..where((t) => t.id.equals(m.id)))
            .write(const FamilyMembersCompanion(role: Value(FamilyRole.adult)));
      }
    }
  }

  Future<void> deleteMember(String id, {FamilyRole actingRole = FamilyRole.owner}) {
    if (!canPerform(actingRole, FamilyAction.manageMembers)) {
      throw FamilyPermissionException(FamilyAction.manageMembers, actingRole);
    }
    return (_db.delete(_db.familyMembers)..where((m) => m.id.equals(id))).go();
  }
}
