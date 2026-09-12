import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/providers.dart';

final allGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(savingsGoalRepositoryProvider).watchGoals();
});

/// Sum of every goal's saved amount — the Money Overview screen's Savings
/// summary card, distinct from income-minus-expenses.
final totalSavedCentsProvider = Provider<int>((ref) {
  final goals = ref.watch(allGoalsProvider).valueOrNull ?? [];
  return goals.fold(0, (sum, g) => sum + g.savedCents);
});
