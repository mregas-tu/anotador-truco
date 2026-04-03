import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  static Future<void> logThemeChanged(String themeName) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme_name': themeName},
    );
  }

  static Future<void> logPremiumClick() async {
    await _analytics.logEvent(name: 'premium_dialog_opened');
  }

  static Future<void> logPurchaseStarted() async {
    await _analytics.logEvent(name: 'purchase_started');
  }
}
