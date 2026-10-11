import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_config.dart';
import '../core/notifications/notification_service.dart';
import 'activity/activity_log.dart';
import 'local/database.dart';
import 'local/tables/sync_outbox_table.dart';
import 'repositories/auth_repository.dart';
import 'repositories/budget_repository.dart';
import 'repositories/cloud_membership_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/family_invite_repository.dart';
import 'repositories/family_profile_repository.dart';
import 'repositories/family_repository.dart';
import 'repositories/note_repository.dart';
import 'repositories/responsibility_repository.dart';
import 'repositories/savings_goal_repository.dart';
import 'repositories/shopping_repository.dart';
import 'repositories/task_repository.dart';
import 'sync/adapters/activity_sync_adapter.dart';
import 'sync/adapters/event_sync_adapter.dart';
import 'sync/adapters/family_member_sync_adapter.dart';
import 'sync/adapters/family_profile_sync_adapter.dart';
import 'sync/adapters/responsibility_sync_adapter.dart';
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
    ResponsibilitySyncAdapter(db),
    ActivitySyncAdapter(db),
  ]);
});

final familyProfileStreamProvider = StreamProvider<FamilyProfileData?>((ref) {
  return ref.watch(familyProfileRepositoryProvider).watchProfile();
});

/// Whether the signed-in account may sync this device's family, and if
/// not, why — drives [activeSyncProvider] and Settings' cloud cards.
enum CloudAccess {
  /// Signed out, never linked to the cloud, or still confirming with
  /// Firestore — nothing to sync and nothing to explain yet.
  none,

  /// The family is linked but its Owner hasn't linked yet, so no cloud
  /// family doc exists to sync against (an Adult linked first).
  awaitingOwner,

  /// The signed-in uid is the family's owner, or holds an invite grant.
  member,

  /// Signed in with an account Firestore won't admit to this family —
  /// neither its owner nor invite-joined (or its grant was revoked). Sync
  /// stays off rather than sending writes the security rules will deny.
  notMember,
}

final cloudMembershipRepositoryProvider = Provider<CloudMembershipRepository>((ref) {
  return CloudMembershipRepository(ref.watch(firestoreProvider));
});

/// Counts `permission-denied` answers from [SyncEngine.accessDenied], so
/// [membershipVerificationProvider] can re-ask Firestore after each.
final _accessDeniedCountProvider = StreamProvider<int>((ref) {
  var count = 0;
  return ref.watch(syncEngineProvider).accessDenied.map((_) => ++count);
});

/// How long to wait before asking Firestore again after it couldn't be
/// reached — overridable so tests don't have to wait it out.
final membershipRetryDelayProvider = Provider<Duration>((ref) => const Duration(seconds: 30));

/// Firestore's answer to "does the signed-in [uid] belong to [familyId]?"
/// (see [CloudMembershipRepository.verify]), re-asked whenever sync hits a
/// denial — and, while Firestore can't be reached, every
/// [membershipRetryDelayProvider], since with sync off nothing else would
/// ever trigger another check once the connection returns. Also keeps the
/// local cache in step with it: a confirmed
/// membership with no local record (a join from before the record existed)
/// gets recorded, and a revoked one has its record cleared.
final membershipVerificationProvider =
    FutureProvider.family<MembershipStatus, (String, String)>((ref, args) async {
  ref.listen(_accessDeniedCountProvider, (_, _) => ref.invalidateSelf());
  if (!isFirebaseAuthSupportedPlatform) return MembershipStatus.unknown;
  final (familyId, uid) = args;
  final status = await ref.watch(cloudMembershipRepositoryProvider).verify(familyId);
  if (status == MembershipStatus.unknown) {
    final retry = Timer(ref.read(membershipRetryDelayProvider), ref.invalidateSelf);
    ref.onDispose(retry.cancel);
  }
  final profiles = ref.read(familyProfileRepositoryProvider);
  final profile = await profiles.watchProfile().first;
  if (profile?.familyId != familyId) return status;
  if (status == MembershipStatus.member &&
      profile?.ownerUid != uid &&
      profile?.joinedUid != uid) {
    await profiles.markJoined(uid);
  } else if (status == MembershipStatus.notMember && profile?.joinedUid == uid) {
    await profiles.clearJoined();
  }
  return status;
});

