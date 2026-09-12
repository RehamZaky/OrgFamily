import '../../../data/local/database.dart';

/// Clamped to [0, 1] — a goal can be over-contributed to (e.g. a manual
/// correction) without the progress bar overflowing its track.
double progressFraction(SavingsGoal goal) {
  if (goal.targetCents <= 0) return 0;
  final fraction = goal.savedCents / goal.targetCents;
  return fraction.clamp(0, 1);
}

int remainingCents(SavingsGoal goal) {
  final remaining = goal.targetCents - goal.savedCents;
  return remaining < 0 ? 0 : remaining;
}
