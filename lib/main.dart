import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/boot_detector.dart';
import 'data/providers.dart';
import 'features/family/providers/family_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  container.read(activeMemberIdProvider.notifier).state =
      await loadPersistedActiveMemberId();
  await container.read(notificationServiceProvider).init();
  if (await hasRebootedSinceLastCheck()) {
    await container.read(taskRepositoryProvider).resyncReminders();
    await container.read(eventRepositoryProvider).resyncReminders();
  }
  await container.read(shoppingRepositoryProvider).seedDefaultCategoriesIfEmpty();
  runApp(UncontrolledProviderScope(container: container, child: const OrgFamilyApp()));
}
