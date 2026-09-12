import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/enum_display.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/family_members_table.dart';
import '../../../data/providers.dart';
import '../../tasks/providers/task_providers.dart';

const _activeMemberIdPrefsKey = 'active_member_id';

/// Which family member the app is currently "acting as" — a soft, local
/// profile switcher (see the drawer), not authentication: nothing stops
/// anyone from switching back. Restored on launch by
/// [loadPersistedActiveMemberId] (called from main.dart before the widget
/// tree is built) and updated by [setActiveMember] whenever someone picks a
/// different profile. Null means "no explicit pick" — [currentMemberProvider]
/// then falls back to the Owner, same as if this provider didn't exist.
final activeMemberIdProvider = StateProvider<String?>((ref) => null);

Future<String?> loadPersistedActiveMemberId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_activeMemberIdPrefsKey);
}

/// Switches the active profile and persists the choice — call this rather
/// than writing [activeMemberIdProvider] directly, so the pick survives an
/// app restart. Pass null to clear back to "no explicit pick" (Owner).
Future<void> setActiveMember(WidgetRef ref, String? memberId) async {
  ref.read(activeMemberIdProvider.notifier).state = memberId;
  final prefs = await SharedPreferences.getInstance();
  if (memberId == null) {
    await prefs.remove(_activeMemberIdPrefsKey);
  } else {
    await prefs.setString(_activeMemberIdPrefsKey, memberId);
  }
}

final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(familyRepositoryProvider).watchMembers();
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

/// The member treated as "you" — for greetings, defaults, AND permission
/// checks (see activeRoleProvider in core/permissions), so switching
/// profiles in the drawer changes both at once rather than leaving them
/// out of sync. Prefers whoever [activeMemberIdProvider] points at; falls
/// back to the family owner (or the first member, if no owner is set yet)
/// when nothing's been explicitly picked, or the pick refers to a member
/// that's since been deleted.
final currentMemberProvider = Provider<FamilyMember?>((ref) {
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  if (members.isEmpty) return null;
  final activeId = ref.watch(activeMemberIdProvider);
  if (activeId != null) {
    final active = members.where((m) => m.id == activeId).firstOrNull;
    if (active != null) return active;
  }
  return members.firstWhere(
    (m) => m.role == FamilyRole.owner,
    orElse: () => members.first,
  );
});
