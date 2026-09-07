import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';

/// Icon-in-circle + label + value row, optionally divided from siblings by
/// a [Divider] inside a shared card. Used both for read-only summaries and,
/// with [onTap] set, as a tappable field that opens a picker — the trailing
/// chevron only appears in that case, so a purely informational row and an
/// editable one are still visually distinguishable.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.valueText,
    this.child,
    this.onTap,
  }) : assert(valueText != null || child != null);

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? valueText;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          const Spacer(),
          child ??
              Text(
                valueText!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: context.colors.textSecondary),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// The rounded, shadowed card [DetailRow]s are typically grouped inside.
class DetailRowCard extends StatelessWidget {
  const DetailRowCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
