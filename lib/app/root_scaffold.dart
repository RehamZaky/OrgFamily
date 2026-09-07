import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_color_scheme.dart';
import '../core/theme/app_colors.dart';
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

class _RootScaffoldState extends ConsumerState<RootScaffold> {
  int _index = 0;

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
      _ => const FamilyScreen(),
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
    if ((membersAsync.valueOrNull ?? []).isEmpty) {
      return const OnboardingScreen();
    }

    return Scaffold(
      body: _buildScreen(_index),
      floatingActionButton: FloatingActionButton(
        heroTag: 'root_quick_add',
        // On the Tasks tab, the global "+" jumps straight to Quick Task
        // instead of the generic type-picker sheet, since that's the only
        // thing worth quick-adding from a screen already about tasks.
        onPressed: () => _index == 1
            ? showQuickAddTaskSheet(context)
            : showQuickAddSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: context.colors.surface,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.check_circle_outline,
                label: l10n.navTasks,
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: _NavItem(
                icon: Icons.calendar_today_outlined,
                label: l10n.navCalendar,
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.checklist_rounded,
                label: l10n.navLists,
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.people_alt_outlined,
                label: l10n.navFamily,
                selected: _index == 4,
                onTap: () => setState(() => _index = 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final color = selected ? AppColors.primary : context.colors.textSecondary;
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
