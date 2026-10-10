import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The round family portrait heading the invite and join screens — a
/// pre-cropped circle of `family.png` (the onboarding art) inside a soft
/// lavender ring, so it reads the same on light and dark backgrounds.
class FamilyIllustration extends StatelessWidget {
  const FamilyIllustration({super.key, this.size = 170});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.035),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryLight.withValues(alpha: 0.35),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/onboarding/family_circle.png',
            fit: BoxFit.cover,
            // Decorative — every screen using it has a text title saying
            // what the screen is for.
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
