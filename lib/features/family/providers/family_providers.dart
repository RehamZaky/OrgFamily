import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/enum_display.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/family_members_table.dart';
import '../../../data/providers.dart';
import '../../tasks/providers/task_providers.dart';

const _activeMemberIdPrefsKey = 'active_member_id';
const _activeMemberUidPrefsKey = 'active_member_uid';

/// The profile someone explicitly picked as "me" in the drawer's profile
/// switcher — e.g. a parent handing their phone to a child. Only one input
/// to [actingMemberProvider], which is what everything else should read.
/// Null means "no explicit pick". Restored on launch by
/// [loadPersistedActiveMember] (main.dart) and changed via
/// [setActiveMember].
///
/// Purely local: never used for cloud/Firestore authorization, which always
/// goes by the signed-in Firebase uid — see docs/architecture.md.
final activeMemberIdProvider = StateProvider<String?>((ref) => null);

/// The Firebase uid that was signed in when [activeMemberIdProvider] was
/// picked (null if nobody was). A pick only counts while that same account
/// is signed in, so when Kareem signs out and Mariam signs in, Mariam never
/// inherits Kareem's "acting as Omar".
final activeMemberPickUidProvider = StateProvider<String?>((ref) => null);

Future<({String? memberId, String? uid})> loadPersistedActiveMember() async {
  final prefs = await SharedPreferences.getInstance();
  return (
    memberId: prefs.getString(_activeMemberIdPrefsKey),
    uid: prefs.getString(_activeMemberUidPrefsKey),
  );
}

/// Switches the explicit "me" pick and persists it, tagged with the
/// account signed in right now — call this rather than writing
/// [activeMemberIdProvider] directly. Pass null to clear the pick, which
/// makes [actingMemberProvider] fall back to the signed-in account's own
/// profile.
Future<void> setActiveMember(WidgetRef ref, String? memberId) async {
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  ref.read(activeMemberIdProvider.notifier).state = memberId;
  ref.read(activeMemberPickUidProvider.notifier).state = memberId == null ? null : uid;
  final prefs = await SharedPreferences.getInstance();
  if (memberId == null) {
    await prefs.remove(_activeMemberIdPrefsKey);
    await prefs.remove(_activeMemberUidPrefsKey);
  } else {
    await prefs.setString(_activeMemberIdPrefsKey, memberId);
    if (uid == null) {
      await prefs.remove(_activeMemberUidPrefsKey);
    } else {
      await prefs.setString(_activeMemberUidPrefsKey, uid);
    }
  }
}

final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(familyRepositoryProvider).watchMembers();
});

/// Owner/Adult members nobody's linked a Firebase account to yet — the
/// candidates `LinkMemberScreen` offers a freshly signed-in adult to pick
/// themselves as, on a device whose local family predates V2 Auth.
final unlinkedAdultMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(familyRepositoryProvider).watchUnlinkedAdults();
});

/// The family group photo shown in the home screen header — distinct from
/// any individual member's own photo.
final familyPhotoPathProvider = StreamProvider<String?>((ref) {
  return ref.watch(familyProfileRepositoryProvider).watchPhotoPath();
});

/// Midnight on the Monday of the current week — the cutoff used for all
/// "this week" family stats, so they reset together.
DateTime _startOfThisWeek() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - DateTime.monday));
}

/// Tasks each member completed this week, keyed by `assigneeId`. Tasks with
/// no assignee don't count toward anyone's points.
final familyPointsThisWeekProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  final weekStart = _startOfThisWeek();
  final points = <String, int>{};
  for (final t in tasks) {
    final assigneeId = t.assigneeId;
    final completedAt = t.completedAt;
    if (!t.isCompleted || assigneeId == null || completedAt == null) continue;
    if (completedAt.isBefore(weekStart)) continue;
    points[assigneeId] = (points[assigneeId] ?? 0) + t.priority.points;
  }
  return points;
});

/// Total tasks (any assignee) completed since the start of this week.
final tasksDoneThisWeekProvider = Provider<int>((ref) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  final weekStart = _startOfThisWeek();
  return tasks
      .where((t) =>
          t.isCompleted &&
          t.completedAt != null &&
          !t.completedAt!.isBefore(weekStart))
      .length;
});

final familyPointsTotalThisWeekProvider = Provider<int>((ref) {
  return ref
      .watch(familyPointsThisWeekProvider)
      .values
      .fold(0, (sum, p) => sum + p);
});

/// Tasks a specific member completed since the start of this week.
final tasksDoneThisWeekForMemberProvider =
    Provider.family<int, String>((ref, memberId) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  final weekStart = _startOfThisWeek();
  return tasks
      .where((t) =>
          t.assigneeId == memberId &&
          t.isCompleted &&
          t.completedAt != null &&
          !t.completedAt!.isBefore(weekStart))
      .length;
});

/// A member's currently-incomplete assigned tasks (not week-scoped — pending
/// work doesn't have a completion date to filter by).
final tasksPendingForMemberProvider =
    Provider.family<int, String>((ref, memberId) {
  final tasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  return tasks.where((t) => t.assigneeId == memberId && !t.isCompleted).length;
});

/// The profile linked to the signed-in Firebase account (`linkedUid`) —
/// who actually holds cloud authority on this device. Null when signed out
/// or when the account has no linked profile.
final authenticatedMemberProvider = Provider<FamilyMember?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  return members.where((m) => m.linkedUid == uid).firstOrNull;
});

/// The member this device is acting as — who performs family actions
/// (`createdByMemberId`, `completedByMemberId`, budget/goal authorship),
/// who the greeting and drawer show, and whose role local permissions use.
/// Distinct from who holds cloud authority: Firestore only ever sees the
/// signed-in uid, even while a parent's phone acts as a child.
///
/// Resolution:
/// 1. An explicit pick ([activeMemberIdProvider]) made under the account
///    that's signed in now, if that member still exists.
/// 2. Otherwise the signed-in account's own profile — so joining via an
///    invite, restoring on a new phone, or a stale/foreign pick all land on
///    the right person with no manual step, including on already-installed
///    apps.
/// 3. Signed in but no linked profile: unresolved (null). Never silently
///    the Owner — that fallback is what made an invited adult appear as,
///    and act with the permissions of, the family Owner.
/// 4. Signed out (a local-only family, or V1 data): the legacy Owner
///    fallback, as before accounts existed.
final actingMemberProvider = Provider<FamilyMember?>((ref) {
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  if (members.isEmpty) return null;
  final auth = ref.watch(authStateProvider);
  final pickId = ref.watch(activeMemberIdProvider);
  final pickUid = ref.watch(activeMemberPickUidProvider);
  // While auth is still resolving at launch, assume the account the pick
  // was made under — it's the one that was signed in last time.
  final uid = auth.isLoading ? pickUid : auth.valueOrNull?.uid;
  if (pickId != null && pickUid == uid) {
    final picked = members.where((m) => m.id == pickId).firstOrNull;
    if (picked != null) return picked;
  }
  if (uid != null) return members.where((m) => m.linkedUid == uid).firstOrNull;
  return members.firstWhere(
    (m) => m.role == FamilyRole.owner,
    orElse: () => members.first,
  );
});

/// [actingMemberProvider]'s id — what every "who did this" field records.
final actingMemberIdProvider = Provider<String?>((ref) {
  return ref.watch(actingMemberProvider)?.id;
});
