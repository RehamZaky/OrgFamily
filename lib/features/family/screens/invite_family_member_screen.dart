import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_invite_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/family_illustration.dart';
import 'manage_invites_screen.dart';

/// Generates a fresh invite code on open and shows it with Copy / Share —
/// the inviter's half of "Family invitations" (see docs/architecture.md).
/// Every visit mints a new code; older unused ones stay valid until they
/// expire or are revoked from [ManageInvitesScreen].
class InviteFamilyMemberScreen extends ConsumerStatefulWidget {
  const InviteFamilyMemberScreen({super.key});

  @override
  ConsumerState<InviteFamilyMemberScreen> createState() =>
      _InviteFamilyMemberScreenState();
}

class _InviteFamilyMemberScreenState
    extends ConsumerState<InviteFamilyMemberScreen> {
  late Future<FamilyInvite> _invite;
  final _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _invite = _createInvite();
  }

  Future<FamilyInvite> _createInvite() async {
    final familyId = ref.read(activeSyncFamilyIdProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (familyId == null || uid == null) {
      throw StateError('Invites need an active cloud-synced family');
    }
    // The inviter's own member row (the one linked to this account), not
    // currentMemberProvider — that's whichever profile is picked right
    // now, which could be a child's.
    final members = await ref.read(familyRepositoryProvider).getMembers();
    final inviterName = members
        .where((m) => m.linkedUid == uid)
        .map((m) => m.name)
        .firstOrNull;
    return ref
        .read(familyInviteRepositoryProvider)
        .createInvite(
          familyId: familyId,
          creatorUid: uid,
          inviterName: inviterName,
        );
  }

  void _retry() => setState(() => _invite = _createInvite());

  void _copy(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(
      ClipboardData(text: FamilyInviteRepository.formatCode(invite.code)),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.inviteCodeCopied)));
  }

  void _share(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    // iPad's share popover throws without an anchor rect.
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: l10n.inviteShareMessage(
          FamilyInviteRepository.formatCode(invite.code),
        ),
        subject: l10n.inviteShareSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final topInset = MediaQuery.paddingOf(context).top;
    const headerHeight = 190.0;
    const illustrationSize = 150.0;

    // Light status-bar icons over the dark header band, in either theme.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              _CurvedHeader(
                height: topInset + headerHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8, topInset + 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(color: Colors.white),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          top: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.inviteTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.inviteSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: topInset + headerHeight - illustrationSize * 0.45,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Column(
                  children: [
                    const FamilyIllustration(size: illustrationSize),
                    const SizedBox(height: 20),
                    FutureBuilder<FamilyInvite>(
                      future: _invite,
                      builder: (context, snapshot) => _InviteCodeCard(
                        snapshot: snapshot,
                        shareButtonKey: _shareButtonKey,
                        onCopy: _copy,
                        onShare: _share,
                        onRetry: _retry,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colors.textSecondary.withValues(alpha: 0.2)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(
                        Icons.group_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        l10n.manageInvites,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colors.textSecondary,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageInvitesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvedHeader extends StatelessWidget {
  const _CurvedHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppColors.primaryDeep,
        child: child,
      ),
    );
  }
}

/// A gentle downward bulge along the header's bottom edge.
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const dip = 28.0;
    return Path()
      ..lineTo(0, size.height - dip)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + dip,
        size.width,
        size.height - dip,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.snapshot,
    required this.shareButtonKey,
    required this.onCopy,
    required this.onShare,
    required this.onRetry,
  });

  final AsyncSnapshot<FamilyInvite> snapshot;
  final GlobalKey shareButtonKey;
  final void Function(FamilyInvite) onCopy;
  final void Function(FamilyInvite) onShare;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final invite = snapshot.data;
    final failed = snapshot.hasError;
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.inviteYourCode,
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 76),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: failed
                ? Column(
                    children: [
                      Text(
                        l10n.inviteCreateFailed,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      TextButton(onPressed: onRetry, child: Text(l10n.retry)),
                    ],
                  )
                : invite == null
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : SelectableText(
                    FamilyInviteRepository.formatCode(invite.code),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: invite == null ? null : () => onCopy(invite),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: Text(l10n.inviteCopyCode),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    shape: buttonShape,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: shareButtonKey,
                  onPressed: invite == null ? null : () => onShare(invite),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(l10n.inviteShare),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.accentCoral,
                    foregroundColor: Colors.white,
                    shape: buttonShape,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (invite != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.inviteExpiresInDays(invite.daysLeft),
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
