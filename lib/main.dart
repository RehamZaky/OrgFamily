import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'core/ads/ad_config.dart';
import 'core/auth/auth_config.dart';
import 'core/notifications/boot_detector.dart';
import 'data/providers.dart';
import 'features/family/providers/family_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isFirebaseAuthSupportedPlatform) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  if (isMobileAdsSupportedPlatform) await MobileAds.instance.initialize();
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
