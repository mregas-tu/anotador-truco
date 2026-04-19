import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  /// Inicializa el SDK y configura los dispositivos de prueba para seguridad.
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Esto te protege de baneos en tu celular al testear con IDs reales
    RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: [
        "2543859CEB14286AB7A77C25F687A0A3", // ID Anterior
        "EC7685C822B403DE73B5E58D9152D7AC", // ID Nuevo (SM A366E)
      ],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);
  }

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4972895390762601/2722330473';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4972895390762601/2722330473'; 
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // ID de prueba
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4972895390762601/2581390945';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4972895390762601/2581390945';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Prueba
    }
    return 'ca-app-pub-4972895390762601/4091264803';
  }

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  static void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      loadInterstitial();
    }
  }

  static void showRewardedAd({
    required Function onUserEarnedReward,
    required Function onAdNotReady,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadRewardedAd();
          onAdNotReady();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onUserEarnedReward());
    } else {
      loadRewardedAd();
      onAdNotReady();
    }
  }
}
