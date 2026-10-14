import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/providers/family_providers.dart';
import 'package:org_family/features/reminders/my_reminders_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notifications;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifications = FakeNotificationService();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
      notificationServiceProvider.overrideWithValue(notifications),
    ]);
    // Signed out, so the phone's own person is the Owner, Kareem.
    for (final (id, name, role) in [
      ('m-kareem', 'Kareem', FamilyRole.owner),
      ('m-omar', 'Omar', FamilyRole.child),
    ]) {
      await db.into(db.familyMembers).insert(FamilyMembersCompanion.insert(
        id: id,
        name: name,
        colorValue: 0xFF7C4DFF,
        role: Value(role),
      ));
    }
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> task(String title, String? assignee, DateTime due) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
        id: 't-$title',
        title: title,
        assigneeId: Value(assignee),
        dueDate: Value(DateTime(due.year, due.month, due.day)),
        dueTimeMinutes: Value(due.hour * 60 + due.minute),
      ));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyRemindersScreen(),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  // The screen refreshes every minute; unmount it so no timer is left.
  Future<void> unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  group('permission warning', () {
    testWidgets('shown when notifications are off, with a way to allow them', (tester) async {
      notifications.enabled = false;
      notifications.grantOnRequest = true;
      await pump(tester);
      expect(find.textContaining('Notifications are turned off'), findsOneWidget);

      await tester.tap(find.text('Allow notifications'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(notifications.permissionRequests, 1);
      expect(find.textContaining('Notifications are'), findsNothing);
      await unmount(tester);
    });

    testWidgets('still off after asking → points to the phone settings', (tester) async {
      notifications.enabled = false;
      notifications.grantOnRequest = false;
      await pump(tester);
      await tester.tap(find.text('Allow notifications'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notifications are still off'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets("not shown when allowed, or when the phone can't say", (tester) async {
      for (final state in [true, null]) {
        notifications.enabled = state;
        container.invalidate(notificationServiceProvider);
        await pump(tester);
        expect(find.textContaining('Notifications are'), findsNothing, reason: '$state');
        await unmount(tester);
      }
    });
  });

  testWidgets("Mine is the phone owner's and the family's; Everyone adds the rest", (tester) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);
    await task('Kareem task', 'm-kareem', tomorrow);
    await task('Family task', null, tomorrow.add(const Duration(minutes: 1)));
    await task('Omar task', 'm-omar', tomorrow.add(const Duration(minutes: 2)));
    await pump(tester);

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Kareem task'), findsOneWidget);
    expect(find.text('Family task'), findsOneWidget);
    expect(find.text('Omar task'), findsNothing);

    await tester.tap(find.text('Everyone'));
    await tester.pumpAndSettle();
    expect(find.text('Omar task'), findsOneWidget);
    expect(find.text('Task · Omar'), findsOneWidget);
    expect(find.text('Task · Whole family'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('switching the acting profile does not change Mine', (tester) async {
    final now = DateTime.now();
    await task('Omar task', 'm-omar', DateTime(now.year, now.month, now.day + 2, 18));
    // Kareem's phone acting as Omar: still Kareem's reminders.
    container.read(activeMemberIdProvider.notifier).state = 'm-omar';
    await pump(tester);
    expect(container.read(actingMemberProvider)?.id, 'm-omar');
    expect(find.text('Omar task'), findsNothing);
    expect(find.text('No reminders for you in the next 7 days'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty state offers the reminder settings', (tester) async {
    await pump(tester);
    expect(find.text('No reminders for you in the next 7 days'), findsOneWidget);
    expect(find.text('Reminder settings'), findsOneWidget);
    await unmount(tester);
  });
}
