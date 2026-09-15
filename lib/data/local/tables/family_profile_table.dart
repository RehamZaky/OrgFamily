import 'package:drift/drift.dart';

/// Single-row table for family-level (not per-member) settings — today just
/// the photo shown in the home screen header, next to the individual
/// per-member photos already stored on [FamilyMembers].
class FamilyProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get photoPath => text().nullable()();
  // A stable id for this family, generated once when the first
  // Owner/Adult member links a Firebase account (see
  // family_members_table.dart's `linkedUid`) — reused as the future
  // Firestore `families/{familyId}` document id, never regenerated.
  TextColumn get familyId => text().nullable()();
  // The linked Owner's Firebase uid specifically — set only once the
  // member who links has local `role == owner`, not just whoever links
  // first (an Adult can link before the Owner does). See
  // docs/architecture.md "Family identity and authentication".
  TextColumn get ownerUid => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
