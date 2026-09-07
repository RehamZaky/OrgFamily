import 'package:drift/drift.dart';

/// Single-row table for family-level (not per-member) settings — today just
/// the photo shown in the home screen header, next to the individual
/// per-member photos already stored on [FamilyMembers].
class FamilyProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
