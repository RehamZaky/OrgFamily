import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/tables/family_members_table.dart';
import '../../features/family/providers/family_providers.dart';

/// The role local permission checks (family_permissions.dart) use: the
/// [actingMemberProvider]'s role. See family_providers.dart for how the
/// acting member is resolved.
///
/// With no members at all (a fresh install mid-onboarding, or a restored
/// family still downloading) there's nobody to act as yet, and setting the
/// family up needs Owner rights. But with members present and no acting
/// member — a signed-in account with no linked profile — this is the most
/// restricted role, never the Owner: an unresolved identity must not quietly
/// gain the Owner's permissions, which is exactly how an invited adult used
/// to end up acting as the family Owner.
final activeRoleProvider = Provider<FamilyRole>((ref) {
  final acting = ref.watch(actingMemberProvider);
  if (acting != null) return acting.role;
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  return members.isEmpty ? FamilyRole.owner : FamilyRole.child;
});
