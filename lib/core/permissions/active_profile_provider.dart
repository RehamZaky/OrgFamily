import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/tables/family_members_table.dart';
import '../../features/family/providers/family_providers.dart';

/// The role [currentMemberProvider] resolves to right now, for the
/// permission checks in family_permissions.dart — Owner if there are no
/// family members yet. See family_providers.dart for how "you" is picked
/// (the drawer's profile switcher, via [activeMemberIdProvider]) and how it
/// falls back (to the family Owner) when nothing's been explicitly chosen.
final activeRoleProvider = Provider<FamilyRole>((ref) {
  return ref.watch(currentMemberProvider)?.role ?? FamilyRole.owner;
});
