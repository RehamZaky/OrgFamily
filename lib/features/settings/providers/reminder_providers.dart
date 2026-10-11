import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/tables/family_members_table.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../family/providers/family_providers.dart';

/// The signed-in account's uid; null when signed out.
final signedInUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Whose reminders this phone keeps (V2.2): the signed-in account's own
/// profile — or, in an all-local family nobody is signed in to, the family
/// Owner's. **Never the acting profile**: Kareem switching into Omar's
/// profile to look at his chores must not start (or cancel) Omar's
/// reminders on Kareem's phone. Scheduling reminders for several profiles
/// on a shared family device would be an explicit option (and V3's child
/// devices have their own).
final reminderOwnerProvider = Provider<FamilyMember?>((ref) {
  if (ref.watch(signedInUidProvider) != null) return ref.watch(authenticatedMemberProvider);
  final members = ref.watch(familyMembersProvider).valueOrNull ?? const <FamilyMember>[];
  return members.where((m) => m.role == FamilyRole.owner).firstOrNull;
});

/// This phone's reminder choices — [reminderOwnerProvider]'s.
final phoneReminderPreferencesProvider = Provider<ReminderPreferences>((ref) {
  return ref.watch(reminderPreferencesProvider(ref.watch(reminderOwnerProvider)?.id));
});
