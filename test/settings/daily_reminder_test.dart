import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/preferences/app_preferences.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/responsibilities_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/daily_responsibility_reminders.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/features/settings/providers/reminder_providers.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

// 2026-10-11 is a Sunday (a default school day); 2026-10-16 a Friday.
final _sunday9am = DateTime(2026, 10, 11, 9);

Responsibility _chore(
  String id,
  ResponsibilityRecurrence recurrence, {
  String? custom,
  DateTime? done,
}) => Responsibility(
  id: id,
  memberId: 'm-mariam',
  title: id,
  recurrence: recurrence,
  customWeekdays: custom,
  lastCompletedDate: done,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late AppLocalizations l10n;
  setUpAll(() async => l10n = await AppLocalizations.delegate.load(const Locale('en')));

  List<DailyReminder> plan(
    List<Responsibility> chores, {
    DateTime? now,
    int atMinutes = 19 * 60,
    Set<int> schoolDays = const {7, 1, 2, 3, 4},
  }) => planDailyResponsibilityReminders(
    now: now ?? _sunday9am,
    atMinutes: atMinutes,
    responsibilities: chores,
    schoolDays: schoolDays,
    l10n: l10n,
  );

  group('planning', () {
    test("today counts only what's left; later days get generic text", () {
      final plans = plan([
        _chore('Feed the cat', ResponsibilityRecurrence.daily, done: _sunday9am),
        _chore('Make the bed', ResponsibilityRecurrence.daily, done: _sunday9am),
        _chore('Prepare school bag', ResponsibilityRecurrence.daily),
      ]);
      expect(plans, hasLength(7));
      expect(plans.first.at, DateTime(2026, 10, 11, 19));
      expect(plans.first.body, '1 responsibility left today 💜 Prepare school bag');
      expect(plans.skip(1).map((p) => p.body).toSet(), {"Check today's responsibilities 💜"});
    });

    test('nothing today once everything is done', () {
      final plans = plan([_chore('Feed the cat', ResponsibilityRecurrence.daily, done: _sunday9am)]);
      expect(plans.map((p) => p.at.day), isNot(contains(11)));
      expect(plans, hasLength(6));
    });

    test('no reminder on days with nothing scheduled', () {
      // School days only: Friday 16 and Saturday 17 have nothing due.
      final plans = plan([_chore('Homework', ResponsibilityRecurrence.schoolDays)]);
      expect(plans.map((p) => p.at.day), [11, 12, 13, 14, 15]);
      expect(plan(const []), isEmpty);
    });

    test("today's slot is skipped once its time has passed", () {
      final plans = plan(
        [_chore('Feed the cat', ResponsibilityRecurrence.daily)],
        now: DateTime(2026, 10, 11, 20),
      );
      expect(plans.first.at.day, 12);
    });

    test('changing school days changes which days remind', () {
      final chores = [_chore('Homework', ResponsibilityRecurrence.schoolDays)];
      final monToFri = plan(chores, schoolDays: const {1, 2, 3, 4, 5});
      expect(monToFri.map((p) => p.at.day), [12, 13, 14, 15, 16]);
    });

    test('each date keeps its slot, distinct within the week', () {
      final a = plan([_chore('x', ResponsibilityRecurrence.daily)]);
      final b = plan([_chore('x', ResponsibilityRecurrence.daily)], now: DateTime(2026, 10, 12, 9));
      expect(a.map((p) => p.slot).toSet(), hasLength(7));
      // The 12th has the same slot whichever day it was planned on.
      final slotOf12 = a.firstWhere((p) => p.at.day == 12).slot;
      expect(b.firstWhere((p) => p.at.day == 12).slot, slotOf12);
    });
  });

  group('scheduling', () {
    late AppDatabase db;
    late FakeNotificationService notifications;
    late ProviderContainer container;
    final owner = StateProvider<String?>((ref) => 'm-mariam');

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notifications = FakeNotificationService();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
          notificationServiceProvider.overrideWithValue(notifications),
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          // Whose reminders this phone keeps (the signed-in person's own
          // profile — see reminder_scope_test.dart for how it's chosen).
          reminderOwnerProvider.overrideWith((ref) {
            final id = ref.watch(owner);
            return id == null
                ? null
                : FamilyMember(
                    id: id,
                    name: id,
                    avatarEmoji: '🙂',
                    colorValue: 0,
                    role: FamilyRole.adult,
                    createdAt: DateTime(2026),
                    updatedAt: DateTime(2026),
                  );
          }),
        ],
      );
      await container
          .read(responsibilityRepositoryProvider)
          .addResponsibility(
            id: 'r1',
            memberId: 'm-mariam',
            title: 'Feed the cat',
            recurrence: ResponsibilityRecurrence.daily,
          );
      container
          .read(reminderPreferencesProvider('m-mariam').notifier)
          .set(const ReminderPreferences(taskDefault: 0, eventMinutes: 15, dailyAtMinutes: 23 * 60 + 59));
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> replan() => container.read(dailyResponsibilityRemindersProvider).replan();

    test('planning again replaces, never duplicates', () async {
      await replan();
      final first = Map.of(notifications.dailyReminders);
      await replan();
      await replan();
      expect(notifications.dailyReminders.keys.toSet(), first.keys.toSet());
      expect(notifications.dailyReminders.length, lessThanOrEqualTo(7));
    });

    test("another account signing in cancels the previous person's reminders", () async {
      await replan();
      expect(notifications.dailyReminders, isNotEmpty);
      // Someone else signs in on the shared phone, with no daily reminder.
      container.read(owner.notifier).state = 'm-kareem';
      await replan();
      expect(notifications.dailyReminders, isEmpty);
      // Nobody to remind (e.g. signed in, profile not linked yet): nothing.
      container.read(owner.notifier).state = null;
      await replan();
      expect(notifications.dailyReminders, isEmpty);
    });

    test('turning the setting off cancels everything', () async {
      await replan();
      container
          .read(reminderPreferencesProvider('m-mariam').notifier)
          .set(ReminderPreferences.defaults);
      await replan();
      expect(notifications.dailyReminders, isEmpty);
    });

    test('ticking the last chore today removes today\'s reminder', () async {
      await replan();
      final today = DateTime.now();
      bool hasToday() => notifications.dailyReminders.values.any(
        (r) => r.at.year == today.year && r.at.month == today.month && r.at.day == today.day,
      );
      expect(hasToday(), isTrue);
      await container.read(responsibilityRepositoryProvider).setCompletedToday('r1', true);
      await replan();
      expect(hasToday(), isFalse);
      expect(notifications.dailyReminders, isNotEmpty); // later days stay
    });
  });
}
