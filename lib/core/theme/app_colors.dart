import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFB9A9FF);
  static const primaryDark = Color(0xFF5541D6);

  static const background = Color(0xFFF6F5FA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1F1B33);
  static const textSecondary = Color(0xFF8B87A0);

  static const priorityUrgent = Color(0xFFE84C4C);
  static const priorityHigh = Color(0xFFE84C4C);
  static const priorityNormal = Color(0xFFFF9F43);
  static const priorityLow = Color(0xFF8B87A0);

  // Task-priority chip colors specifically (distinct from `priorityNormal`/
  // `priorityHigh` above, which are reused elsewhere as generic orange/red
  // accents unrelated to task priority — e.g. delete buttons, other icons —
  // so changing those values would have unintended knock-on effects).
  static const taskPriorityNormal = Color(0xFF34C471);
  static const taskPriorityHigh = Color(0xFFFF9F43);
  static const success = Color(0xFF34C471);
  static const info = Color(0xFF5B8DEF);

  static const eventPalette = [
    Color(0xFF8E7CFF), // purple
    Color(0xFFE8749B), // pink
    Color(0xFF5B8DEF), // blue
    Color(0xFF34C471), // green
    Color(0xFFFF9F43), // orange
    Color(0xFF00B4D8), // cyan
  ];

  static const avatarPalette = [
    Color(0xFF6C5CE7),
    Color(0xFFE8749B),
    Color(0xFF5B8DEF),
    Color(0xFF34C471),
    Color(0xFFFF9F43),
    Color(0xFF00B4D8),
  ];

  /// Fixed palette for quick notes — pastel fills work as a sticky-note
  /// background (unlike avatarPalette's saturated colors, which are tuned
  /// to sit behind white/emoji foreground content instead).
  static const notePalette = [
    Color(0xFFFFF3B0),
    Color(0xFFFFD6E0),
    Color(0xFFC8F4DE),
    Color(0xFFC9E4FF),
    Color(0xFFE3D9FF),
    Color(0xFFFFE0C2),
  ];
}
