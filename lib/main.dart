import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();
  await container.read(shoppingRepositoryProvider).seedDefaultCategoriesIfEmpty();
  runApp(UncontrolledProviderScope(container: container, child: const OrgFamilyApp()));
}
