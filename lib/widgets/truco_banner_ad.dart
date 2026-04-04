import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../providers/premium_provider.dart';

class TrucoBannerAd extends StatefulWidget {
  final Color backgroundColor;

  const TrucoBannerAd({super.key, this.backgroundColor = Colors.transparent});

  @override
  State<TrucoBannerAd> createState() => _TrucoBannerAdState();
}

class _TrucoBannerAdState extends State<TrucoBannerAd> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPremium = Provider.of<PremiumProvider>(context).isPremium;
    if (isPremium || !_isBannerLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        color: widget.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble() + 8,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
