import 'dart:io';
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
  bool _loadAttempted = false;

  Future<void> _loadAdaptiveBanner() async {
    if (_loadAttempted) return;
    _loadAttempted = true;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getAnchoredAdaptiveBannerAdSize(
      Platform.isAndroid ? Orientation.portrait : Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: size,
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
    if (isPremium) return const SizedBox.shrink();

    // Trigger load once context is available (needs MediaQuery).
    if (!_loadAttempted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdaptiveBanner());
    }

    if (!_isBannerLoaded || _bannerAd == null) return const SizedBox.shrink();

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
