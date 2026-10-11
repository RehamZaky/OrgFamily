import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/preferences/app_preferences.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/local/tables/responsibilities_table.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/daily_responsibility_reminders.dart';
import 'package:org_family/features/family/providers/family_providers.dart';
import 'package:org_family/features/settings/providers/reminder_providers.dart';
import 'package:org_family/features/tasks/domain/task_status_calculator.dart';
import 'package:org_family/features/tasks/screens/task_form_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

FamilyMember _member(String id, String name, FamilyRole role, {String? uid}) => FamilyMember(
  id: id,
  name: name,
  avatarEmoji: '🙂',
  colorValue: 0,
  role: role,
  linkedUid: uid,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('new-task reminder default', () {
    Future<Task> createWithDefault(WidgetTester tester, int? taskDefault, {DateTime? due}) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = AppPreferences.inMemory();
      prefs.setReminders(
        null,
        ReminderPreferences(taskDefault: taskDefault, eventMinutes: 15, dailyAtMinutes: null),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TaskFormScreen(initialTitle: 'Pay the bill', initialDueDate: due),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      final task = (await tester.runAsync(() => db.select(db.tasks).getSingle()))!;
      container.dispose();
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
      return task;
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));

    testWidgets('"No reminder" turns it off for a new date-only task too', (tester) async {
      final task = await createWithDefault(tester, null, due: tomorrow);
      expect(task.reminderType, TaskReminderType.none);
    });

    testWidgets('a date-only task otherwise keeps the 9 AM on-the-day reminder', (tester) async {
      final task = await createWithDefault(tester, 30, due: tomorrow);
      expect(task.reminderType, TaskReminderType.dueTime);
      final at = taskReminderNotifyAt(TaskReminderInput.fromTask(task));
      expect(at, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));
    });

    testWidgets('a task with no due date gets no automatic reminder', (tester) async {
      final task = await createWithDefault(tester, 30);
      final at = taskReminderNotifyAt(TaskReminderInput.fromTask(task));
      expect(at, isNull);
    });
  });

  group("reminders belong to the phone's own person, not the acting profile", () {
    final kareem = _member('m-kareem', 'Kareem', FamilyRole.owner, uid: 'uid-kareem');
    final reem = _member('m-reem', 'Reem', FamilyRole.adult, uid: 'uid-reem');
    final omar = _member('m-omar', 'Omar', FamilyRole.child);

    late AppDatabase db;
    late FakeNotificationService notifications;
    late ProviderContainer container;
    final acting = StateProvider<String?>((ref) => 'm-kareem');
    final signedIn = StateProvider<String?>((ref) => 'uid-kareem');

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notifications = FakeNotificationService();
      final prefs = AppPreferences.inMemory();
      const daily = ReminderPreferences(taskDefault: 0, eventMinutes: 15, dailyAtMinutes: 23 * 60 + 59);
      prefs.setReminders('m-kareem', daily);
      prefs.setReminders('m-omar', daily); // set for Omar too — must still never fire here
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
          notificationServiceProvider.overrideWithValue(notifications),
          appPreferencesProvider.overrideWithValue(prefs),
          familyMembersProvider.overrideWith((ref) => Stream.value([kareem, reem, omar])),
          signedInUidProvider.overrideWith((ref) => ref.watch(signedIn)),
          authenticatedMemberProvider.overrideWith((ref) {
            final uid = ref.watch(signedIn);
            return [kareem, reem].where((m) => m.linkedUid == uid).firstOrNull;
          }),
          actingMemberProvider.overrideWith(
            (ref) => [kareem, reem, omar].where((m) => m.id == ref.watch(acting)).firstOrNull,
          ),
          actingMemberIdProvider.overrideWith((ref) => ref.watch(acting)),
        ],
      );
      final chores = container.read(responsibilityRepositoryProvider);
      await chores.addResponsibility(
        id: 'rk',
        memberId: 'm-kareem',
        title: 'Organize the family',
        recurrence: ResponsibilityRecurrence.daily,
      );
      await chores.addResponsibility(
        id: 'ro',
        memberId: 'm-omar',
        title: 'Feed the cat',
        recurrence: ResponsibilityRecurrence.daily,
      );
      await container.read(familyMembersProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> replan() => container.read(dailyResponsibilityRemindersProvider).replan();
    Set<String> bodies() => notifications.dailyReminders.values.map((r) => r.body).toSet();

    test('Kareem → Omar → Kareem: always only Kareem\'s reminders', () async {
      await replan();
      final kareemsPlan = Map.of(notifications.dailyReminders);
      expect(bodies().any((b) => b.contains('Organize the family')), isTrue);

      container.read(acting.notifier).state = 'm-omar'; // looking at Omar's chores
      expect(container.read(reminderOwnerProvider)?.id, 'm-kareem');
      await replan();
      expect(notifications.dailyReminders, kareemsPlan);
      expect(bodies().any((b) => b.contains('Feed the cat')), isFalse);

      container.read(acting.notifier).state = 'm-kareem';
      await replan();
      expect(notifications.dailyReminders, kareemsPlan);
    });

    test("another account signing in replaces the previous account's reminders", () async {
      await replan();
      expect(notifications.dailyReminders, isNotEmpty);
      container.read(signedIn.notifier).state = 'uid-reem'; // Reem: no daily reminder set
      expect(container.read(reminderOwnerProvider)?.id, 'm-reem');
      await replan();
      expect(notifications.dailyReminders, isEmpty);
    });

    test('signed out (an all-local family): the family Owner\'s profile', () async {
      container.read(signedIn.notifier).state = null;
      container.read(acting.notifier).state = 'm-omar';
      expect(container.read(reminderOwnerProvider)?.id, 'm-kareem');
    });
  });
}
