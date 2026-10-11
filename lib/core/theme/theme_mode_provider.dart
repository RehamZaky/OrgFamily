import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Light / dark / follow the phone — saved, and loaded before the first
/// frame (see [AppPreferences]).
final themeModeProvider = StateNotifierProvider<PreferenceNotifier<ThemeMode>, ThemeMode>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return PreferenceNotifier(prefs.themeMode, (v) => prefs.themeMode = v);
});
