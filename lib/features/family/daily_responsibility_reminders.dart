import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/preferences/app_preferences.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../data/repositories/family_settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../settings/providers/reminder_providers.dart';
import 'providers/responsibility_providers.dart';
import 'responsibility_schedule.dart';

/// One planned daily reminder.
typedef DailyReminder = ({int slot, DateTime at, String body});

/// The daily responsibilities reminders for the next days (V2.2) — a pure
/// function so the rules are easy to test:
/// - only on days with something due ([schoolDays] decide "school days");
/// - **today** names what's still undone, and is skipped if everything's
///   done or its time has passed;
/// - **later days** say only "Check today's responsibilities" — their count
///   would be stale by then;
/// - each date has a fixed slot, so planning again replaces, never adds.
List<DailyReminder> planDailyResponsibilityReminders({
  required DateTime now,
  required int atMinutes,
  required List<Responsibility> responsibilities,
  required Set<int> schoolDays,
  required AppLocalizations l10n,
  int days = 7,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final plans = <DailyReminder>[];
  for (var i = 0; i < days; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final at = DateTime(day.year, day.month, day.day, atMinutes ~/ 60, atMinutes % 60);
    if (!at.isAfter(now)) continue;
    final due = [
      for (final r in responsibilities)
        if (r.deletedAt == null && isDueOn(r, day, schoolDays: schoolDays)) r,
    ];
    if (due.isEmpty) continue;
    String body;
    if (i == 0) {
      final left = [for (final r in due) if (!isDoneOn(r, day)) r];
      if (left.isEmpty) continue;
      // Arabic lists use the Arabic comma.
      final names = left.take(3).map((r) => r.title).join(l10n.localeName.startsWith('ar') ? '، ' : ', ');
      body = l10n.dailyReminderLeft(left.length, left.length > 3 ? '$names +${left.length - 3}' : names);
    } else {
      body = l10n.dailyReminderGeneric;
    }
    final epochDay = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000;
    plans.add((slot: epochDay % NotificationService.dailyReminderSlots, at: at, body: body));
  }
  return plans;
}

/// Keeps this phone's daily responsibilities reminders matching its owner
/// ([reminderOwnerProvider] — the signed-in adult's own profile, never the
/// acting one), their setting, their chores and the family's school days.
/// Every plan first cancels all slots, so a different account signing in
/// never leaves the previous person's reminders behind — while switching
/// the acting profile changes nothing.
class DailyResponsibilityReminders {
  DailyResponsibilityReminders(this._ref);

  final Ref _ref;
  Future<void> _last = Future.value();

  /// Plans are run one at a time, in order — two overlapping plans could
  /// otherwise interleave their cancel and schedule calls.
  Future<void> replan({DateTime? now}) => _last = _last.then((_) => _plan(now ?? DateTime.now()));

  Future<void> _plan(DateTime now) async {
    final notifications = _ref.read(notificationServiceProvider);
    await notifications.cancelDailyResponsibilityReminders();
    final memberId = _ref.read(reminderOwnerProvider)?.id;
    if (memberId == null) return;
    final atMinutes = _ref.read(reminderPreferencesProvider(memberId)).dailyAtMinutes;
    if (atMinutes == null) return;
    final chores = await _ref.read(responsibilityRepositoryProvider).watchForMember(memberId).first;
    final schedule = await _ref.read(familySettingsRepositoryProvider).watchSchedule().first;
    final locale = _ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode)
          ? Locale(locale.languageCode)
          : const Locale('en'),
    );
    for (final plan in planDailyResponsibilityReminders(
      now: now,
      atMinutes: atMinutes,
      responsibilities: chores,
      schoolDays: schedule.schoolWeekdays,
      l10n: l10n,
    )) {
      await notifications.scheduleDailyResponsibilityReminder(
        slot: plan.slot,
        title: l10n.homeMyResponsibilities,
        body: plan.body,
        at: plan.at,
      );
    }
  }
}

final dailyResponsibilityRemindersProvider = Provider<DailyResponsibilityReminders>(
  DailyResponsibilityReminders.new,
);

/// Everything the daily reminders depend on — `RootScaffold` re-plans
/// whenever this changes (the signed-in account, the setting, that
/// person's chores or their ticks, school days, language).
final dailyReminderInputsProvider = Provider<Object?>((ref) {
  final memberId = ref.watch(reminderOwnerProvider)?.id;
  final chores = memberId == null
      ? null
      : ref.watch(responsibilitiesForMemberProvider(memberId)).valueOrNull;
  return Object.hashAll([
    memberId,
    if (memberId != null) ref.watch(reminderPreferencesProvider(memberId)).dailyAtMinutes,
    ref.watch(familyScheduleProvider).valueOrNull ?? FamilySchedule.defaults,
    ref.watch(localeProvider),
    for (final r in chores ?? const <Responsibility>[])
      Object.hash(r.id, r.title, r.recurrence, r.customWeekdays, r.lastCompletedDate, r.deletedAt),
  ]);
});
