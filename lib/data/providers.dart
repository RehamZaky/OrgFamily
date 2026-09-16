import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_config.dart';
import '../core/notifications/notification_service.dart';
import 'local/database.dart';
import 'repositories/auth_repository.dart';
import 'repositories/budget_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/family_profile_repository.dart';
import 'repositories/family_repository.dart';
import 'repositories/note_repository.dart';
import 'repositories/responsibility_repository.dart';
import 'repositories/savings_goal_repository.dart';
import 'repositories/shopping_repository.dart';
import 'repositories/task_repository.dart';
import 'sync/adapters/family_member_sync_adapter.dart';
import 'sync/adapters/family_profile_sync_adapter.dart';
import 'sync/sync_engine.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

/// Live signed-in-user state — null while signed out. See
/// `lib/core/auth/auth_config.dart`: on desktop this stream never emits a
/// non-null user, since Firebase is never initialized there.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Always non-null (same pattern as [notificationServiceProvider]) — a
/// permanently-inert [SyncEngine.inert] on a platform that never
/// initializes Firebase at all, so this provider never touches
/// [firestoreProvider]/`FirebaseFirestore.instance` on desktop. See
/// `docs/architecture.md` "Firestore sync".
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  if (!isFirebaseAuthSupportedPlatform) return SyncEngine.inert(db);
  return SyncEngine(db, ref.watch(firestoreProvider), [
    FamilyMemberSyncAdapter(db),
    FamilyProfileSyncAdapter(db),
  ]);
});

/// True once this device is both signed in and linked to a family with an
/// Owner — see `FamilyProfileSyncAdapter`'s doc comment on why "has an
/// ownerUid", not just "has a familyId". Not yet wired to actually start/
/// stop [syncEngineProvider] — that's the Firestore sync plan's
/// "Lifecycle + reconciliation" step.
final familyProfileStreamProvider = StreamProvider<FamilyProfileData?>((ref) {
  return ref.watch(familyProfileRepositoryProvider).watchProfile();
});

final isCloudSyncActiveProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(familyProfileStreamProvider).valueOrNull;
  return user != null && profile?.ownerUid != null;
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider), ref.watch(syncEngineProvider));
});

final familyProfileRepositoryProvider = Provider<FamilyProfileRepository>((ref) {
  return FamilyProfileRepository(ref.watch(databaseProvider), ref.watch(syncEngineProvider));
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
