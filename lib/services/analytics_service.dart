import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> init() async {
    // Solo habilitamos en producción para no ensuciar datos en desarrollo
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(false);
    } else {
      await _analytics.setAnalyticsCollectionEnabled(true);
    }
  }

  static Future<void> markAsInternalUser() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.setUserProperty(name: 'user_type', value: 'internal');
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(false);
    }
  }

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // --- EVENTOS DE CONFIGURACIÓN Y UI ---

  static Future<void> logThemeChanged(String themeName) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme_name': themeName},
    );
  }

  static Future<void> logPieceStyleSelected(String style) async {
    await _analytics.logEvent(
      name: 'piece_style_selected',
      parameters: {'style': style},
    );
  }

  static Future<void> logViewRules() async {
    await _analytics.logEvent(name: 'view_rules_and_signs');
  }

  static Future<void> logTutorialRepeat() async {
    await _analytics.logEvent(name: 'tutorial_repeat');
  }

  static Future<void> logTutorialSkip(int step) async {
    await _analytics.logEvent(
      name: 'tutorial_skip',
      parameters: {'at_step': step},
    );
  }

  static Future<void> logViewAbout() async {
    await _analytics.logEvent(name: 'view_about');
  }

  static Future<void> logViewRateApp() async {
    await _analytics.logEvent(name: 'view_rate_app');
  }

  static Future<void> logRateAppAction(String action) async {
    await _analytics.logEvent(
      name: 'rate_app_action',
      parameters: {'action': action},
    );
  }

  static Future<void> logContactUs() async {
    await _analytics.logEvent(name: 'contact_us_click');
  }

  // --- EVENTOS DE JUEGO ---

  static Future<void> logTeamNamesChanged() async {
    await _analytics.logEvent(name: 'team_names_changed');
  }

  static Future<void> logPicaPicaToggled(bool enabled) async {
    await _analytics.logEvent(
      name: 'pica_pica_toggled',
      parameters: {'enabled': enabled ? 'on' : 'off'},
    );
  }

  static Future<void> logNewGameStarted() async {
    await _analytics.logEvent(name: 'new_game_started');
  }

  static Future<void> logGameRestored() async {
    await _analytics.logEvent(name: 'game_restored');
  }

  static Future<void> logShareMenu() async {
    await _analytics.logEvent(name: 'share_menu_clicked');
  }

  static Future<void> logShareGameResult() async {
    await _analytics.logEvent(name: 'share_game_result');
  }

  static Future<void> logNewGameFromSummary() async {
    await _analytics.logEvent(name: 'new_game_from_summary');
  }

  static Future<void> logUndoFromSummary() async {
    await _analytics.logEvent(name: 'undo_from_summary');
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
    await _analytics.logEvent(
      name: 'game_finished',
      parameters: {
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
    await _analytics.logEvent(name: 'menu_game_mode_view');
  }

  static Future<void> logDesignMenu() async {
    await _analytics.logEvent(name: 'menu_design_view');
  }

  static Future<void> logSupportMenu() async {
    await _analytics.logEvent(name: 'menu_support_view');
  }

  static Future<void> logPurchaseStarted() async {
    await _analytics.logEvent(name: 'purchase_premium_started');
  }

  // Evento genérico por si necesitamos trackear algo rápido
  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
