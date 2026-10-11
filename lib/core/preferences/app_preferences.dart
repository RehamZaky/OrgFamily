import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which tab the app opens on.
enum StartTab { home, tasks, calendar, lists, family, money }

/// How times are shown: the phone's own setting, or forced 12/24-hour.
enum TimeFormatPreference { system, h12, h24 }

/// Per-phone preferences (V2.2): appearance, language, start tab, time
/// format, and reminder choices. Stored in SharedPreferences and loaded in
/// `main()` **before `runApp`** (see [AppPreferences.load]), so the first
/// frame already has the saved theme and language — no flash of defaults.
///
/// Family-wide settings (school days, week start) are not here: they sync
/// for the whole family — see `FamilySettings`.
class AppPreferences {
  AppPreferences._(this._prefs, this._memory);

  /// Reads the stored values. Call once, before `runApp`.
  static Future<AppPreferences> load() async =>
      AppPreferences._(await SharedPreferences.getInstance(), null);

  /// Not persisted — for tests and for the provider's default.
  AppPreferences.inMemory([Map<String, Object>? values]) : this._(null, {...?values});

  final SharedPreferences? _prefs;
  final Map<String, Object>? _memory;

  String? _getString(String key) => _prefs?.getString(key) ?? _memory?[key] as String?;
  int? _getInt(String key) => _prefs?.getInt(key) ?? _memory?[key] as int?;
  bool _has(String key) => _prefs?.containsKey(key) ?? _memory!.containsKey(key);

  void _setString(String key, String? value) {
    if (value == null) return _remove(key);
    _memory?[key] = value;
    _prefs?.setString(key, value);
  }

  void _setInt(String key, int? value) {
    if (value == null) return _remove(key);
    _memory?[key] = value;
    _prefs?.setInt(key, value);
  }

  void _remove(String key) {
    _memory?.remove(key);
    _prefs?.remove(key);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  ThemeMode get themeMode => _byName(ThemeMode.values, _getString('themeMode'), ThemeMode.system);
  set themeMode(ThemeMode v) => _setString('themeMode', v.name);

  /// Null: follow the phone's language.
  Locale? get locale {
    final code = _getString('locale');
    return code == null ? null : Locale(code);
  }

  set locale(Locale? v) => _setString('locale', v?.languageCode);

  StartTab get startTab => _byName(StartTab.values, _getString('startTab'), StartTab.home);
  set startTab(StartTab v) => _setString('startTab', v.name);

  TimeFormatPreference get timeFormat =>
      _byName(TimeFormatPreference.values, _getString('timeFormat'), TimeFormatPreference.system);
  set timeFormat(TimeFormatPreference v) => _setString('timeFormat', v.name);

  /// Reminder choices for one profile on this phone — keyed by member so
  /// people sharing a phone don't overwrite each other's ([memberId] null:
  /// nobody picked yet).
  ReminderPreferences reminders(String? memberId) {
    final k = _reminderKey(memberId);
    return ReminderPreferences(
      taskDefault: _has('$k.task')
          ? (_getInt('$k.task')! < 0 ? null : _getInt('$k.task'))
          : ReminderPreferences.defaults.taskDefault,
      eventMinutes: _has('$k.event')
          ? (_getInt('$k.event')! < 0 ? null : _getInt('$k.event'))
          : ReminderPreferences.defaults.eventMinutes,
      dailyAtMinutes: _getInt('$k.daily'),
    );
  }

  void setReminders(String? memberId, ReminderPreferences r) {
    final k = _reminderKey(memberId);
    // -1 stores "none", so it's distinguishable from "never set".
    _setInt('$k.task', r.taskDefault ?? -1);
    _setInt('$k.event', r.eventMinutes ?? -1);
    _setInt('$k.daily', r.dailyAtMinutes);
  }

  static String _reminderKey(String? memberId) => 'reminders.${memberId ?? '_'}';
}

/// One profile's reminder choices on this phone.
@immutable
class ReminderPreferences {
  const ReminderPreferences({
    required this.taskDefault,
    required this.eventMinutes,
    required this.dailyAtMinutes,
  });

  /// What a **new** task's reminder starts as: null = none, 0 = at the due
  /// time, n = n minutes before. Never applied to existing tasks.
  final int? taskDefault;

  /// Minutes before an event this phone reminds; null = no event reminders.
  final int? eventMinutes;

  /// Daily responsibilities reminder, minutes after midnight; null = off.
  final int? dailyAtMinutes;

  /// Today's behaviour: remind at the due time, events 15 minutes before,
  /// no daily reminder.
  static const defaults = ReminderPreferences(taskDefault: 0, eventMinutes: 15, dailyAtMinutes: null);

  ReminderPreferences copyWith({
    int? Function()? taskDefault,
    int? Function()? eventMinutes,
    int? Function()? dailyAtMinutes,
  }) => ReminderPreferences(
    taskDefault: taskDefault != null ? taskDefault() : this.taskDefault,
    eventMinutes: eventMinutes != null ? eventMinutes() : this.eventMinutes,
    dailyAtMinutes: dailyAtMinutes != null ? dailyAtMinutes() : this.dailyAtMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderPreferences &&
      other.taskDefault == taskDefault &&
      other.eventMinutes == eventMinutes &&
      other.dailyAtMinutes == dailyAtMinutes;

  @override
  int get hashCode => Object.hash(taskDefault, eventMinutes, dailyAtMinutes);
}

/// Overridden in `main()` with the loaded [AppPreferences]; tests get an
/// in-memory one.
final appPreferencesProvider = Provider<AppPreferences>((ref) => AppPreferences.inMemory());

/// A value read from [AppPreferences] once, written back on every [set].
class PreferenceNotifier<T> extends StateNotifier<T> {
  PreferenceNotifier(super.initial, this._write);

  final void Function(T value) _write;

  void set(T value) {
    if (value == state) return;
    state = value;
    _write(value);
  }
}

final startTabProvider = StateNotifierProvider<PreferenceNotifier<StartTab>, StartTab>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return PreferenceNotifier(prefs.startTab, (v) => prefs.startTab = v);
});

final timeFormatProvider =
    StateNotifierProvider<PreferenceNotifier<TimeFormatPreference>, TimeFormatPreference>((ref) {
      final prefs = ref.watch(appPreferencesProvider);
      return PreferenceNotifier(prefs.timeFormat, (v) => prefs.timeFormat = v);
    });

/// One profile's reminder choices ([memberId] null: nobody picked yet).
final reminderPreferencesProvider = StateNotifierProvider.family<
  PreferenceNotifier<ReminderPreferences>,
  ReminderPreferences,
  String?
>((ref, memberId) {
  final prefs = ref.watch(appPreferencesProvider);
  return PreferenceNotifier(prefs.reminders(memberId), (v) => prefs.setReminders(memberId, v));
});
