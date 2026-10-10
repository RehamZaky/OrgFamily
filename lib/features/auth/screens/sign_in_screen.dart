import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boxed_field.dart';
import '../../../data/local/tables/family_members_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import 'link_member_screen.dart';

/// Sign in / sign up with a Firebase account. Used two ways:
///  - Rendered inline by `RootScaffold` when there's no local family yet
///    (fresh install) — becoming the Owner happens right after, via
///    `AddMemberScreen(isFirstMember: true)`.
///  - Pushed from Settings, for an existing local family where an
///    Owner/Adult wants to link their own account (or an upgraded V1
///    install still has unlinked members).
///
/// After a successful sign-in/sign-up, if this device already has a local
/// family with members nobody's linked yet, this hands off to
/// [LinkMemberScreen] to ask "which of these are you?" rather than
/// assuming the signed-in person is a brand-new Owner — see
/// docs/architecture.md's "Family identity and authentication".
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _error;
  bool _restoring = false;
  bool _restoreFailed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maps Firebase's error codes to messages a non-technical user can act
  /// on — the raw messages (e.g. "The supplied auth credential is
  /// incorrect, malformed or has expired.") read as internal jargon.
  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'That email address doesn\'t look valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'That password is too weak — use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        await auth.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      await _afterSignedIn();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await _afterSignedIn();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?" again.');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e));
    }
  }

  /// After a real sign-in, figures out whether this device's local family
  /// (if any) already knows who this is. If there's an existing,
  /// still-unlinked family, hands off to the "which of these are you?"
  /// picker instead of assuming a fresh Owner sign-up — see
  /// FamilyRepository.linkMember/watchUnlinkedAdults.
  Future<void> _afterSignedIn() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null || !mounted) return;
    final members = await ref.read(familyRepositoryProvider).getMembers();
    if (members.isEmpty && isFirebaseAuthSupportedPlatform) {
      final restored = await _restoreExistingFamily(uid);
      // null: the lookup failed — stay here (with a retry) rather than let
      // the caller go on to create a duplicate family for this account.
      if (restored == null || !mounted) return;
      if (restored) {
        Navigator.of(context).maybePop();
        return;
      }
    }
    final linkedMember = members.where((m) => m.linkedUid == uid).firstOrNull;
    final hasUnlinkedAdults =
        members.any((m) => m.role != FamilyRole.child && m.linkedUid == null);
    if (!mounted) return;
    if (linkedMember == null && members.isNotEmpty && hasUnlinkedAdults) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LinkMemberScreen()),
      );
      return;
    }
    // Already-linked adult signing back in on this device — default the
    // local profile picker to them (see actingMemberProvider).
    if (linkedMember != null) await setActiveMember(ref, linkedMember.id);
    if (mounted) Navigator.of(context).maybePop();
  }

  /// A fresh device (no local family) signed in as an account that already
  /// belongs to a cloud family — e.g. a member's second phone: brings that
  /// family down instead of starting a new one, with no new invite needed
  /// (membership belongs to the account, not the device). Returns whether
  /// a family was restored, or null if Firestore couldn't be asked.
  Future<bool?> _restoreExistingFamily(String uid) async {
    setState(() {
      _restoring = true;
      _restoreFailed = false;
      _error = null;
    });
    try {
      final found = await ref.read(cloudMembershipRepositoryProvider).findFamily(uid);
      if (found == null) return false;
      final family = ref.read(familyRepositoryProvider);
      await ref.read(familyProfileRepositoryProvider).recordRestore(
            familyId: found.familyId,
            uid: uid,
            isOwner: found.ownerUid == uid,
          );
      // Sync's first pass downloads the family; once this account's own
      // member arrives, make it the active profile. If that's slow, the
      // app still opens (on the Owner by default) and catches up.
      final me = await family
          .watchMembers()
          .map((members) => members.where((m) => m.linkedUid == uid).firstOrNull)
          .firstWhere((m) => m != null)
          .timeout(const Duration(seconds: 20), onTimeout: () => null);
      if (me != null) await setActiveMember(ref, me.id);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.restoreFamilyError;
          _restoreFailed = true;
        });
      }
      return null;
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const ClipOval(
                            child: Image(
                              image: AssetImage('assets/onboarding/family.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSignUp ? 'Create your account' : 'Welcome back',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Adults sign in with their own account.\nKids keep using local profiles — no login needed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  BoxedField(
                    label: 'Email',
                    verticalPadding: 10,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BoxedField(
                    label: 'Password',
                    verticalPadding: 10,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                  ),
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  if (_restoring) ...[
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.restoreFamilyChecking),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.priorityUrgent)),
                  ],
                  if (_restoreFailed)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _restoring ? null : _afterSignedIn,
                        child: Text(AppLocalizations.of(context)!.restoreFamilyRetry),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitEmail,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(_isSignUp ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _submitGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    icon: SvgPicture.asset('assets/icons/google_logo.svg', width: 18, height: 18),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                    child: Text(_isSignUp
                        ? 'Already have an account? Sign in'
                        : "New here? Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
