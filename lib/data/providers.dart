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
import 'repositories/family_invite_repository.dart';
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

/// Whether the signed-in account may sync this device's family, and if
/// not, why — drives both [activeSyncFamilyIdProvider] and Settings' cloud
/// cards.
enum CloudAccess {
  /// Signed out, or this device's family has never been linked to the
  /// cloud — nothing to sync and nothing to explain.
  none,

  /// The family is linked but its Owner hasn't linked yet, so no cloud
  /// family doc exists to sync against (an Adult linked first).
  awaitingOwner,

  /// The signed-in uid is the family's owner, or joined it via an invite.
  member,

  /// Signed in with an account Firestore won't admit to this family —
  /// neither its owner nor invite-joined. Sync stays off rather than
  /// queueing writes the security rules will always deny.
  notMember,
}

/// Decides [CloudAccess] for the signed-in account. Firestore admits only
/// the family doc's `ownerUid` or a uid with a `joinedUids/{uid}` grant
/// (see firestore.rules), so this mirrors exactly that: a match on the
/// local `ownerUid`, or on `joinedUid`, the local record of an invite
/// claimed on this device (`FamilyProfileRepository.recordJoin`/
/// `markJoined`). Merely having a local member linked to the uid is *not*
/// enough — linking on a device that already has a family
/// (`LinkMemberScreen`) records who you are locally but grants no cloud
/// access, which is how a second adult signing in on the owner's phone
/// used to start a sync whose every read and write was denied.
///
/// A joiner's local `ownerUid` stays null until sync pulls the family doc
/// down, so `joinedUid` (set before sync starts) is what lets their sync
/// start at all — gating on `ownerUid` alone would deadlock.
final cloudAccessProvider = Provider<CloudAccess>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return CloudAccess.none;
  final profile = ref.watch(familyProfileStreamProvider).valueOrNull;
  if (profile?.familyId == null) return CloudAccess.none;
  if (profile!.ownerUid == user.uid || profile.joinedUid == user.uid) {
    return CloudAccess.member;
  }
  if (profile.ownerUid == null) return CloudAccess.awaitingOwner;
  // Not a member by local records — but a device that joined before the
  // `joinedUid` marker existed has no local record either, so confirm
  // against Firestore once before deciding. A confirmed grant writes the
  // marker, which re-runs this provider as a member.
  final remotelyJoined = ref.watch(_remoteJoinGrantProvider((profile.familyId!, user.uid)));
  return remotelyJoined.valueOrNull == true ? CloudAccess.member : CloudAccess.notMember;
});

/// One-shot check for a `families/{familyId}/joinedUids/{uid}` grant —
/// see [cloudAccessProvider]. A non-member's read is denied by the rules
/// (the grant doc is only readable by members), which counts as "no".
final _remoteJoinGrantProvider =
    FutureProvider.family<bool, (String, String)>((ref, args) async {
  if (!isFirebaseAuthSupportedPlatform) return false;
  final (familyId, uid) = args;
  try {
    final doc = await ref
        .watch(firestoreProvider)
        .collection('families')
        .doc(familyId)
        .collection('joinedUids')
        .doc(uid)
        .get();
    if (!doc.exists) return false;
    await ref.read(familyProfileRepositoryProvider).markJoined(uid);
    return true;
  } catch (_) {
    return false;
  }
});

/// The familyId [syncEngineProvider] should be syncing against right now,
/// or null if it shouldn't be syncing at all — see [cloudAccessProvider].
/// `RootScaffold` listens to this and calls `SyncEngine.start`/`stop`
/// accordingly.
final activeSyncFamilyIdProvider = Provider<String?>((ref) {
  if (ref.watch(cloudAccessProvider) != CloudAccess.member) return null;
  return ref.watch(familyProfileStreamProvider).valueOrNull?.familyId;
});

/// See [SyncEngine.listenerError].
final syncListenerErrorProvider = StreamProvider<String?>((ref) async* {
  final engine = ref.watch(syncEngineProvider);
  yield engine.listenerError;
  yield* engine.listenerErrorChanges;
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

/// Always constructible (unlike [syncEngineProvider], no inert variant
/// needed) — invitations are pure Firestore control-plane calls with no
/// local Drift table, so nothing here touches the database at all. Not
/// meaningfully callable on a platform that never initializes Firebase
/// (see `isFirebaseAuthSupportedPlatform`); screens that reach it are only
/// ever shown after a real sign-in, which already requires that platform.
final familyInviteRepositoryProvider = Provider<FamilyInviteRepository>((ref) {
  return FamilyInviteRepository(ref.watch(firestoreProvider));
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
