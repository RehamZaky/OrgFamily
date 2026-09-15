import 'package:flutter/material.dart';

/// A labeled field with a visible border — used instead of the app-wide
/// borderless [InputDecorationTheme] (which fills with `colors.background`,
/// so it blends into a plain `Scaffold` body with no surface behind it)
/// wherever a form sits directly on the scaffold rather than inside a Card.
class BoxedField extends StatelessWidget {
  const BoxedField({
    super.key,
    required this.label,
    required this.child,
    this.verticalPadding = 14,
  });

  final String label;
  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ],
    );
  }
}
