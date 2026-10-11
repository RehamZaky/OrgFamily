import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/locale_provider.dart';
import '../core/navigation/navigator_key.dart';
import '../core/preferences/app_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/utils/date_format_x.dart';
import '../data/providers.dart';
import '../features/calendar/screens/event_form_screen.dart';
import '../features/tasks/screens/task_form_screen.dart';
import '../l10n/app_localizations.dart';
import 'root_scaffold.dart';
import '../features/family/screens/my_responsibilities_screen.dart';

class OrgFamilyApp extends ConsumerStatefulWidget {
  const OrgFamilyApp({super.key});

  @override
  ConsumerState<OrgFamilyApp> createState() => _OrgFamilyAppState();
}

class _OrgFamilyAppState extends ConsumerState<OrgFamilyApp> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame so the navigator this pushes into
    // is actually mounted — both for the cold-start case (app launched by
    // tapping a notification) and for taps that arrive while already
    // running (registering the callback here covers both).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifications = ref.read(notificationServiceProvider);
      notifications.onNotificationTapped = _handleNotificationTap;
      notifications.handlePendingLaunch();
    });
  }

  Future<void> _handleNotificationTap(String type, String id) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (type == 'task') {
      final task = await ref.read(taskRepositoryProvider).getById(id);
      // Null if the task was completed/deleted between the reminder firing
      // and the user tapping it — nothing sensible to open in that case.
      if (task != null) {
        navigator.push(MaterialPageRoute(builder: (_) => TaskFormScreen(existing: task)));
      }
    } else if (type == 'responsibilities') {
      navigator.push(MaterialPageRoute(builder: (_) => const MyResponsibilitiesScreen()));
    } else if (type == 'event') {
      final event = await ref.read(eventRepositoryProvider).getById(id);
      if (event != null) {
        navigator.push(MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final timeFormat = ref.watch(timeFormatProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OrgFamily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The time-format setting drives MediaQuery's 24-hour flag, so time
      // pickers and every formatted time follow it ("system" keeps the
      // phone's own choice).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final use24 = switch (timeFormat) {
          TimeFormatPreference.system => mq.alwaysUse24HourFormat,
          TimeFormatPreference.h12 => false,
          TimeFormatPreference.h24 => true,
        };
        TimeFormatting.use24Hour = use24;
        TimeFormatting.locale = Localizations.localeOf(context).toString();
        return MediaQuery(data: mq.copyWith(alwaysUse24HourFormat: use24), child: child!);
      },
      home: const RootScaffold(),
    );
  }
}
