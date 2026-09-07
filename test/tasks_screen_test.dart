import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/tasks/screens/tasks_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('search narrows the task list by title', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container.read(taskRepositoryProvider).addTask(
          id: 'task-1',
          title: 'Buy groceries',
          category: TaskCategory.shopping,
        );
    await container.read(taskRepositoryProvider).addTask(
          id: 'task-2',
          title: 'Wash the car',
          category: TaskCategory.car,
        );

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

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Wash the car'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'groceries');
    await tester.pumpAndSettle();

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Wash the car'), findsNothing);
  });
}
