import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../utils/enum_display.dart';
import 'active_profile_provider.dart';
import 'family_permissions.dart';

/// Checks [action] against whoever the app is currently "acting as" and,
/// if denied, shows a snackbar and returns false — for use as a guard
/// (`confirmDismiss`, before a save/delete `onTap`) so the UI stops before
/// anything happens, rather than letting the repository throw after an
/// optimistic UI change (like a swipe-to-dismiss animation) already ran.
bool checkPermission(BuildContext context, WidgetRef ref, FamilyAction action) {
  final role = ref.read(activeRoleProvider);
  if (canPerform(role, action)) return true;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.permissionDenied(role.label))),
  );
  return false;
}
