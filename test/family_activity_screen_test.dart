import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/activity/activity_log.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/providers/activity_providers.dart';
import 'package:org_family/features/family/screens/family_activity_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final now = DateTime.now();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      ],
    );
    for (final (id, name) in [('m-kareem', 'Kareem'), ('m-mariam', 'Mariam')]) {
      await db
          .into(db.familyMembers)
          .insert(FamilyMembersCompanion.insert(id: id, name: name, colorValue: 0xFF7C4DFF));
    }
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> logged(
    String id,
    String type,
    String memberId,
    DateTime at, {
    Map<String, Object?> metadata = const {},
    String? entityId,
  }) {
    return db
        .into(db.familyActivities)
        .insert(
          FamilyActivitiesCompanion.insert(
            id: id,
            type: type,
            actorMemberId: Value(memberId),
            entityType: type.split('.').first,
            entityId: entityId ?? 'e-$id',
            metadata: Value(jsonEncode(metadata)),
            createdAt: at,
            occurredAt: Value(at),
            updatedAt: at,
          ),
        );
  }

  Future<List<ActivityItem>> activity(int days) async {
    final sub = container.listen(familyActivityProvider(days), (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && !sub.read().hasValue; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return sub.read().requireValue;
  }

  group('familyActivityProvider', () {
    test('repeated completions already stored show once (first kept)', () async {
      final today = DateTime(now.year, now.month, now.day, 12);
      // Three completions of one responsibility today, as stored by the
      // earlier build + the new one; one more yesterday; a task twice.
      for (final (id, at) in [
        ('c1', today),
        ('c2', today.add(const Duration(minutes: 1))),
        ('c3', today.add(const Duration(hours: 2))),
        ('c4', today.subtract(const Duration(days: 1))),
      ]) {
        await logged(id, ActivityTypes.responsibilityCompleted, 'm-kareem', at,
            metadata: {'title': 'Organize the family'}, entityId: 'r1');
      }
      for (final id in ['t1', 't2']) {
        await logged(id, ActivityTypes.taskCompleted, 'm-kareem',
            today.subtract(Duration(hours: id == 't1' ? 3 : 1)),
            metadata: {'title': 'Call mom'}, entityId: 'task-1');
      }
      final ids = (await activity(7)).map((i) => i.id).toList();
      expect(ids, ['c1', 't1', 'c4']);
      // …and the weekly summary counts them once too.
      final summary = WeeklyActivitySummary.of(await activity(7));
      expect(summary.choresDone, 2);
      expect(summary.tasksDone, 1);
    });

    test('merges history from before the log with the log, newest first', () async {
      // Completed before this phone had the log…
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'old',
              title: 'Old chore',
              isCompleted: const Value(true),
              completedAt: Value(now.subtract(const Duration(days: 3))),
              completedByMemberId: const Value('m-mariam'),
            ),
          );
      // …and after: the log has it, so it isn't derived a second time.
      final loggedAt = now.subtract(const Duration(days: 2));
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'new',
              title: 'Feed the cat',
              isCompleted: const Value(true),
              completedAt: Value(loggedAt),
            ),
          );
      await logged(
        'a1',
        ActivityTypes.taskCompleted,
        'm-mariam',
        loggedAt,
        metadata: {'title': 'Feed the cat'},
        entityId: 'new',
      );

      final items = await activity(7);
      expect(items.map((i) => i.metadata['title']), ['Feed the cat', 'Old chore']);
    });

    test("another phone's older entries don't hide this phone's earlier history", () async {
      // Synced from a phone that upgraded first: an entry from 5 days ago.
      await logged(
        'other',
        ActivityTypes.taskCreated,
        'm-kareem',
        now.subtract(const Duration(days: 5)),
        metadata: {'title': 'Pay the bill'},
      );
      // This phone, before it upgraded: completed 3 days ago, never logged.
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'mine',
              title: 'Feed the cat',
              isCompleted: const Value(true),
              completedAt: Value(now.subtract(const Duration(days: 3))),
            ),
          );
      final items = await activity(7);
      expect(items.map((i) => i.metadata['title']), ['Feed the cat', 'Pay the bill']);
    });

    test("a newer app's entry types are skipped, not shown wrongly", () async {
      await logged('a1', 'task.submitted_for_approval', 'm-mariam', now);
      await logged('a2', ActivityTypes.taskCreated, 'm-kareem', now);
      expect((await activity(7)).map((i) => i.id), ['a2']);
    });

    test('the window covers whole days; older entries need "show older"', () async {
      await logged(
        'recent',
        ActivityTypes.taskCreated,
        'm-kareem',
        now.subtract(const Duration(days: 6)),
      );
      await logged(
        'older',
        ActivityTypes.taskCreated,
        'm-kareem',
        now.subtract(const Duration(days: 9)),
      );
      expect((await activity(7)).map((i) => i.id), ['recent']);
      expect((await activity(14)).map((i) => i.id), ['recent', 'older']);
    });
  });

  testWidgets('Arabic uses neutral phrasing that fits every member', (tester) async {
    await tester.runAsync(() async {
      await logged(
        't1',
        ActivityTypes.taskCompleted,
        'm-mariam',
        now,
        metadata: {'title': 'Feed the cat'},
      );
      await logged(
        'r1',
        ActivityTypes.responsibilityCompleted,
        'm-mariam',
        now,
        metadata: {'title': 'Make the bed'},
      );
      await logged('t2', ActivityTypes.taskCreated, 'm-kareem', now, metadata: {'title': 'Pay'});
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FamilyActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The action (name in place, no gendered verb), then the title on its
    // own line.
    expect(find.text('تم إكمال مهمة بواسطة Mariam'), findsOneWidget);
    expect(find.text('تم إنجاز مسؤولية بواسطة Mariam'), findsOneWidget);
    expect(find.text('تمت إضافة مهمة بواسطة Kareem'), findsOneWidget);
    expect(find.text('Feed the cat'), findsOneWidget);
    expect(find.text('Make the bed'), findsOneWidget);
  });

  testWidgets('the screen groups by day, sums up the week and filters', (tester) async {
    await tester.runAsync(() async {
      await logged(
        't1',
        ActivityTypes.taskCompleted,
        'm-mariam',
        now,
        metadata: {'title': 'Feed the cat'},
      );
      await logged(
        's1',
        ActivityTypes.shoppingItemAdded,
        'm-kareem',
        now,
        metadata: {'name': 'Milk', 'listName': 'Grocery'},
      );
      await logged(
        'e1',
        ActivityTypes.eventCreated,
        'm-kareem',
        now.subtract(const Duration(days: 1)),
        metadata: {'title': 'Dentist'},
      );
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FamilyActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.textContaining('Whole family'), findsOneWidget);
    expect(find.text('Mariam completed a task'), findsOneWidget);
    expect(find.text('Feed the cat'), findsOneWidget);
    expect(find.text('Kareem added to Grocery'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Kareem added an event'), findsOneWidget);
    expect(find.text('Dentist'), findsOneWidget);

    // Member filter, from its sheet: only Mariam's.
    await tester.tap(find.text('Everyone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Mariam'));
    await tester.pumpAndSettle();
    expect(find.text('Feed the cat'), findsOneWidget);
    expect(find.text('Milk'), findsNothing);
    // The summary stays the whole family's.
    expect(find.textContaining('Whole family'), findsOneWidget);

    // Back to everyone, then the type sheet: only events.
    await tester.tap(find.text('Mariam').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Everyone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Events'));
    await tester.pumpAndSettle();
    expect(find.text('Dentist'), findsOneWidget);
    expect(find.text('Feed the cat'), findsNothing);
    expect(find.text('No older activity on this phone'), findsOneWidget);
  });

  test('sections: Today, Yesterday, weekday, then date — in local time', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final today = DateTime(2026, 10, 11, 12); // a Sunday
    ActivityItem at(DateTime t) => ActivityItem(id: '$t', type: 't', memberId: null, time: t);
    final groups = groupActivityByDay(
      [
        at(today),
        at(today.subtract(const Duration(days: 1))),
        at(today.subtract(const Duration(days: 3))),
        at(today.subtract(const Duration(days: 9))),
        at(DateTime(2025, 12, 30, 9)),
        // A server (UTC) timestamp lands on the viewer's local day.
        at(DateTime(2026, 10, 8, 12).toUtc()),
      ],
      l10n,
      'en',
      now: today,
    );
    expect(groups.map((g) => g.$1), [
      'Today',
      'Yesterday',
      'Thursday',
      'Fri, Oct 2',
      'Tue, Dec 30, 2025',
      'Thursday',
    ]);
  });
}
