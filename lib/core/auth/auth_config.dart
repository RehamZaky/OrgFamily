import 'package:flutter/foundation.dart';

/// Whether this build can use Firebase Auth at all — desktop
/// (Windows/macOS/Linux) skips it entirely and behaves exactly as before
/// this feature existed, same "unsupported platform, no-op" pattern as
/// [isMobileAdsSupportedPlatform] in `lib/core/ads/ad_config.dart`.
///
/// Web is deliberately excluded too, even though `lib/firebase_options.dart`
/// still carries a `web` entry (a leftover from an earlier configuration —
/// FlutterFire CLI doesn't delete a platform's config just because a later
/// `flutterfire configure` run didn't select it) — there's no product need
/// for web auth, so it's kept off rather than exercised.
bool get isFirebaseAuthSupportedPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
