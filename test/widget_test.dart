import 'package:drift/native.dart';
import 'package:org_family/app/app.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

void main() {
  testWidgets('shows the onboarding carousel when no family members exist yet',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const OrgFamilyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The four marketing pages are supplied artwork (no native text/buttons
    // drawn on top) — only the final "set up your family" page is native.
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingSkip')));
    await tester.pumpAndSettle();

    expect(find.text("Let's set up your family"), findsOneWidget);
    expect(find.text('Add yourself'), findsOneWidget);

    await tester.tap(find.text('Add yourself'));
    await tester.pumpAndSettle();

    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    // Finishing setup must land back on the normal app shell, not a black
    // screen — regression test for onboarding having pushReplaced (instead
    // of pushed) into AddMemberScreen, which left nothing on the Navigator
    // stack for its post-save pop() to return to.
    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Save'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Add member'), findsNothing);
    expect(find.text('Home'), findsOneWidget);

    // Dispose the container (which cancels Drift's watch-query stream
    // subscriptions) while we can still pump the zero-duration Timer that
    // Drift schedules on unsubscribe — letting flutter_test's automatic
    // widget-tree teardown do this instead leaves that Timer pending and
    // fails the test's "no pending timers" invariant.
    container.dispose();
    await tester.pump(Duration.zero);
  });
}
