import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boxed_field.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_invite_repository.dart';
import '../../family/screens/add_member_screen.dart';
import 'sign_in_screen.dart';

/// "Enter the code someone in your family sent you" — the entry point for
/// a second real adult, on their own fresh device, to join an existing
/// family's cloud data instead of starting a brand-new one. See
/// docs/architecture.md "Family invitations" for the full design: this
/// screen only looks up and claims the code (via
/// [FamilyInviteRepository]); the actual local join (creating this
/// device's own [FamilyMember] row and calling
/// `FamilyProfileRepository.recordJoin`) happens right after, in
/// [AddMemberScreen] with `joinFamilyId` set.
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      // Joining needs a real account of its own — a fresh device has none
      // yet, so ask for one first, same as OnboardingScreen's own
      // "add yourself" path does for a brand-new Owner.
      if (isFirebaseAuthSupportedPlatform &&
          ref.read(authRepositoryProvider).currentUser == null) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (!mounted) return;
      if (uid == null) {
        setState(() => _joining = false);
        return;
      }
      final invites = ref.read(familyInviteRepositoryProvider);
      final invite = await invites.lookupInvite(code);
      if (invite == null) {
        setState(() {
          _error = "That code doesn't match any invite. Double-check it and try again.";
          _joining = false;
        });
        return;
      }
      if (invite.isUsed) {
        setState(() {
          _error = 'This invite has already been used. Ask them to send you a new one.';
          _joining = false;
        });
        return;
      }
      if (invite.isExpired) {
        setState(() {
          _error = 'This invite has expired. Ask them to send you a new one.';
          _joining = false;
        });
        return;
      }
      await invites.claimInvite(invite, uid);
      if (!mounted) return;
      // Must be push, not pushReplacement — this screen isn't its own
      // route underneath OnboardingScreen either, so replacing it would
      // leave AddMemberScreen's Navigator.pop(), after saving, with
      // nothing left to pop back to. See OnboardingScreen._addYourself's
      // identical note.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddMemberScreen(isFirstMember: true, joinFamilyId: invite.familyId),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please check your connection and try again.';
          _joining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a family')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Enter the invite code another adult in your family sent you. "
              "You'll join their existing tasks, events, and shopping lists.",
            ),
            const SizedBox(height: 16),
            BoxedField(
              label: 'Invite code',
              child: TextField(
                controller: _codeController,
                enabled: !_joining,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'e.g. 7K9XQPRT',
                ),
                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.priorityUrgent)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _joining ? null : _join,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _joining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join family'),
            ),
          ],
        ),
      ),
    );
  }
}