/// Decides [CloudAccess] for the signed-in account. Firestore admits only
/// the family doc's `ownerUid` or a uid with a `joinedUids/{uid}` grant
/// (see firestore.rules), and it — not this device — is the authority:
///
/// - The owner is trusted locally: `ownerUid` is immutable server-side and
///   only ever set by the owner's own link or pulled from the family doc.
/// - A local `joinedUid` record is a cache, honoured optimistically so sync
///   can start offline, but re-checked with Firestore each session and on
///   every denial; a revoked grant clears it and ends sync.
/// - With no local record (a join made before the record existed),
///   Firestore is asked before deciding.
///
/// Merely having a local member linked to the uid is *not* enough — a
/// second adult who signs in on the owner's phone (`LinkMemberScreen`) is
/// recorded locally but holds no grant, which is how a sync whose every
/// read and write was denied used to start.
final cloudAccessProvider = Provider<CloudAccess>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return CloudAccess.none;
  final profile = ref.watch(familyProfileStreamProvider).valueOrNull;
  final familyId = profile?.familyId;
  if (profile == null || familyId == null) return CloudAccess.none;
  if (profile.ownerUid == user.uid) return CloudAccess.member;
  final hasLocalRecord = profile.joinedUid == user.uid;
  final verification = membershipVerificationProvider((familyId, user.uid));
  // No owner linked yet and nothing recorded for this account: wait for the
  // owner. Unless Firestore was already asked about this account — then its
  // record was just cleared by a revocation, and its answer stands.
  if (!hasLocalRecord && profile.ownerUid == null && !ref.exists(verification)) {
    return CloudAccess.awaitingOwner;
  }
  final verified = ref.watch(verification).valueOrNull;
  return switch (verified) {
    MembershipStatus.member => CloudAccess.member,
    MembershipStatus.notMember => CloudAccess.notMember,
    // Couldn't ask (yet): a cached join is honoured so sync works offline;
    // without one, keep checking rather than declare a verdict Firestore
    // never gave — the retry above settles it once the connection returns.
    MembershipStatus.unknown || null => hasLocalRecord ? CloudAccess.member : CloudAccess.none,
  };
});

/// The family and account [syncEngineProvider] should be syncing as right
/// now, or null if it shouldn't be syncing at all — see
/// [cloudAccessProvider]. `RootScaffold` listens to this and calls
/// `SyncEngine.start`/`stop` accordingly.
final activeSyncProvider = Provider<({String familyId, String uid})?>((ref) {
  if (ref.watch(cloudAccessProvider) != CloudAccess.member) return null;
  final familyId = ref.watch(familyProfileStreamProvider).valueOrNull?.familyId;
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (familyId == null || uid == null) return null;
  return (familyId: familyId, uid: uid);
});

final activeSyncFamilyIdProvider = Provider<String?>((ref) {
  return ref.watch(activeSyncProvider)?.familyId;
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

/// The active family's queued changes, from the syncing account's point of
/// view: its own still uploading ([pending]) or given up on ([failed] — a
/// permanent error, or too many unclassified ones, see `SyncEngine`'s
/// "Outbox failure policy"), and [review]: changes that only upload once a
/// member chooses to — made while not syncing, or by another account (see
/// `SyncEngine.uploadHeld`). Null while sync isn't active at all.
class SyncOutboxSummary {
  const SyncOutboxSummary({
    required this.pending,
    required this.failed,
    this.review = const [],
  });
  final int pending;
  final int failed;
  final List<SyncOutboxData> review;

  /// Distinct entities in [review] — an entity edited several times is
  /// queued several times but is one change to the person reviewing it.
  /// Activity entries aren't counted: each follows the decision on the
  /// change it describes (see `SyncEngine.inspectReview`).
  int get reviewCount => review
      .where((r) => r.entityType != SyncEntityType.activity)
      .map((r) => (r.entityType, r.entityId))
      .toSet()
      .length;
}

final syncOutboxSummaryProvider = StreamProvider<SyncOutboxSummary?>((ref) {
  final active = ref.watch(activeSyncProvider);
  if (active == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return (db.select(db.syncOutbox)..where((o) => o.familyId.equals(active.familyId)))
      .watch()
      .map((rows) {
    bool needsReview(SyncOutboxData r) =>
        r.status == SyncOutboxStatus.held || r.originUid != active.uid;
    final mine = rows.where((r) => !needsReview(r));
    return SyncOutboxSummary(
      pending: mine.where((r) => r.status != SyncOutboxStatus.failed).length,
      failed: mine.where((r) => r.status == SyncOutboxStatus.failed).length,
      review: rows.where(needsReview).toList(),
    );
  });
});

/// One per app: the actor it stamps on entries is kept current by
/// `RootScaffold`.
final activityLogProvider = Provider<ActivityLog>((ref) {
  return ActivityLog(ref.watch(syncEngineProvider));
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
    activity: ref.watch(activityLogProvider),
  );
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
    activity: ref.watch(activityLogProvider),
  );
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(syncEngineProvider),
    activity: ref.watch(activityLogProvider),
  );
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
    activity: ref.watch(activityLogProvider),
  );
});

final responsibilityRepositoryProvider = Provider<ResponsibilityRepository>((ref) {
  return ResponsibilityRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
    activity: ref.watch(activityLogProvider),
  );
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
