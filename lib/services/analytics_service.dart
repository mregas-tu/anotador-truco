import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'persistence_service.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);
  static Mixpanel? _mixpanel;

  static Future<void> init() async {
    // Inicializar Mixpanel
    try {
      _mixpanel = await Mixpanel.init("2aa595971d68ecedbac6ddca38168ae9",
          trackAutomaticEvents: true);
    } catch (e) {
      debugPrint("Error al inicializar Mixpanel: $e");
    }

    // Solo habilitamos en producción para no ensuciar datos en desarrollo
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(false);
      _mixpanel?.optOutTracking();
    } else {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _mixpanel?.optInTracking();
    }
  }

  static Future<void> _track(String name,
      [Map<String, Object>? parameters]) async {
    if (parameters != null) {
      final Map<String, dynamic> props = Map<String, dynamic>.from(parameters);
      _mixpanel?.track(name, properties: props);
    } else {
      _mixpanel?.track(name);
    }
  }

  static Future<void> markAsInternalUser() async {
    _mixpanel?.optInTracking();
    _mixpanel?.getPeople().set("user_type", "internal");

    if (kDebugMode) {
      _mixpanel?.optOutTracking();
    }
  }

  static Future<void> logAppOpen() async {
    _mixpanel?.track("app_open");
  }

  // --- SUPER PROPERTIES & PEOPLE PROPERTIES ---

  static Future<void> setSuperProperties(Map<String, dynamic> props) async {
    _mixpanel?.registerSuperProperties(props);
  }

  static Future<void> setSuperProperty(String key, dynamic value) async {
    await setSuperProperties({key: value});
  }

  static Future<void> setPeopleProperties(Map<String, dynamic> props) async {
    final people = _mixpanel?.getPeople();
    if (people == null) return;
    for (final entry in props.entries) {
      people.set(entry.key, entry.value);
    }
  }

  static Future<void> incrementPeopleProperty(String key,
      [num value = 1]) async {
    _mixpanel?.getPeople().increment(key, value.toDouble());
  }

  /// Refresca propiedades estáticas: app_version, days_since_install.
  /// Llamar al iniciar la app.
  static Future<void> refreshStaticUserContext() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      await setSuperProperty('app_version', pkg.version);
      await setPeopleProperties({'app_version': pkg.version});
    } catch (_) {}

    try {
      final installMillis = await PersistenceService.getOrSetInstallDate();
      final installDate =
          DateTime.fromMillisecondsSinceEpoch(installMillis).toIso8601String();
      final days = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(installMillis))
          .inDays;
      await setSuperProperty('days_since_install', days);
      await setPeopleProperties({
        '\$created': installDate,
        'days_since_install': days,
      });
    } catch (_) {}
  }

  // --- EVENTOS DE CONFIGURACIÓN Y UI ---

  static Future<void> logThemeChanged(String themeName) async {
    await _track('theme_changed', {'theme_name': themeName});
  }

  static Future<void> logPieceStyleSelected(String style) async {
    await _track('piece_style_selected', {'style': style});
  }

  static Future<void> logViewRules() async {
    await _track('view_rules_and_signs');
  }

  static Future<void> logTutorialRepeat() async {
    await _track('tutorial_repeat');
  }

  static Future<void> logTutorialSkip(int step) async {
    await _track('tutorial_skip', {'at_step': step});
  }

  static Future<void> logRateAppAction(String action) async {
    await _track('rate_app_action', {'action': action});
  }

  static Future<void> logContactUs() async {
    await _track('contact_us_click');
  }

  // --- EVENTOS DE JUEGO ---

  static Future<void> logTeamNamesChanged() async {
    await _track('team_names_changed');
  }

  static Future<void> logPicaPicaToggled(bool enabled) async {
    await _track('pica_pica_toggled', {'enabled': enabled ? 'on' : 'off'});
  }

  // === BRINDIS / VASO ===
  static Future<void> logVasoDialogOpened({required bool isPremium}) async {
    await _track('vaso_dialog_opened', {
      'is_premium': isPremium ? 'yes' : 'no',
    });
  }

  static Future<void> logVasoVideoButtonTapped({
    required bool isPremium,
    required int vasosFilledBefore,
  }) async {
    await _track('vaso_video_button_tapped', {
      'is_premium': isPremium ? 'yes' : 'no',
      'vasos_filled_before': vasosFilledBefore,
    });
  }

  static Future<void> logVasoFilled({
    required bool isPremium,
    required int vasosFilledTotal,
    required int adsInBar,
  }) async {
    await _track('vaso_filled', {
      'is_premium': isPremium ? 'yes' : 'no',
      'vasos_filled_total': vasosFilledTotal,
      'ads_in_bar_after': adsInBar,
    });
  }

  static Future<void> logVasoTempPremiumUnlocked({
    required int vasosFilledTotal,
  }) async {
    await _track('vaso_temp_premium_unlocked', {
      'vasos_filled_total': vasosFilledTotal,
    });
  }

  static Future<void> logVasoAdNotReady({required bool isPremium}) async {
    await _track('vaso_ad_not_ready', {
      'is_premium': isPremium ? 'yes' : 'no',
    });
  }

  static Future<void> logInterstitialAdShown({required String source}) async {
    await _track('interstitial_ad_shown', {
      'source': source,
    });
  }

  static Future<void> logInterstitialAdNotReady({
    required String source,
  }) async {
    await _track('interstitial_ad_not_ready', {
      'source': source,
    });
  }

  static Future<void> logInterstitialAdSkipped({
    required String source,
    required String reason,
  }) async {
    await _track('interstitial_ad_skipped', {
      'source': source,
      'reason': reason,
    });
  }

  static Future<void> logInterstitialAdFailedToShow({
    required String source,
    required String error,
  }) async {
    await _track('interstitial_ad_failed_to_show', {
      'source': source,
      'error': error,
    });
  }

  static Future<void> logNewGameStarted() async {
    await _track('new_game_started');
  }

  static Future<void> logGameRestored() async {
    await _track('game_restored');
  }

  static Future<void> logShareMenu() async {
    await _track('share_menu_clicked');
  }

  static Future<void> logShareGameResult() async {
    await _track('share_game_result');
  }

  static Future<void> logMatchHistoryOpened({
    required int savedMatches,
  }) async {
    await _track('match_history_opened', {
      'saved_matches': savedMatches,
    });
  }

  static Future<void> logMatchHistoryDetailOpened({
    required int daysSinceMatch,
    required int targetScore,
    required bool hasBuenas,
  }) async {
    await _track('match_history_detail_opened', {
      'days_since_match': daysSinceMatch,
      'target_score': targetScore,
      'has_buenas': hasBuenas,
    });
  }

  static Future<void> logMatchHistoryResultShared({
    required int daysSinceMatch,
    required int targetScore,
    required bool hasBuenas,
  }) async {
    await _track('match_history_result_shared', {
      'days_since_match': daysSinceMatch,
      'target_score': targetScore,
      'has_buenas': hasBuenas,
    });
  }

  static Future<void> logMatchHistoryDeleteRequested({
    required int daysSinceMatch,
  }) async {
    await _track('match_history_delete_requested', {
      'days_since_match': daysSinceMatch,
    });
  }

  static Future<void> logMatchHistoryMatchDeleted({
    required int daysSinceMatch,
  }) async {
    await _track('match_history_match_deleted', {
      'days_since_match': daysSinceMatch,
    });
  }

  static Future<void> logUndoFromSummary() async {
    await _track('undo_from_summary');
  }

  static Future<void> logGameFinished({
    required bool teamNosIsCustom,
    required bool teamEllosIsCustom,
  }) async {
    await _track(
      'game_finished',
      {
        'team_nos_is_custom': teamNosIsCustom,
        'team_ellos_is_custom': teamEllosIsCustom,
      },
    );
    incrementPeopleProperty('total_matches_played');
    setPeopleProperties({
      'last_match_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> logDesignMenu() async {
    await _track('menu_design_view');
  }

  // --- PREMIUM FUNNEL ---

  static Future<void> logPremiumPromptShown(String source) async {
    await _track('premium_prompt_shown', {'source': source});
  }

  static Future<void> logPremiumPromptAccepted(String source) async {
    await _track('premium_prompt_accepted', {'source': source});
  }

  static Future<void> logPremiumPromptDismissed(String source) async {
    await _track('premium_prompt_dismissed', {'source': source});
  }

  static Future<void> logPremiumPurchaseCompleted(String? productId) async {
    await _track('premium_purchase_completed', {
      'product_id': productId ?? 'unknown',
    });
  }

  static Future<void> logPremiumPurchaseFailed({String? reason}) async {
    await _track('premium_purchase_failed', {
      'reason': reason ?? 'unknown',
    });
  }

  static Future<void> logPremiumRestoreSucceeded() async {
    await _track('premium_restore_succeeded');
  }

  static Future<void> logLockedContentTapped({
    required String contentType,
    required String contentId,
  }) async {
    await _track('locked_content_tapped', {
      'content_type': contentType,
      'content_id': contentId,
    });
  }

  // Evento genérico por si necesitamos trackear algo rápido
  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    await _track(name, parameters);
  }
}
