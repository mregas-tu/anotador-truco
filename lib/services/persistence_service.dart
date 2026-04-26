import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String keyNosotrosScore = 'nosotros_score';
  static const String keyEllosScore = 'ellos_score';
  static const String keyNosotrosName = 'nosotros_name';
  static const String keyEllosName = 'ellos_name';
  static const String keyGameModeIndex = 'game_mode_index';
  static const String keyThemeId = 'theme_id';
  static const String keyPaletteIndex = 'palette_index';
  static const String keyScoringMode = 'scoring_mode';
  static const String keyIsMuted = 'is_muted';
  static const String keyFinishedMalasNosotros = 'finished_malas_nosotros';
  static const String keyFinishedMalasEllos = 'finished_malas_ellos';
  static const String keyTutorialDone = 'tutorial_done';
  static const String keyPointType = 'point_type';
  static const String keyPicaPicaEnabled = 'pica_pica_enabled';
  static const String keyPicaPicaStart = 'pica_pica_start';
  static const String keyPicaPicaEnd = 'pica_pica_end';
  static const String keyBeanPaletteIndex = 'bean_palette_index';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyMatchesCompletedCount = 'matches_completed_count';
  static const String keyHasRatedApp = 'has_rated_app';
  static const String keyLastRateRequestMatchCount = 'last_rate_request_match_count';
  static const String keyInstallDate = 'install_date';
  static const String keyLastPremiumPromptDate = 'last_premium_prompt_date';
  static const String keyMatchesAtLastPremiumPrompt =
      'matches_at_last_premium_prompt';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<bool> getTutorialDone() async {
    final prefs = await _getPrefs();
    return prefs.getBool(keyTutorialDone) ?? false;
  }

  static Future<void> setTutorialDone(bool done) async {
    final prefs = await _getPrefs();
    await prefs.setBool(keyTutorialDone, done);
  }

  static Future<int> getMatchesCompletedCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyMatchesCompletedCount) ?? 0;
  }

  static Future<void> incrementMatchesCompletedCount() async {
    final prefs = await _getPrefs();
    final current = prefs.getInt(keyMatchesCompletedCount) ?? 0;
    await prefs.setInt(keyMatchesCompletedCount, current + 1);
  }

  static Future<bool> getHasRatedApp() async {
    final prefs = await _getPrefs();
    return prefs.getBool(keyHasRatedApp) ?? false;
  }

  static Future<void> setHasRatedApp(bool rated) async {
    final prefs = await _getPrefs();
    await prefs.setBool(keyHasRatedApp, rated);
  }

  static Future<int> getLastRateRequestMatchCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyLastRateRequestMatchCount) ?? 0;
  }

  static Future<void> setLastRateRequestMatchCount(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyLastRateRequestMatchCount, count);
  }

  static Future<int> getOrSetInstallDate() async {
    final prefs = await _getPrefs();
    int? installMillis = prefs.getInt(keyInstallDate);
    if (installMillis == null) {
      installMillis = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(keyInstallDate, installMillis);
    }
    return installMillis;
  }

  static Future<int> getLastPremiumPromptDate() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyLastPremiumPromptDate) ?? 0;
  }

  static Future<int> getMatchesAtLastPremiumPrompt() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyMatchesAtLastPremiumPrompt) ?? 0;
  }

  static Future<void> markPremiumPromptShown(int matchesCount) async {
    final prefs = await _getPrefs();
    await prefs.setInt(
        keyLastPremiumPromptDate, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(keyMatchesAtLastPremiumPrompt, matchesCount);
  }

  static Future<void> saveGameState({
    required int nosotros,
    required int ellos,
    required String nosotrosName,
    required String ellosName,
    required bool finishedMalasNosotros,
    required bool finishedMalasEllos,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyNosotrosScore, nosotros);
    await prefs.setInt(keyEllosScore, ellos);
    await prefs.setString(keyNosotrosName, nosotrosName);
    await prefs.setString(keyEllosName, ellosName);
    await prefs.setBool(keyFinishedMalasNosotros, finishedMalasNosotros);
    await prefs.setBool(keyFinishedMalasEllos, finishedMalasEllos);
  }

  static Future<void> clearGameState() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyNosotrosScore);
    await prefs.remove(keyEllosScore);
    await prefs.remove(keyFinishedMalasNosotros);
    await prefs.remove(keyFinishedMalasEllos);
    // Names and settings persist
  }

  static Future<void> saveSettings({
    required int gameModeIndex,
    required String themeId,
    required int paletteIndex,
    required int beanPaletteIndex,
    required String scoringMode,
    required bool isMuted,
    required String pointType,
    required bool picaPicaEnabled,
    required int picaPicaStart,
    required int picaPicaEnd,
    required bool vibrationEnabled,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyGameModeIndex, gameModeIndex);
    await prefs.setString(keyThemeId, themeId);
    await prefs.setInt(keyPaletteIndex, paletteIndex);
    await prefs.setInt(keyBeanPaletteIndex, beanPaletteIndex);
    await prefs.setString(keyScoringMode, scoringMode);
    await prefs.setBool(keyIsMuted, isMuted);
    await prefs.setString(keyPointType, pointType);
    await prefs.setBool(keyPicaPicaEnabled, picaPicaEnabled);
    await prefs.setInt(keyPicaPicaStart, picaPicaStart);
    await prefs.setInt(keyPicaPicaEnd, picaPicaEnd);
    await prefs.setBool(keyVibrationEnabled, vibrationEnabled);
  }

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await _getPrefs();
    return {
      keyNosotrosScore: prefs.getInt(keyNosotrosScore),
      keyEllosScore: prefs.getInt(keyEllosScore),
      keyNosotrosName: prefs.getString(keyNosotrosName),
      keyEllosName: prefs.getString(keyEllosName),
      keyGameModeIndex: prefs.getInt(keyGameModeIndex),
      keyThemeId: prefs.getString(keyThemeId),
      keyPaletteIndex: prefs.getInt(keyPaletteIndex),
      keyBeanPaletteIndex: prefs.getInt(keyBeanPaletteIndex),
      keyScoringMode: prefs.getString(keyScoringMode),
      keyIsMuted: prefs.getBool(keyIsMuted),
      keyFinishedMalasNosotros: prefs.getBool(keyFinishedMalasNosotros),
      keyFinishedMalasEllos: prefs.getBool(keyFinishedMalasEllos),
      keyPointType: prefs.getString(keyPointType),
      keyPicaPicaEnabled: prefs.getBool(keyPicaPicaEnabled),
      keyPicaPicaStart: prefs.getInt(keyPicaPicaStart),
      keyPicaPicaEnd: prefs.getInt(keyPicaPicaEnd),
      keyVibrationEnabled: prefs.getBool(keyVibrationEnabled),
    };
  }
}
