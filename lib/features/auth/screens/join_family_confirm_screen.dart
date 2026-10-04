import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_invite_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/screens/add_member_screen.dart';
import '../../family/widgets/family_illustration.dart';
import '../widgets/join_flow_button.dart';

/// "Join Reem's family?" — the last stop before an invite is actually
/// claimed, so a mistyped-but-valid code (someone else's family) can still
/// be backed out of. Claiming is single-use and irreversible, which is why
/// [JoinFamilyScreen] only looks the code up and this screen does the
/// claim. After claiming, the joiner sets up their own profile in
/// [AddMemberScreen] (`joinFamilyId` set), which is what creates this
/// device's local member row and starts sync.
class JoinFamilyConfirmScreen extends ConsumerStatefulWidget {
  const JoinFamilyConfirmScreen({super.key, required this.invite});

  final FamilyInvite invite;

  @override
  ConsumerState<JoinFamilyConfirmScreen> createState() =>
      _JoinFamilyConfirmScreenState();
}

class _JoinFamilyConfirmScreenState
    extends ConsumerState<JoinFamilyConfirmScreen> {
  late FamilyInvite _invite = widget.invite;
  bool _joining = false;
  String? _error;

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      setState(() => _error = l10n.joinErrorGeneric);
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    // Joining from Settings' "Not syncing this family" card happens on a
    // device that already has a family. Only an invite for *that* family
    // makes sense there — checked before claiming so a wrong code isn't
    // burned on a join that can't proceed.
    final localFamilyId = (await ref
            .read(familyProfileRepositoryProvider)
            .watchProfile()
            .first)
        ?.familyId;
    if (!mounted) return;
    if (localFamilyId != null && localFamilyId != _invite.familyId) {
      setState(() {
        _error = l10n.joinErrorOtherFamily;
        _joining = false;
      });
      return;
    }
    try {
      await ref.read(familyInviteRepositoryProvider).claimInvite(_invite, uid);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        // permission-denied on a code that looked usable moments ago means
        // someone else claimed it in between (or it just expired).
        _error = e.code == 'permission-denied'
            ? l10n.joinErrorUsed
            : l10n.joinErrorGeneric;
        _joining = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.joinErrorGeneric;
        _joining = false;
      });
      return;
    }
    // Remember the claim locally: if the joiner backs out of profile setup
    // and taps Join again, claimInvite must skip straight to the grant
    // rather than re-claim (which the rules would now deny).
    _invite = FamilyInvite(
      code: _invite.code,
      familyId: _invite.familyId,
      expiresAt: _invite.expiresAt,
      usedByUid: uid,
      inviterName: _invite.inviterName,
    );
    if (localFamilyId != null) {
      // This device already has the family and the account's own member
      // profile, so there's no profile to set up — just record the grant,
      // which is what lets sync start for this account.
      await ref.read(familyProfileRepositoryProvider).markJoined(uid);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(
          isFirstMember: true,
          joinFamilyId: _invite.familyId,
        ),
      ),
    );
    if (!mounted) return;
    // AddMemberScreen pops the same way whether it saved or was
    // cancelled. Once this device has a member, RootScaffold (the root
    // route) has already swapped from onboarding to the app itself — but
    // this screen and JoinFamilyScreen are still stacked on top of it, so
    // clear them rather than leave the joiner staring at "Join family?".
    final joined =
        (await ref.read(familyRepositoryProvider).getMembers()).isNotEmpty;
    if (!mounted) return;
    if (joined) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final name = _invite.inviterName?.trim();
    final hasName = name != null && name.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const FamilyIllustration(size: 180),
            const SizedBox(height: 28),
            Text(
              hasName
                  ? l10n.joinConfirmTitleNamed(name)
                  : l10n.joinConfirmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName
                              ? l10n.joinFamilyNamed(name)
                              : l10n.joinFamilyUnnamed,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.joinConfirmBody,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.priorityUrgent),
              ),
            ],
            const SizedBox(height: 32),
            JoinFlowButton(
              label: l10n.joinFamilyButton,
              busy: _joining,
              onPressed: _join,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _joining ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
