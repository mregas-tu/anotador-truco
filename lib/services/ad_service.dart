import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';

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
  static bool _isLoadingInterstitial = false;
  static bool _isLoadingRewarded = false;
  static Timer? _rewardedRetryTimer;
  static int _rewardedRetryCount = 0;

  static const int _maxRewardedRetryCount = 3;
  static const Duration _rewardedRetryDelay = Duration(seconds: 30);

  static void loadInterstitial() {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static void loadRewardedAd() {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _rewardedRetryTimer?.cancel();
    _rewardedRetryTimer = null;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewarded = false;
          _rewardedRetryCount = 0;
          _rewardedAd?.dispose();
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
          _scheduleRewardedRetry();
        },
      ),
    );
  }

  static void _scheduleRewardedRetry() {
    if (_rewardedAd != null || _isLoadingRewarded) return;
    if (_rewardedRetryTimer?.isActive ?? false) return;
    if (_rewardedRetryCount >= _maxRewardedRetryCount) return;

    _rewardedRetryCount += 1;
    _rewardedRetryTimer = Timer(_rewardedRetryDelay, () {
      _rewardedRetryTimer = null;
      loadRewardedAd();
    });
  }

  static const Duration _interstitialCooldown = Duration(minutes: 1);
  static const Duration _appStartGracePeriod = Duration(minutes: 1);
  static final DateTime _appStartedAt = DateTime.now();
  static DateTime? _lastInterstitialShownAt;

  static void maybeShowInterstitialOnNewGame({
    required int nosotros,
    required int ellos,
    required bool isPremium,
    required String source,
  }) {
    if (isPremium) {
      AnalyticsService.logInterstitialAdSkipped(
        source: source,
        reason: 'premium',
      );
      return;
    }
    if (nosotros == 0 && ellos == 0) {
      AnalyticsService.logInterstitialAdSkipped(
        source: source,
        reason: 'empty_score',
      );
      return;
    }
    if (DateTime.now().difference(_appStartedAt) < _appStartGracePeriod) {
      AnalyticsService.logInterstitialAdSkipped(
        source: source,
        reason: 'app_start_grace_period',
      );
      return;
    }
    showInterstitial(isPremium: isPremium, source: source);
  }

  static void showInterstitial({
    required bool isPremium,
    required String source,
  }) {
    if (isPremium) {
      AnalyticsService.logInterstitialAdSkipped(
        source: source,
        reason: 'premium',
      );
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < _interstitialCooldown) {
      AnalyticsService.logInterstitialAdSkipped(
        source: source,
        reason: 'cooldown',
      );
      return;
    }
    final ad = _interstitialAd;
    _interstitialAd = null;
    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AnalyticsService.logInterstitialAdFailedToShow(
            source: source,
            error: error.toString(),
          );
          ad.dispose();
          loadInterstitial();
        },
      );
      _lastInterstitialShownAt = now;
      AnalyticsService.logInterstitialAdShown(source: source);
      ad.show();
    } else {
      AnalyticsService.logInterstitialAdNotReady(source: source);
      loadInterstitial();
    }
  }

  static void showRewardedAd({
    required Function onUserEarnedReward,
    required Function onAdNotReady,
  }) {
    final ad = _rewardedAd;
    _rewardedAd = null;
    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
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
      ad.show(onUserEarnedReward: (ad, reward) => onUserEarnedReward());
    } else {
      loadRewardedAd();
      onAdNotReady();
    }
  }
}
