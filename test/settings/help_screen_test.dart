import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/features/settings/screens/help_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

void main() {
  Future<AppLocalizations> pump(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HelpScreen(),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(HelpScreen)))!;
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('all eight questions, answers open on tap (${locale.languageCode})', (tester) async {
      final l10n = await pump(tester, locale);
      final questions = [
        l10n.helpSwitchProfileQ,
        l10n.helpInviteQ,
        l10n.helpRolesQ,
        l10n.helpResponsibilitiesQ,
        l10n.helpRemindersQ,
        l10n.helpOfflineQ,
        l10n.helpMoneyQ,
        l10n.helpLanguageQ,
      ];
      for (final q in questions) {
        expect(find.text(q), findsOneWidget);
      }
      expect(find.text(l10n.helpRolesA), findsNothing);
      await tester.tap(find.text(l10n.helpRolesQ));
      await tester.pumpAndSettle();
      expect(find.text(l10n.helpRolesA), findsOneWidget);
      expect(find.text(l10n.settingsMoneyGuide), findsOneWidget);
    });
  }
}
