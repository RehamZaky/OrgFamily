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
  }) {
    return db
        .into(db.familyActivities)
        .insert(
          FamilyActivitiesCompanion.insert(
            id: id,
            type: type,
            actorMemberId: Value(memberId),
            entityType: type.split('.').first,
            entityId: 'e-$id',
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
      );

      final items = await activity(7);
      expect(items.map((i) => i.metadata['title']), ['Feed the cat', 'Old chore']);
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
    expect(find.textContaining('completed "Feed the cat"'), findsOneWidget);
    expect(find.textContaining('added "Milk" to Grocery'), findsOneWidget);
    expect(find.textContaining('added the event "Dentist"'), findsOneWidget);

    // Member filter: only Mariam's.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mariam'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Feed the cat'), findsOneWidget);
    expect(find.textContaining('Milk'), findsNothing);

    // Back to everyone, then type filter: only events.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Everyone'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Events'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dentist'), findsOneWidget);
    expect(find.textContaining('Feed the cat'), findsNothing);
    expect(find.text('No older activity on this phone'), findsOneWidget);
  });
}
