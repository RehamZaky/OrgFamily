import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/repositories/family_invite_repository.dart';
import 'package:org_family/features/auth/screens/join_family_confirm_screen.dart';
import 'package:org_family/features/auth/screens/join_family_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => ProviderScope(
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

FamilyInvite _invite({String? inviterName}) => FamilyInvite(
  code: 'ABCD2345',
  familyId: 'fam-1',
  expiresAt: DateTime.now().add(const Duration(days: 7)),
  usedByUid: null,
  inviterName: inviterName,
);

void main() {
  testWidgets('JoinFamilyScreen shows the code entry step', (tester) async {
    await tester.pumpWidget(_app(const JoinFamilyScreen()));

    expect(find.text('Join a family'), findsOneWidget);
    expect(find.text('Enter invitation code'), findsOneWidget);
    expect(find.text('Ask a family member for their code.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('JoinFamilyConfirmScreen names the inviter\'s family', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(JoinFamilyConfirmScreen(invite: _invite(inviterName: 'Reem'))),
    );

    expect(find.text("Join Reem's family?"), findsOneWidget);
    expect(find.text("Reem's family"), findsOneWidget);
    expect(
      find.text('Tasks, events and shopping lists will be shared with you.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Join family'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets(
    'JoinFamilyConfirmScreen falls back gracefully for an invite with no inviter name',
    (tester) async {
      await tester.pumpWidget(_app(JoinFamilyConfirmScreen(invite: _invite())));

      expect(find.text('Join this family?'), findsOneWidget);
      expect(find.text('Your new family'), findsOneWidget);
    },
  );

  testWidgets('JoinFamilyConfirmScreen renders in Arabic (RTL)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        JoinFamilyConfirmScreen(invite: _invite(inviterName: 'ريم')),
        locale: const Locale('ar'),
      ),
    );

    expect(find.text('الانضمام إلى عائلة ريم؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
