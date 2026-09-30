import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The join flow's full-width primary button, with an in-place spinner
/// (and taps ignored) while [busy] — shared by `JoinFamilyScreen` and
/// `JoinFamilyConfirmScreen` so both steps look like one flow.
class JoinFlowButton extends StatelessWidget {
  const JoinFlowButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        // Keep the brand color while busy instead of Material's grey
        // disabled fill, so the spinner reads as "working", not "off".
        disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}
