import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/tasks/screens/tasks_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('tapping a task opens the edit form directly', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container
        .read(taskRepositoryProvider)
        .addTask(id: 'task-1', title: 'Water the plants');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water the plants'));
    await tester.pumpAndSettle();

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Water the plants'), findsOneWidget);
  });
}

// TaskDetailScreen is disabled for now (see task_detail_screen.dart) —
// tapping a task opens TaskFormScreen directly instead. Its old test is
// kept here, commented out alongside the screen, in case it comes back.
/*
import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/tasks/screens/tasks_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('tapping a task opens read-only details, not the edit form',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container
        .read(taskRepositoryProvider)
        .addTask(id: 'task-1', title: 'Water the plants');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water the plants'));
    await tester.pumpAndSettle();

    expect(find.text('Task Details'), findsOneWidget);
    // The edit form's title field must not appear yet — only reachable
    // through the explicit Edit action.
    expect(find.widgetWithText(TextField, 'Water the plants'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Remember the watering can');
    await tester.pump();
    await tester.dragUntilVisible(
      find.widgetWithText(TextButton, 'Save'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.widgetWithText(TextButton, 'Save'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final task = await (db.select(db.tasks)..where((t) => t.id.equals('task-1')))
        .getSingle();
    expect(task.description, 'Remember the watering can');

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Water the plants'), findsOneWidget);
  });
}
*/
