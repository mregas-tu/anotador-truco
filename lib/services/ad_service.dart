import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4972895390762601/2722330473';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4972895390762601/2722330473'; // Asumiendo mismo ID o placeholder si no hay iOS real
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

  static InterstitialAd? _interstitialAd;

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
              loadInterstitial(); // Recargar para la próxima
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

  static void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      loadInterstitial(); // Intentar cargar si no hay
    }
  }
}
