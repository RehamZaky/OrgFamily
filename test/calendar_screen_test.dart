import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/calendar/screens/calendar_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('tapping an event opens the edit form and saves changes',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container.read(familyRepositoryProvider).addMember(
          id: 'me',
          name: 'Reham',
          avatarEmoji: '👩',
          colorValue: 0xFF7C4DFF,
          role: FamilyRole.owner,
        );

    final today = DateTime.now();
    await container.read(eventRepositoryProvider).addEvent(
          id: 'event-1',
          title: 'Dentist appointment',
          startAt: DateTime(today.year, today.month, today.day, 10, 0),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dentist appointment'), findsOneWidget);

    await tester.tap(find.text('Dentist appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Event'), findsOneWidget);
    final titleField = find.widgetWithText(TextField, 'Dentist appointment');
    expect(titleField, findsOneWidget);

    await tester.enterText(titleField, 'Dentist checkup');
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Save changes'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Dentist checkup'), findsOneWidget);
    expect(find.text('Dentist appointment'), findsNothing);
  });

  testWidgets('swiping an event away deletes it', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container.read(familyRepositoryProvider).addMember(
          id: 'me',
          name: 'Reham',
          avatarEmoji: '👩',
          colorValue: 0xFF7C4DFF,
          role: FamilyRole.owner,
        );

    final today = DateTime.now();
    await container.read(eventRepositoryProvider).addEvent(
          id: 'event-2',
          title: 'Family picnic',
          startAt: DateTime(today.year, today.month, today.day, 12, 0),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Family picnic'), findsOneWidget);

    await tester.drag(find.text('Family picnic'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Family picnic'), findsNothing);
  });
}
