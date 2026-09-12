import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format_x.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../budget/providers/budget_providers.dart' show currencyCodeProvider;
import '../../family/providers/family_providers.dart' show activeMemberIdProvider;
import '../domain/savings_goal_calculator.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/add_goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currencyCodeProvider);
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddGoalSheet(context),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.savings_outlined, size: 48, color: context.colors.textSecondary),
                    const SizedBox(height: 12),
                    Text(l10n.noGoalsYet, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(l10n.goalsEmptyHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const _GoalsHero(),
              const SizedBox(height: 20),
              for (final goal in goals) _GoalCard(goal: goal, currencyCode: currencyCode),
            ],
          );
        },
      ),
    );
  }
}

/// Motivational banner topping the goals list — copy on the left, the
/// treasure chest illustration on the right, inside a tinted card. A static
/// illustration rather than another goal card, so the screen has some
/// warmth before the first goal is even added. Falls back to a plain icon
/// if the illustration asset hasn't been dropped into assets/illustrations/
/// yet.
class _GoalsHero extends StatelessWidget {
  const _GoalsHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalsBanner,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, height: 1.15),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.goalsBannerSubtitle,
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/illustrations/treasure_chest.png',
            width: 120,
            height: 120,
            errorBuilder: (_, _, _) => Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Highest 25%-multiple milestone reached by [fraction] — 0 if under 25%.
/// Used to detect whether a contribution just crossed a new milestone worth
/// celebrating, rather than firing on every single contribution.
int _milestoneTier(double fraction) => ((fraction * 100) ~/ 25) * 25;

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.currencyCode});

  final SavingsGoal goal;
  final String currencyCode;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(savingsGoalRepositoryProvider).deleteGoal(
          goal.id,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );
  }

  Future<void> _showContributeDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.contribute),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          decoration: InputDecoration(labelText: l10n.contributeAmount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(double.tryParse(controller.text)),
            child: Text(l10n.contribute),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    if (!context.mounted || !checkPermission(context, ref, FamilyAction.manageSavingsGoals)) {
      return;
    }

    final amountCents = (amount * 100).round();
    final oldTier = _milestoneTier(progressFraction(goal));
    final newSavedCents = (goal.savedCents + amountCents).clamp(0, goal.targetCents);
    final newFraction = goal.targetCents <= 0 ? 0.0 : newSavedCents / goal.targetCents;
    final newTier = _milestoneTier(newFraction);

    await ref.read(savingsGoalRepositoryProvider).contribute(
          goal.id,
          amountCents,
          actingRole: ref.read(activeRoleProvider),
          actingMemberId: ref.read(activeMemberIdProvider),
        );

    if (!context.mounted || newTier <= oldTier || newTier <= 0) return;
    unawaited(_showCelebration(context, l10n.goalCelebrationMessage(
      formatCents(amountCents, currencyCode: currencyCode),
    )));
  }

  Future<void> _showCelebration(BuildContext context, String message) async {
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (_) => _GoalCelebration(message: message),
    );
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (context.mounted) Navigator.of(context, rootNavigator: true).maybePop();
    });
    await dialogFuture;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fraction = progressFraction(goal);
    final remaining = remainingCents(goal);
    final isCompleted = remaining <= 0;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (!checkPermission(context, ref, FamilyAction.manageSavingsGoals)) return false;
        return true;
      },
      onDismissed: (_) => _delete(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showAddGoalSheet(context, existing: goal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: goal.icon.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(goal.icon.icon, size: 20, color: goal.icon.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCents(goal.savedCents, currencyCode: currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    '${(fraction * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isCompleted ? AppColors.success : context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    isCompleted ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.goalOfTarget(formatCents(goal.targetCents, currencyCode: currencyCode)),
                    style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                  ),
                  if (goal.targetDate != null)
                    Text(
                      l10n.goalTargetDateLabel(goal.targetDate!.shortDate),
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: isCompleted
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              l10n.goalCompleted,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextButton(
                        onPressed: () => _showContributeDialog(context, ref),
                        child: Text(l10n.contribute),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brief full-screen celebration shown when a contribution crosses a new
/// 25% milestone — auto-dismisses itself, so callers don't need to manage
/// a timer or navigator state.
class _GoalCelebration extends StatelessWidget {
  const _GoalCelebration({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/goal_celebration.json',
            width: 180,
            height: 180,
            repeat: false,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.celebration, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
