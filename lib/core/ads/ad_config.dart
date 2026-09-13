import 'package:flutter/foundation.dart';

/// Whether this build can show AdMob ads at all — the plugin only supports
/// Android and iOS, so every ad entry point (init, banner widget) must
/// check this first rather than crashing on web/desktop, which this app
/// also targets (e.g. Windows during development).
bool get isMobileAdsSupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Google's official *test* banner ad unit IDs — always safe to request,
/// since they only ever serve Google's own test creative. Swap these for
/// the real banner ad unit ID(s) from your AdMob account before a
/// production release; shipping test ads to real users violates AdMob
/// policy.
String get testBannerAdUnitId => defaultTargetPlatform == TargetPlatform.iOS
    ? 'ca-app-pub-3940256099942544/2934735716'
    : 'ca-app-pub-3940256099942544/6300978111';
