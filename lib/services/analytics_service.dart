import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

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

  static Future<void> _track(String name, [Map<String, Object>? parameters]) async {
    // Track en Firebase
    await _analytics.logEvent(name: name, parameters: parameters);
    
    // Track en Mixpanel
    if (parameters != null) {
      // Mixpanel prefiere Map<String, dynamic> para las propiedades
      final Map<String, dynamic> props = Map<String, dynamic>.from(parameters);
      _mixpanel?.track(name, properties: props);
    } else {
      _mixpanel?.track(name);
    }
  }

  static Future<void> markAsInternalUser() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.setUserProperty(name: 'user_type', value: 'internal');
    _mixpanel?.optInTracking();
    _mixpanel?.getPeople().set("user_type", "internal");
    
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(false);
      _mixpanel?.optOutTracking();
    }
  }

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    _mixpanel?.track("app_open");
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

  static Future<void> logViewAbout() async {
    await _track('view_about');
  }

  static Future<void> logViewRateApp() async {
    await _track('view_rate_app');
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

  static Future<void> logNewGameFromSummary() async {
    await _track('new_game_from_summary');
  }

  static Future<void> logUndoFromSummary() async {
    await _track('undo_from_summary');
  }

  static Future<void> logGameFinished({
    required String gameMode,
    required bool picaPica,
    required String theme,
    required String pieceType,
    required String pieceDesign,
    required String controlMode,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required String teamNameNos,
    required String teamNameEllos,
  }) async {
    await _track(
      'game_finished',
      {
        'game_mode': gameMode,
        'pica_pica_enabled': picaPica ? 'yes' : 'no',
        'theme': theme,
        'piece_type': pieceType,
        'piece_design': pieceDesign,
        'control_mode': controlMode,
        'sound_enabled': soundEnabled ? 'yes' : 'no',
        'vibration_enabled': vibrationEnabled ? 'yes' : 'no',
        'team_nos': teamNameNos,
        'team_ellos': teamNameEllos,
      },
    );
  }

  static Future<void> logGameModeMenu() async {
    await _track('menu_game_mode_view');
  }

  static Future<void> logDesignMenu() async {
    await _track('menu_design_view');
  }

  static Future<void> logSupportMenu() async {
    await _track('menu_support_view');
  }

  static Future<void> logPurchaseStarted() async {
    await _track('purchase_premium_started');
  }

  // Evento genérico por si necesitamos trackear algo rápido
  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    await _track(name, parameters);
  }
}
