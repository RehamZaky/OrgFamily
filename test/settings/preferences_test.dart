import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/app/app.dart';
import 'package:org_family/core/localization/locale_provider.dart';
import 'package:org_family/core/preferences/app_preferences.dart';
import 'package:org_family/core/theme/theme_mode_provider.dart';
import 'package:org_family/core/utils/date_format_x.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/repositories/event_repository.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/tasks/domain/default_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_notification_service.dart';

void main() {
  group('saved preferences', () {
    test('survive a restart: theme, language, start tab, time format', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(await AppPreferences.load())],
      );
      first.read(themeModeProvider.notifier).set(ThemeMode.dark);
      first.read(localeProvider.notifier).set(const Locale('ar'));
      first.read(startTabProvider.notifier).set(StartTab.calendar);
      first.read(timeFormatProvider.notifier).set(TimeFormatPreference.h24);
      first.dispose();

      // "Restart": a fresh container over freshly loaded preferences — and
      // the values are there synchronously, before any frame.
      final second = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(await AppPreferences.load())],
      );
      addTearDown(second.dispose);
      expect(second.read(themeModeProvider), ThemeMode.dark);
      expect(second.read(localeProvider), const Locale('ar'));
      expect(second.read(startTabProvider), StartTab.calendar);
      expect(second.read(timeFormatProvider), TimeFormatPreference.h24);
    });

    test('defaults before anything is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.load();
      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.locale, isNull);
      expect(prefs.startTab, StartTab.home);
      expect(prefs.timeFormat, TimeFormatPreference.system);
      expect(prefs.reminders('m1'), ReminderPreferences.defaults);
    });

    test('reminder choices are kept per profile on a shared phone', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(await AppPreferences.load())],
      );
      addTearDown(c.dispose);
      final kareem = c.read(reminderPreferencesProvider('m-kareem').notifier);
      kareem.set(
        const ReminderPreferences(taskDefault: 30, eventMinutes: null, dailyAtMinutes: 19 * 60),
      );
      // Reem's are untouched by Kareem's choices.
      expect(c.read(reminderPreferencesProvider('m-reem')), ReminderPreferences.defaults);

      final reloaded = await AppPreferences.load();
      expect(
        reloaded.reminders('m-kareem'),
        const ReminderPreferences(taskDefault: 30, eventMinutes: null, dailyAtMinutes: 19 * 60),
      );
      // "None" stays none after a reload (not mistaken for "never set").
      expect(reloaded.reminders('m-kareem').eventMinutes, isNull);
      expect(reloaded.reminders('m-reem'), ReminderPreferences.defaults);
    });
  });

  group('time format', () {
    Future<String> format(WidgetTester tester, String lang, bool use24) async {
      late String out;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: use24),
            child: Builder(
              builder: (context) {
                out = formatTime(context, DateTime(2026, 1, 1, 15, 30));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return out;
    }

    // Digits are whatever intl renders for the language (Arabic-Indic on
    // phones); the 12/24-hour shape is what the setting decides.
    final h24 = RegExp(r'^[1١][5٥]:[3٣][0٠]$');

    testWidgets('English 12-hour / 24-hour', (tester) async {
      expect(await format(tester, 'en', false), '3:30 PM');
      expect(await format(tester, 'en', true), matches(h24));
    });

    testWidgets('Arabic 12-hour / 24-hour', (tester) async {
      final twelve = await format(tester, 'ar', false);
      expect(twelve, contains('م'));
      expect(twelve, isNot(matches(h24)));
      expect(await format(tester, 'ar', true), matches(h24));
    });
  });

  group('start tab', () {
    late AppDatabase db;
    late ProviderContainer container;

    Future<void> pumpApp(WidgetTester tester, Map<String, Object> saved, FamilyRole role) async {
      SharedPreferences.setMockInitialValues(saved);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(
        () => db
            .into(db.familyMembers)
            .insert(
              FamilyMembersCompanion.insert(
                id: 'm1',
                name: 'Kareem',
                colorValue: 0,
                role: Value(role),
              ),
            ),
      );
      final prefs = await tester.runAsync(AppPreferences.load);
      container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs!),
          databaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const OrgFamilyApp()),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tearDownApp(WidgetTester tester) async {
      container.dispose();
      await tester.pump(Duration.zero);
      await db.close();
    }

    testWidgets('opens on the saved tab once; later navigation sticks through rebuilds', (
      tester,
    ) async {
      await pumpApp(tester, {'startTab': 'calendar'}, FamilyRole.owner);
      expect(find.byType(TableCalendar<Event>), findsOneWidget);

      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();
      // A rebuild of everything above the shell (theme change).
      container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(find.byType(TableCalendar<Event>), findsNothing);
      await tearDownApp(tester);
    });

    testWidgets("Money as start tab falls back to Home for a profile that can't see it", (
      tester,
    ) async {
      await pumpApp(tester, {'startTab': 'money'}, FamilyRole.child);
      expect(find.text('Money'), findsNothing); // no Money tab for a child
      // …and the saved choice is kept for when Money is available again.
      expect(container.read(startTabProvider), StartTab.money);
      expect((await tester.runAsync(AppPreferences.load))!.startTab, StartTab.money);
      await tearDownApp(tester);
    });
  });

  group('default task reminder', () {
    test('maps the setting to the reminder a new task starts with', () {
      expect(defaultTaskReminder(null, dueTimeMinutes: 600).type, TaskReminderType.none);
      expect(defaultTaskReminder(0, dueTimeMinutes: 600).type, TaskReminderType.dueTime);
      final before = defaultTaskReminder(30, dueTimeMinutes: 600);
      expect((before.type, before.offsetMinutes), (TaskReminderType.offset, 30));
    });

    test('a date-only task keeps the on-the-day reminder instead of an offset', () {
      final d = defaultTaskReminder(30, dueTimeMinutes: null);
      expect((d.type, d.offsetMinutes), (TaskReminderType.dueTime, null));
      expect(defaultTaskReminder(null, dueTimeMinutes: null).type, TaskReminderType.none);
    });
  });

  group('event reminder', () {
    test('uses the setting, and re-arming applies a change to every event', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final notifications = FakeNotificationService();
      int? minutes = 15;
      final events = EventRepository(
        db,
        notifications,
        SyncEngine.inert(db),
        eventReminderMinutes: () => minutes,
      );
      final start = DateTime.now().add(const Duration(days: 2));
      await events.addEvent(id: 'e1', title: 'Dentist', startAt: start);
      await events.addEvent(id: 'e2', title: 'Swim', startAt: start);
      expect(notifications.eventReminders, {'e1': 15, 'e2': 15});

      minutes = 60;
      await events.resyncReminders();
      expect(notifications.eventReminders, {'e1': 60, 'e2': 60});

      minutes = null; // "No reminder"
      await events.resyncReminders();
      expect(notifications.eventReminders, isEmpty);
      // The shared event records themselves never change.
      expect((await events.getById('e1'))!.startAt.difference(start).inSeconds, 0);
    });
  });
}
