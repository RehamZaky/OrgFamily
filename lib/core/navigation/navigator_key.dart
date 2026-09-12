import 'package:flutter/material.dart';

/// The app's root [Navigator], so code outside the widget tree — notably
/// [NotificationService]'s tap handler — can push a screen without needing
/// a [BuildContext] of its own.
final navigatorKey = GlobalKey<NavigatorState>();
