import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `null` means "follow the device's system locale".
final localeProvider = StateProvider<Locale?>((ref) => null);
