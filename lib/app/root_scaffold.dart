import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions/active_profile_provider.dart';
import '../core/permissions/family_permissions.dart';
import '../core/theme/app_color_scheme.dart';
import '../core/widgets/banner_ad_widget.dart';
import '../data/backup/money_backup_providers.dart';
import '../data/providers.dart';
import '../features/budget/screens/money_overview_screen.dart';
import '../features/budget/widgets/add_transaction_sheet.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/dashboard/screens/home_screen.dart';
import '../features/family/providers/family_providers.dart';
import '../features/family/screens/family_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/quick_add/quick_add_sheet.dart';
import '../features/shopping/screens/shopping_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/tasks/widgets/quick_add_task_sheet.dart';
import '../l10n/app_localizations.dart';

class RootScaffold extends ConsumerStatefulWidget {
  const RootScaffold({super.key});

  @override
  ConsumerState<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends ConsumerState<RootScaffold>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Starts/stops SyncEngine as sign-in/link state changes — fireImmediately
    // so a fresh app boot that's already linked resumes syncing right away,
    // not just at the moment recordLink itself runs. See
    // docs/architecture.md "Firestore sync".
    ref.listenManual(activeSyncProvider, (previous, next) {
      final sync = ref.read(syncEngineProvider);
      if (next != null) {
        sync.start(next.familyId, next.uid);
        _maybeBackUpMoney();
      } else {
        sync.stop();
      }
    }, fireImmediately: true);
    // Changes made while not syncing are still queued (held for review),
    // tagged with whoever was signed in — see SyncEngine.enqueueUpsert.
    ref.listenManual(authStateProvider, (previous, next) {
      ref.read(syncEngineProvider).setSignedInUid(next.valueOrNull?.uid);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A proxy for "reconnect" without a dedicated connectivity dependency —
    // Firestore's own listeners resume on their own, but a queued outbox
    // row's retry backoff can be sitting well past due if the app was
    // backgrounded for a while, so give it an immediate nudge on resume
    // rather than waiting for its scheduled retry.
    if (state == AppLifecycleState.resumed) {
      final sync = ref.read(syncEngineProvider);
      unawaited(sync.drainNow());
      sync.reconnectNow();
      _maybeBackUpMoney();
    }
  }

  /// The automatic daily Money backup — the Owner's phone only, and only
  /// while syncing as them (see MoneyAutoBackup).
  void _maybeBackUpMoney() {
    final active = ref.read(activeSyncProvider);
    final ownerUid = ref.read(familyProfileStreamProvider).valueOrNull?.ownerUid;
    if (active == null || ownerUid != active.uid) return;
    unawaited(ref
        .read(moneyAutoBackupProvider)
        .runIfDue(familyId: active.familyId, uid: active.uid));
  }

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => HomeScreen(
        onViewTasks: () => setState(() => _index = 1),
        onViewEvents: () => setState(() => _index = 2),
        onViewLists: () => setState(() => _index = 3),
      ),
      1 => const TasksScreen(),
      2 => const CalendarScreen(),
      3 => const ShoppingScreen(),
      4 => const FamilyScreen(),
      _ => const MoneyOverviewScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(familyMembersProvider);

    // While there's no family yet, show the onboarding flow full-screen —
    // it must not sit inside this Scaffold, or its own bottom nav bar and
    // "+" FAB bleed through underneath the onboarding UI.
    if (membersAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if ((membersAsync.valueOrNull ?? []).isEmpty &&
        ref.watch(familyProfileStreamProvider).valueOrNull?.familyId != null) {
      // A restored cloud family (a member's new phone, see SignInScreen)
      // whose members haven't downloaded yet — not a fresh install, so
      // don't offer to create a new family while it arrives.
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.restoreFamilyChecking),
            ],
          ),
        ),
      );
    }
    if ((membersAsync.valueOrNull ?? []).isEmpty) {
      // Fresh install, no local family at all: show the intro slides
      // first. Sign-in (on a platform that supports it) and creating the
      // first Owner both happen at the end of that flow — see
      // OnboardingScreen's `_addYourself`.
      return const OnboardingScreen();
    }

    // Finances are Owner/Adult only — Child profiles never see the Money
    // tab. If the active profile switches to Child while it's open, fall
    // back to Home rather than leaving a Child looking at a screen it can
    // no longer navigate to.
    final canViewFinances = canPerform(
      ref.watch(activeRoleProvider),
      FamilyAction.viewFinances,
    );
    if (_index == 5 && !canViewFinances) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 0);
      });
    }

    // Ads sit above the bottom nav on the browsing-heavy tabs — not on
    // Tasks/Lists, which are already dense with actionable content. Home
    // shows its own banner inline (between Upcoming and Family Activity)
    // instead of pinned here.
    final showBanner = _index == 2 || _index == 4 || _index == 5;

    Widget navItem(int index, IconData icon, String label) => Expanded(
          child: _NavItem(
            icon: icon,
            label: label,
            selected: _index == index,
            onTap: () => setState(() => _index = index),
          ),
        );
    final navItems = [
      navItem(0, Icons.home_rounded, l10n.navHome),
      navItem(1, Icons.check_circle_outline, l10n.navTasks),
      navItem(2, Icons.calendar_today_outlined, l10n.navCalendar),
      navItem(3, Icons.checklist_rounded, l10n.navLists),
      navItem(4, Icons.people_alt_outlined, l10n.navFamily),
      if (canViewFinances)
        navItem(5, Icons.account_balance_wallet_outlined, l10n.navBudget),
    ];
    final split = navItems.length ~/ 2;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildScreen(_index)),
          if (showBanner) const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'root_quick_add',
        // On the Tasks tab, the global "+" jumps straight to Quick Task,
        // and on the Money tab it jumps straight to Add Transaction,
        // instead of the generic type-picker sheet, since that's the only
        // thing worth quick-adding from a screen already about that type.
        onPressed: () => switch (_index) {
          1 => showQuickAddTaskSheet(context),
          5 => showAddTransactionSheet(context),
          _ => showQuickAddSheet(context),
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        // Transparent in light; a hairline in dark, where the bar shares the
        // page background instead of standing out as its own surface.
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.navDivider)),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: context.colors.navBackground,
          surfaceTintColor: Colors.transparent,
          // Tabs split into two equal-width halves around a gap the size of
          // the docked FAB, so the gap — and the FAB's notch — stays centered
          // whether Money is shown (3 + 3) or not (2 + 3). A single row with
          // a gap after the second tab put the FAB on top of Calendar.
          child: Row(
            children: [
              Expanded(child: Row(children: navItems.sublist(0, split))),
              const SizedBox(width: _fabGapWidth),
              Expanded(child: Row(children: navItems.sublist(split))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Docked FAB diameter (56) plus `notchMargin` (8) on each side.
const double _fabGapWidth = 72;

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.accent
        : context.colors.textSecondary;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
