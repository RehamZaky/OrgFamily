import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The "nothing here" animation shown above empty-state copy across the
/// app (empty task/event lists, no search results), replacing plain
/// static icons.
class NoResultsAnimation extends StatelessWidget {
  const NoResultsAnimation({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/no_result_found.json',
      width: size,
      height: size,
      // Looping by default means widget tests' pumpAndSettle() — which
      // waits for all animations to finish — hangs forever on any screen
      // that renders an empty state.
      repeat: false,
    );
  }
}
