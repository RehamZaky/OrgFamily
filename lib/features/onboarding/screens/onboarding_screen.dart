import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/join_family_screen.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../family/screens/add_member_screen.dart';

/// The four marketing screens are supplied as ready-made artwork (English
/// and Arabic versions, picked by the device's system language) and shown
/// exactly as designed — full-bleed, no native chrome drawn on top of them.
/// The final "let's set up your family" page is built natively and, on a
/// platform that supports it, requires signing in first — see
/// `_addYourself` — before AddMemberScreen(isFirstMember: true) can create
/// that first Owner (docs/architecture.md "Family identity and
/// authentication").
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _imagePageCount = 4;
  static const _pageCount = _imagePageCount + 1;

  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLastPage() {
    _controller.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _addYourself() async {
    // On a platform that supports it, the first Owner has to authenticate
    // before AddMemberScreen(isFirstMember: true) can link their Firebase
    // uid to that member — see docs/architecture.md "Family identity and
    // authentication". Desktop skips straight to setup, same as before V2
    // Auth existed.
    if (isFirebaseAuthSupportedPlatform &&
        ref.read(authRepositoryProvider).currentUser == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      // authStateProvider is a StreamProvider — reading it here instead of
      // the synchronous `currentUser` getter risks an AsyncLoading value on
      // its very first watch (nothing else watches it on this fresh-install
      // path), which would misread a successful sign-in as failed.
      if (!mounted || ref.read(authRepositoryProvider).currentUser == null) {
        return;
      }
      // Signing in restored an existing cloud family for this account (a
      // member's new phone) — there's no first member to create, even if
      // the download hasn't delivered the members yet.
      final profile = await ref.read(familyProfileRepositoryProvider).watchProfile().first;
      if (profile?.familyId != null) return;
    }
    // Must be push, not pushReplacement: OnboardingScreen isn't a separate
    // route (RootScaffold renders it inline as the app's one and only
    // route while there's no family yet), so replacing it here would leave
    // AddMemberScreen's Navigator.pop(), after saving, with no route left
    // to pop back to — a black screen. Pushing keeps that route underneath,
    // and once the first member is saved RootScaffold reactively swaps
    // itself from onboarding to the normal tab shell once popped back to.
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddMemberScreen(isFirstMember: true),
      ),
    );
  }

  /// The alternative to [_addYourself] for a second real adult whose
  /// family already exists in the cloud — see docs/architecture.md
  /// "Family invitations". Not platform-gated the way [_addYourself]'s
  /// sign-in step is: joining is meaningless without Firebase at all, so
  /// this button only appears when `isFirebaseAuthSupportedPlatform`
  /// (see `_SetupPage` below).
  void _joinFamily() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang =
        Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            children: [
              for (var i = 1; i <= _imagePageCount; i++)
                _OnboardingImagePage(
                  assetPath: 'assets/onboarding/$lang/page$i.webp',
                  onTap: _next,
                  onSkip: _goToLastPage,
                ),
              _SetupPage(l10n: l10n, onAddYourself: _addYourself, onJoinFamily: _joinFamily),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the four supplied illustrations, shown edge-to-edge. Tapping
/// anywhere advances to the next page — the artwork already has its own
/// "Next"/"Get Started" graphic drawn in, so the whole page acting as that
/// button means it works regardless of exactly where that graphic sits.
class _OnboardingImagePage extends StatelessWidget {
  const _OnboardingImagePage({
    required this.assetPath,
    required this.onTap,
    required this.onSkip,
  });

  final String assetPath;
  final VoidCallback onTap;

  /// The artwork has a "Skip" drawn in its top corner; this invisible tap
  /// area sits over it. It lives inside the artwork's own frame (not over
  /// the whole screen) so it moves with the artwork and always lines up.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: context.colors.background,
        // Kept clear of the status bar and given breathing room top and
        // bottom — edge-to-edge, the drawn "Skip" sat against the status bar.
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('onboardingSkip'),
                      onTap: onSkip,
                      child: const SizedBox(width: 120, height: 88),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one page that isn't supplied artwork — it has to actually add the
/// first family member, so it's built natively.
class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.l10n,
    required this.onAddYourself,
    required this.onJoinFamily,
  });

  final AppLocalizations l10n;
  final VoidCallback onAddYourself;
  final VoidCallback onJoinFamily;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.accent.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/onboarding/family.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.onboardingPage5Title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingPage5Body,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                FilledButton(
                  onPressed: onAddYourself,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(l10n.onboardingAddYourself),
                ),
                // Only meaningful once there's a cloud family to join at
                // all — desktop never initializes Firebase, so there's
                // nothing for this to join. See docs/architecture.md
                // "Family invitations".
                if (isFirebaseAuthSupportedPlatform)
                  TextButton(
                    onPressed: onJoinFamily,
                    child: const Text('Join an existing family instead'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
