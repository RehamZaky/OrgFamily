import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/activity/activity_log.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/repositories/family_settings_repository.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/insights/family_insights.dart';
import 'package:org_family/features/family/insights/family_insights_screen.dart';
import 'package:org_family/features/family/providers/activity_providers.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

ActivityItem _item(
  String id,
  String type,
  DateTime time, {
  String? entity,
  String? member = 'm-kareem',
}) => ActivityItem(id: id, type: type, memberId: member, time: time, entityId: entity ?? 'e-$id');

void main() {
  group('periods', () {
    // 2026-10-14 is a Wednesday.
    final wednesday = DateTime(2026, 10, 14, 15, 30);

    test('week: from the family week start, against last week up to the same point', () {
      final w = insightsWindow(InsightsPeriod.week, now: wednesday, schedule: FamilySchedule.defaults);
      expect(w.start, DateTime(2026, 10, 11)); // Sunday
      expect(w.end, wednesday);
      expect(w.previousStart, DateTime(2026, 10, 4));
      expect(w.previousEnd, DateTime(2026, 10, 7, 15, 30));
    });

    test('week start follows the family schedule', () {
      const saturday = FamilySchedule(schoolWeekdays: {1}, weekStartDay: DateTime.saturday);
      const monday = FamilySchedule(schoolWeekdays: {1}, weekStartDay: DateTime.monday);
      expect(insightsWindow(InsightsPeriod.week, now: wednesday, schedule: saturday).start,
          DateTime(2026, 10, 10));
      expect(insightsWindow(InsightsPeriod.week, now: wednesday, schedule: monday).start,
          DateTime(2026, 10, 12));
      // On the first day itself, "so far" is today only.
      final w = insightsWindow(InsightsPeriod.week, now: DateTime(2026, 10, 12, 9), schedule: monday);
      expect(w.start, DateTime(2026, 10, 12));
      expect(w.previousEnd, DateTime(2026, 10, 5, 9));
    });

    test('month: from the 1st, against last month up to the same day', () {
      final w = insightsWindow(InsightsPeriod.month, now: wednesday, schedule: FamilySchedule.defaults);
      expect(w.start, DateTime(2026, 10));
      expect(w.previousStart, DateTime(2026, 9));
      expect(w.previousEnd, DateTime(2026, 9, 14, 15, 30));
    });

    test('month: a day the previous month lacks compares with all of it', () {
      final w = insightsWindow(InsightsPeriod.month, now: DateTime(2026, 3, 31, 10),
          schedule: FamilySchedule.defaults);
      expect(w.previousStart, DateTime(2026, 2));
      expect(w.previousEnd, DateTime(2026, 3));
      final jan = insightsWindow(InsightsPeriod.month, now: DateTime(2026, 1, 5),
          schedule: FamilySchedule.defaults);
      expect(jan.previousStart, DateTime(2025, 12));
    });
  });

  group('counting', () {
    final from = DateTime(2026, 10, 11);
    final to = DateTime(2026, 10, 14, 23);
    final mon = DateTime(2026, 10, 12, 10);
    final tue = DateTime(2026, 10, 13, 10);

    test('each metric, each thing once', () {
      final c = countInsights([
        _item('t1', ActivityTypes.taskCompleted, mon, entity: 'task-1'),
        _item('t2', ActivityTypes.taskCompleted, tue, entity: 'task-2'),
        _item('r1', ActivityTypes.responsibilityCompleted, mon, entity: 'bed'),
        _item('r2', ActivityTypes.responsibilityCompleted, tue, entity: 'bed'),
        _item('a1', ActivityTypes.shoppingItemAdded, mon, entity: 'milk'),
        _item('a2', ActivityTypes.shoppingItemAdded, mon, entity: 'eggs'),
        _item('p1', ActivityTypes.shoppingItemPurchased, tue, entity: 'milk'),
        _item('ev1', ActivityTypes.eventCreated, mon, entity: 'dentist'),
        _item('ev2', ActivityTypes.eventChanged, tue, entity: 'dentist'),
        _item('ev3', ActivityTypes.eventCancelled, tue, entity: 'party'),
        // Not counted anywhere.
        _item('x1', ActivityTypes.taskCreated, mon),
        _item('x2', ActivityTypes.memberJoined, mon),
        _item('x3', ActivityTypes.shoppingItemRemoved, mon),
        _item('x4', 'reward.redeemed', mon),
      ], from: from, to: to);
      expect(c.tasksCompleted, 2);
      expect(c.responsibilitiesDone, 2); // the same chore on two days
      expect(c.shoppingAdded, 2);
      expect(c.shoppingPurchased, 1);
      expect(c.eventUpdates, 3);
    });

    test('duplicate and legacy entries count once, credited to the first', () {
      final c = countInsights([
        // A log entry and the same completion derived from the tasks table,
        // plus a repeat from an older build.
        _item('task.completed:task-1', ActivityTypes.taskCompleted, mon, entity: 'task-1'),
        _item('legacy-task-task-1', ActivityTypes.taskCompleted, mon.add(const Duration(minutes: 1)),
            entity: 'task-1', member: 'm-mariam'),
        _item('random-1', ActivityTypes.taskCompleted, tue, entity: 'task-1', member: 'm-mariam'),
        // A chore ticked twice the same day (two phones, older build).
        _item('r-a', ActivityTypes.responsibilityCompleted, mon, entity: 'bed', member: 'm-mariam'),
        _item('r-b', ActivityTypes.responsibilityCompleted, mon.add(const Duration(hours: 2)),
            entity: 'bed', member: 'm-kareem'),
        // Bought, un-ticked, bought again.
        _item('p-a', ActivityTypes.shoppingItemPurchased, mon, entity: 'milk'),
        _item('p-b', ActivityTypes.shoppingItemPurchased, tue, entity: 'milk'),
      ], from: from, to: to);
      expect(c.tasksCompleted, 1);
      expect(c.responsibilitiesDone, 1);
      expect(c.shoppingPurchased, 1);
      expect(c.byMember['m-kareem']!.tasks, 1);
      expect(c.byMember['m-kareem']!.responsibilities, 0);
      expect(c.byMember['m-mariam']!.tasks, 0);
      expect(c.byMember['m-mariam']!.responsibilities, 1);
    });

    test('member progress counts only tasks and responsibilities', () {
      final c = countInsights([
        _item('t', ActivityTypes.taskCompleted, mon, member: 'm-omar'),
        _item('r', ActivityTypes.responsibilityCompleted, mon, member: 'm-omar'),
        _item('a', ActivityTypes.shoppingItemAdded, mon, member: 'm-mariam'),
        _item('e', ActivityTypes.eventCreated, mon, member: 'm-mariam'),
        _item('nobody', ActivityTypes.taskCompleted, mon, member: null),
      ], from: from, to: to);
      expect(c.byMember.keys, ['m-omar']);
      expect(c.byMember['m-omar']!.total, 2);
      expect(c.tasksCompleted, 2); // still counted for the family
    });

    test('the period is [from, to)', () {
      final c = countInsights([
        _item('at-start', ActivityTypes.taskCompleted, from),
        _item('before', ActivityTypes.taskCompleted, from.subtract(const Duration(seconds: 1))),
        _item('at-end', ActivityTypes.taskCompleted, to),
      ], from: from, to: to);
      expect(c.tasksCompleted, 1);
    });
  });

  group('change percent', () {
    test('only against a complete, non-empty previous period', () {
      expect(changePercent(5, null), isNull);
      expect(changePercent(5, 0), isNull);
      expect(changePercent(0, 0), isNull);
      expect(changePercent(2, 1), 100);
      expect(changePercent(1, 2), -50);
      expect(changePercent(3, 3), 0);
      expect(changePercent(0, 4), -100);
    });

    test('a real change never rounds to 0%', () {
      expect(changePercent(301, 300), 1);
      expect(changePercent(299, 300), -1);
    });
  });

  group('history', () {
    final start = DateTime(2026, 10, 4);
    test('only when the log reaches back to the start', () {
      expect(hasHistorySince(null, start), isFalse);
      expect(hasHistorySince(DateTime(2026, 10, 3, 23), start), isTrue);
      expect(hasHistorySince(start, start), isTrue);
      expect(hasHistorySince(DateTime(2026, 10, 4, 8), start), isFalse);
    });
  });

  group('screen', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      ]);
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

    Future<void> logged(String id, String type, DateTime at, {String member = 'm-mariam', String? entity}) =>
        db.into(db.familyActivities).insert(FamilyActivitiesCompanion.insert(
          id: id,
          type: type,
          actorMemberId: Value(member),
          entityType: type.split('.').first,
          entityId: entity ?? 'e-$id',
          metadata: Value(jsonEncode({'title': id})),
          createdAt: at,
          occurredAt: Value(at.toUtc()),
          updatedAt: at,
        ));

    Future<void> pump(WidgetTester tester) async {
      // Tall enough that the whole list is built.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FamilyInsightsScreen(),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    Finder tooltip(String containing) => find.byWidgetPredicate(
      (w) => w is Tooltip && (w.message ?? '').contains(containing),
    );

    testWidgets('no activity at all: a welcome, no numbers', (tester) async {
      await pump(tester);
      expect(find.text("Your family's progress starts here! 💜"), findsOneWidget);
      expect(find.text('More insights will appear as your family uses OrgFamily.'), findsOneWidget);
      expect(find.text('Tasks completed'), findsNothing);
      expect(find.text('Week'), findsNothing);
    });

    testWidgets('a new log: numbers and bars, no comparison, coverage only in the tooltip',
        (tester) async {
      final now = DateTime.now();
      await logged('r1', ActivityTypes.responsibilityCompleted, now, entity: 'bed');
      await logged('t1', ActivityTypes.taskCompleted, now, entity: 'task-1', member: 'm-kareem');
      await pump(tester);
      expect(find.text('Responsibilities done'), findsOneWidget);
      expect(find.text('Not enough history to compare'), findsNothing);
      expect(find.textContaining('vs. same time'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining("This phone's activity starts on"), findsNothing,
          reason: 'not shown on the page');
      expect(tooltip("This phone's activity starts on"), findsOneWidget);
      expect(tooltip('Older activity may be incomplete'), findsOneWidget);
      Finder memberBar(String label) =>
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
      expect(memberBar('Mariam — tasks: 0, responsibilities: 1'), findsOneWidget);
      expect(memberBar('Kareem — tasks: 1, responsibilities: 0'), findsOneWidget);

      // Month too: numbers, no comparison.
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('This month'), findsOneWidget);
      expect(find.textContaining('vs. same time'), findsNothing);
    });

    testWidgets('with complete history: percentages, hidden where last period had none',
        (tester) async {
      final now = DateTime.now();
      final week = insightsWindow(InsightsPeriod.week, now: now, schedule: FamilySchedule.defaults);
      // History starts well before last week.
      await logged('old', ActivityTypes.taskCreated, week.previousStart.subtract(const Duration(days: 1)));
      // Tasks: 1 last week → 2 this week.
      await logged('last', ActivityTypes.taskCompleted, week.previousStart, entity: 'task-a');
      await logged('this1', ActivityTypes.taskCompleted, week.start, entity: 'task-b');
      await logged('this2', ActivityTypes.taskCompleted, week.start, entity: 'task-c',
          member: 'm-kareem');
      // Items added: 2 → 1.
      await logged('add1', ActivityTypes.shoppingItemAdded, week.previousStart, entity: 'milk');
      await logged('add2', ActivityTypes.shoppingItemAdded, week.previousStart, entity: 'eggs');
      await logged('add3', ActivityTypes.shoppingItemAdded, week.start, entity: 'bread');
      // Events: 1 → 1.
      await logged('ev1', ActivityTypes.eventCreated, week.previousStart, entity: 'dentist');
      await logged('ev2', ActivityTypes.eventChanged, week.start, entity: 'dentist');
      // Responsibilities: 0 → 1 — a change from nothing has no percentage.
      await logged('r1', ActivityTypes.responsibilityCompleted, week.start, entity: 'bed');
      await pump(tester);
      expect(find.text('+100% vs. same time last week'), findsOneWidget);
      expect(find.text('−50% vs. same time last week'), findsOneWidget);
      expect(find.text('No change vs. same time last week'), findsOneWidget);
      expect(find.textContaining('vs. same time'), findsNWidgets(3));
      expect(tooltip("This phone's activity starts on"), findsNothing);
      expect(tooltip('Older activity may be incomplete'), findsOneWidget);
    });
  });
}
