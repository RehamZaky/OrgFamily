import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_invite_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/widgets/family_illustration.dart';
import '../widgets/join_flow_button.dart';
import 'join_family_confirm_screen.dart';
import 'sign_in_screen.dart';

/// "Enter the code someone in your family sent you" — the entry point for
/// a second real adult, on their own fresh device, to join an existing
/// family's cloud data instead of starting a brand-new one. See
/// docs/architecture.md "Family invitations" for the full design: this
/// screen only looks the code up (via [FamilyInviteRepository]) and
/// rejects unusable ones; claiming it happens only once the joiner
/// confirms on [JoinFamilyConfirmScreen].
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text;
    if (FamilyInviteRepository.normalizeCode(code).isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      // Joining needs a real account of its own — a fresh device has none
      // yet, so ask for one first, same as OnboardingScreen's own
      // "add yourself" path does for a brand-new Owner. Looking a code up
      // needs one too (`firestore.rules` denies an anonymous get).
      if (isFirebaseAuthSupportedPlatform &&
          ref.read(authRepositoryProvider).currentUser == null) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
      }
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (!mounted) return;
      if (uid == null) {
        setState(() => _checking = false);
        return;
      }
      final invite = await ref
          .read(familyInviteRepositoryProvider)
          .lookupInvite(code);
      if (!mounted) return;
      // Already claimed by this same account means an earlier attempt got
      // partway (backed out of profile setup, or the grant write failed)
      // — let it through so JoinFamilyConfirmScreen can finish the job.
      final error = invite == null
          ? l10n.joinErrorNotFound
          : invite.isUsed && invite.usedByUid != uid
          ? l10n.joinErrorUsed
          : invite.isExpired
          ? l10n.joinErrorExpired
          : null;
      setState(() {
        _error = error;
        _checking = false;
      });
      if (error != null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JoinFamilyConfirmScreen(invite: invite!),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = l10n.joinErrorGeneric;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

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
              l10n.joinFamilyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.joinEnterCode,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              enabled: !_checking,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _continue(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'ABCD-2345',
                hintStyle: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
                filled: true,
                fillColor: context.colors.accent.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                enabledBorder: border(
                  context.colors.accent.withValues(alpha: 0.45),
                ),
                disabledBorder: border(
                  context.colors.accent.withValues(alpha: 0.25),
                ),
                focusedBorder: border(context.colors.accent, 1.8),
                errorBorder: border(context.colors.danger),
                focusedErrorBorder: border(context.colors.danger, 1.8),
                errorText: _error,
                errorMaxLines: 3,
                helperText: l10n.joinCodeHelper,
                helperStyle: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 28),
            JoinFlowButton(
              label: l10n.joinContinue,
              busy: _checking,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
