import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// `null` means "follow the device's system locale". Saved, and loaded
/// before the first frame (see [AppPreferences]).
final localeProvider = StateNotifierProvider<PreferenceNotifier<Locale?>, Locale?>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return PreferenceNotifier(prefs.locale, (v) => prefs.locale = v);
});
