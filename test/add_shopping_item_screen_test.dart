import 'package:drift/native.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/shopping/screens/add_shopping_item_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('adds an item to the pre-selected list', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    await container
        .read(shoppingRepositoryProvider)
        .addList(id: 'list-1', name: 'Groceries', emoji: '🛒');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddShoppingItemScreen(initialListId: 'list-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🛒  Groceries'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Item'));
    await tester.pumpAndSettle();

    final items = await db.select(db.shoppingItems).get();
    expect(items, hasLength(1));
    expect(items.single.name, 'Milk');
    expect(items.single.listId, 'list-1');
  });

  testWidgets('switching the list via the picker saves to the new list',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ]);
    addTearDown(container.dispose);

    final repo = container.read(shoppingRepositoryProvider);
    await repo.addList(id: 'list-1', name: 'Groceries', emoji: '🛒');
    await repo.addList(id: 'list-2', name: 'Gifts', emoji: '🎁');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddShoppingItemScreen(initialListId: 'list-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('🛒  Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gifts'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Birthday candles');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Item'));
    await tester.pumpAndSettle();

    final items = await db.select(db.shoppingItems).get();
    expect(items.single.listId, 'list-2');
  });
}
