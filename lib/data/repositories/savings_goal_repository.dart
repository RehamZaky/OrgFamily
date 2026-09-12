import 'package:drift/drift.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/savings_goals_table.dart';

class SavingsGoalRepository {
  SavingsGoalRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavingsGoal>> watchGoals() {
    return (_db.select(_db.savingsGoals)
          ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
        .watch();
  }

  Future<void> addGoal({
    required String id,
    required String name,
    required SavingsGoalIcon icon,
    required int targetCents,
    DateTime? targetDate,
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageSavingsGoals)) {
      throw FamilyPermissionException(FamilyAction.manageSavingsGoals, actingRole);
    }
    await _db.into(_db.savingsGoals).insert(
          SavingsGoalsCompanion.insert(
            id: id,
            name: name,
            icon: Value(icon),
            targetCents: targetCents,
            targetDate: Value(targetDate),
            createdByMemberId: Value(actingMemberId),
          ),
        );
  }

  Future<void> updateGoal(
    SavingsGoal goal, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageSavingsGoals)) {
      throw FamilyPermissionException(FamilyAction.manageSavingsGoals, actingRole);
    }
    await _db.update(_db.savingsGoals).replace(goal);
  }

  Future<void> deleteGoal(
    String id, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageSavingsGoals)) {
      throw FamilyPermissionException(FamilyAction.manageSavingsGoals, actingRole);
    }
    await (_db.delete(_db.savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Adds [amountCents] to the goal's saved total, clamped so it never
  /// exceeds the target — a contribution can't overshoot the goal.
  Future<void> contribute(
    String id,
    int amountCents, {
    FamilyRole actingRole = FamilyRole.owner,
    String? actingMemberId,
  }) async {
    if (!canPerform(actingRole, FamilyAction.manageSavingsGoals)) {
      throw FamilyPermissionException(FamilyAction.manageSavingsGoals, actingRole);
    }
    final goal =
        await (_db.select(_db.savingsGoals)..where((g) => g.id.equals(id))).getSingleOrNull();
    if (goal == null) return;
    final newSaved = (goal.savedCents + amountCents).clamp(0, goal.targetCents);
    await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id)))
        .write(SavingsGoalsCompanion(savedCents: Value(newSaved)));
  }
}
