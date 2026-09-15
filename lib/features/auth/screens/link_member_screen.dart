import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/family_members_table.dart';
import '../../../data/providers.dart';
import '../../family/providers/family_providers.dart';

/// "Which of these are you?" — shown right after a sign-in that happened
/// on a device with an existing, still-unlinked local family (a V1
/// install upgrading to V2 Auth). Links the chosen member to the
/// signed-in Firebase uid; never creates a new member, so the existing
/// family is preserved exactly as-is. See
/// docs/architecture.md's "Family identity and authentication".
class LinkMemberScreen extends ConsumerStatefulWidget {
  const LinkMemberScreen({super.key});

  @override
  ConsumerState<LinkMemberScreen> createState() => _LinkMemberScreenState();
}

class _LinkMemberScreenState extends ConsumerState<LinkMemberScreen> {
  bool _linking = false;

  Future<void> _link(FamilyMember member) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    setState(() => _linking = true);
    await ref.read(familyRepositoryProvider).linkMember(member.id, uid);
    await ref.read(familyProfileRepositoryProvider).recordLink(
          uid: uid,
          isOwner: member.role == FamilyRole.owner,
        );
    await setActiveMember(ref, member.id);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(unlinkedAdultMembersProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Which of these are you?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "This device already has a family set up. Pick your profile to "
              "link it to the account you just signed in with — everything "
              "stays exactly as it is, nothing gets recreated.",
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            for (final member in candidates)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: MemberAvatar(member: member),
                  title: Text(member.name),
                  subtitle: Text(member.role.label),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_linking,
                  onTap: () => _link(member),
                ),
              ),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No unlinked members left — everyone in this family already has an account.',
                    style: TextStyle(color: AppColors.priorityLow),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
