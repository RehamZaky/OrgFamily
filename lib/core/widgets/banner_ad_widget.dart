import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../permissions/active_profile_provider.dart';
import '../../data/local/tables/family_members_table.dart';

/// A standard AdMob banner, anchored wherever it's placed (typically just
/// above a screen's bottom nav bar). Renders nothing on platforms the
/// google_mobile_ads plugin doesn't support (web, desktop) and while the ad
/// hasn't loaded yet, so a failed/slow ad load never leaves a broken box in
/// the layout.
///
/// When the active family profile is a Child, the request is marked
/// non-personalized — Owner/Adult sessions get normal (personalized) ads.
/// This is a per-request signal, not a substitute for the app-level child-
/// directed declaration you make in your AdMob/Play Console account once
/// this ships with a real ad unit.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (isMobileAdsSupportedPlatform) _loadAd();
  }

  void _loadAd() {
    final isChild = ref.read(activeRoleProvider) == FamilyRole.child;
    final ad = BannerAd(
      adUnitId: testBannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(nonPersonalizedAds: isChild),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loadFailed = true);
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!isMobileAdsSupportedPlatform || _loadFailed || ad == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
