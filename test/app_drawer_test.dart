import 'package:drift/native.dart';
import 'package:org_family/core/widgets/app_drawer.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/tasks/screens/tasks_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('drawer Profile entry opens the current member\'s profile',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
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

    // Open the drawer via the AppBar's automatic menu button.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Reham (You)'), findsOneWidget);
  });

  testWidgets('Profile entry is disabled when there is no family member yet',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(drawer: AppDrawer(), body: SizedBox()),
        ),
      ),
    );
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Profile'));
    expect(tile.enabled, isFalse);
  });

  group('V2.3 layout', () {
    Future<ProviderContainer> open(WidgetTester tester, {required CloudAccess access}) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        cloudAccessProvider.overrideWithValue(access),
      ]);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(drawer: AppDrawer(), body: SizedBox()),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('three groups, in order, with the new items', (tester) async {
      await open(tester, access: CloudAccess.member);
      final labels = [
        'My space',
        'Profile',
        'My responsibilities',
        'My reminders',
        'Family',
        'Family activity',
        'Family insights',
        'Invite member',
        'App',
        'Settings',
        'Help & support',
        'About',
      ];
      final ys = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
      expect(ys, [...ys]..sort(), reason: 'shown in this order');
    });

    testWidgets('80% of a phone, at most 304 on a tablet', (tester) async {
      for (final (screen, expected) in [(360.0, 288.0), (375.0, 300.0), (412.0, 304.0), (800.0, 304.0)]) {
        await open(tester, access: CloudAccess.none);
        tester.view.physicalSize = Size(screen, 1600);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(Drawer)).width, closeTo(expected, 0.01), reason: '$screen');
      }
    });

    testWidgets('Invite member only for a synced family member', (tester) async {
      for (final access in [CloudAccess.none, CloudAccess.notMember, CloudAccess.awaitingOwner]) {
        await open(tester, access: access);
        expect(find.text('Invite member'), findsNothing, reason: '$access');
      }
    });

    testWidgets('the new items open their screens', (tester) async {
      for (final (item, title) in [
        ('My reminders', 'My reminders'),
        ('Family insights', 'Family insights'),
        ('Help & support', 'Help & support'),
      ]) {
        await open(tester, access: CloudAccess.none);
        await tester.tap(find.text(item));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(AppBar, title), findsOneWidget, reason: item);
        // My reminders refreshes every minute; unmount it before the next.
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
