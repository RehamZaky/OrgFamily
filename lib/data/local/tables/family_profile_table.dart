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
  /// Firestore sync bookkeeping — see `tasks_table.dart`'s `updatedAt` doc
  /// comment. No `deletedAt`: this singleton row is never deleted, only
  /// ever upserted.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  /// Set once, only after the one-time initial reconciliation pass has
  /// succeeded for *every* synced collection (not per-collection — see
  /// `docs/architecture.md` "Firestore sync"). Local-only, never synced to
  /// Firestore. Before this is set, a local row with no remote counterpart
  /// is genuine pre-cloud V1 data to push; after, "missing remotely" is
  /// never re-interpreted as "needs uploading" again, which is what stops
  /// a deleted row from being resurrected on a later reconnect.
  DateTimeColumn get initialCloudMigrationCompletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
