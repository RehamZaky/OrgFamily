import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_config.dart';
import '../core/notifications/notification_service.dart';
import 'local/database.dart';
import 'local/tables/sync_outbox_table.dart';
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
import 'sync/adapters/event_sync_adapter.dart';
import 'sync/adapters/family_member_sync_adapter.dart';
import 'sync/adapters/family_profile_sync_adapter.dart';
import 'sync/adapters/shopping_item_sync_adapter.dart';
import 'sync/adapters/shopping_list_sync_adapter.dart';
import 'sync/adapters/task_sync_adapter.dart';
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
    TaskSyncAdapter(db),
    EventSyncAdapter(db),
    ShoppingListSyncAdapter(db),
    ShoppingItemSyncAdapter(db),
  ]);
});

final familyProfileStreamProvider = StreamProvider<FamilyProfileData?>((ref) {
  return ref.watch(familyProfileRepositoryProvider).watchProfile();
});

/// The familyId [syncEngineProvider] should be syncing against right now,
/// or null if it shouldn't be syncing at all — signed out, or linked but
/// not yet Owner-confirmed (see `FamilyProfileSyncAdapter`'s doc comment
/// on why "has an ownerUid", not just "has a familyId", is the bar).
/// `RootScaffold` listens to this and calls `SyncEngine.start`/`stop`
/// accordingly — see docs/architecture.md "Firestore sync".
final activeSyncFamilyIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final profile = ref.watch(familyProfileStreamProvider).valueOrNull;
  if (profile?.ownerUid == null) return null;
  return profile?.familyId;
});

final isCloudSyncActiveProvider = Provider<bool>((ref) {
  return ref.watch(activeSyncFamilyIdProvider) != null;
});

/// How many locally-queued changes for the active family haven't reached
/// Firestore yet ([pending]: still trying, possibly with backoff) versus
/// given up on ([failed]: a permanent error, or too many unclassified
/// ones — see `SyncEngine`'s "Outbox failure policy"). Null while sync
/// isn't active at all.
class SyncOutboxSummary {
  const SyncOutboxSummary({required this.pending, required this.failed});
  final int pending;
  final int failed;
}

final syncOutboxSummaryProvider = StreamProvider<SyncOutboxSummary?>((ref) {
  final familyId = ref.watch(activeSyncFamilyIdProvider);
  if (familyId == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return (db.select(db.syncOutbox)..where((o) => o.familyId.equals(familyId)))
      .watch()
      .map((rows) => SyncOutboxSummary(
            pending: rows.where((r) => r.status != SyncOutboxStatus.failed).length,
            failed: rows.where((r) => r.status == SyncOutboxStatus.failed).length,
          ));
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider), ref.watch(syncEngineProvider));
});

final familyProfileRepositoryProvider = Provider<FamilyProfileRepository>((ref) {
  return FamilyProfileRepository(ref.watch(databaseProvider), ref.watch(syncEngineProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(syncEngineProvider),
  );
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(syncEngineProvider),
  );
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(databaseProvider), ref.watch(syncEngineProvider));
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
