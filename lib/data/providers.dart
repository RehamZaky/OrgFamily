import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import 'local/database.dart';
import 'repositories/budget_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/family_profile_repository.dart';
import 'repositories/family_repository.dart';
import 'repositories/note_repository.dart';
import 'repositories/responsibility_repository.dart';
import 'repositories/savings_goal_repository.dart';
import 'repositories/shopping_repository.dart';
import 'repositories/task_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider));
});

final familyProfileRepositoryProvider = Provider<FamilyProfileRepository>((ref) {
  return FamilyProfileRepository(ref.watch(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider), ref.watch(notificationServiceProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(databaseProvider), ref.watch(notificationServiceProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(databaseProvider));
});

final responsibilityRepositoryProvider = Provider<ResponsibilityRepository>((ref) {
  return ResponsibilityRepository(ref.watch(databaseProvider));
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(ref.watch(databaseProvider));
});
