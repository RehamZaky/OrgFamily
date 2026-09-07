import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Maps a shopping list's stored emoji to a pastel icon + color pair,
/// matching the rest of the app's icon language instead of raw emoji.
/// Falls back to a generic list icon for anything outside the picker's
/// fixed emoji set.
(IconData, Color) listIconFor(String emoji) => switch (emoji) {
      '🛒' => (Icons.shopping_cart_rounded, AppColors.avatarPalette[0]),
      '🏖️' => (Icons.beach_access_rounded, AppColors.avatarPalette[5]),
      '🏫' => (Icons.school_rounded, AppColors.avatarPalette[2]),
      '🏠' => (Icons.home_rounded, AppColors.avatarPalette[3]),
      '🎁' => (Icons.card_giftcard_rounded, AppColors.avatarPalette[1]),
      '🚗' => (Icons.directions_car_rounded, AppColors.avatarPalette[4]),
      _ => (Icons.list_alt_rounded, AppColors.avatarPalette[0]),
    };
