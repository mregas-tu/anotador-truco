import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_record.dart';

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
  static const String keyScoreHistoryTutorialShown =
      'score_history_tutorial_shown';
  static const String keyLiveMatchTutorialShown =
      'live_match_tutorial_shown';
  static const String keyPointType = 'point_type';
  static const String keyPicaPicaEnabled = 'pica_pica_enabled';
  static const String keyPicaPicaStart = 'pica_pica_start';
  static const String keyPicaPicaEnd = 'pica_pica_end';
  static const String keyBeanPaletteIndex = 'bean_palette_index';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyMatchesCompletedCount = 'matches_completed_count';
  static const String keyHasRatedApp = 'has_rated_app';
  static const String keyLastRateRequestMatchCount =
      'last_rate_request_match_count';
  static const String keyInstallDate = 'install_date';
  static const String keyLastPremiumPromptDate = 'last_premium_prompt_date';
  static const String keyMatchesAtLastPremiumPrompt =
      'matches_at_last_premium_prompt';
  static const String keyVasoAdsWatched = 'vaso_ads_watched';
  static const String keyVasoLastAdAt = 'vaso_last_ad_at';
  static const String keyVasoBrindados = 'vaso_brindados';
  static const String keyScoreHistory = 'score_history';
  static const String keyMatchHistory = 'match_history_v1';
  static const String keyCurrentMatchId = 'current_match_id';
  static const String keyCurrentMatchStartedAt = 'current_match_started_at';

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

  static Future<bool> getScoreHistoryTutorialShown() async {
    final prefs = await _getPrefs();
    return prefs.getBool(keyScoreHistoryTutorialShown) ?? false;
  }

  static Future<void> setScoreHistoryTutorialShown(bool shown) async {
    final prefs = await _getPrefs();
    await prefs.setBool(keyScoreHistoryTutorialShown, shown);
  }

  static Future<bool> getLiveMatchTutorialShown() async {
    final prefs = await _getPrefs();
    return prefs.getBool(keyLiveMatchTutorialShown) ?? false;
  }

  static Future<void> setLiveMatchTutorialShown(bool shown) async {
    final prefs = await _getPrefs();
    await prefs.setBool(keyLiveMatchTutorialShown, shown);
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

  static Future<void> decrementMatchesCompletedCount() async {
    final prefs = await _getPrefs();
    final current = prefs.getInt(keyMatchesCompletedCount) ?? 0;
    await prefs.setInt(
      keyMatchesCompletedCount,
      current > 0 ? current - 1 : 0,
    );
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

  static Future<int> getVasoAdsWatched() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyVasoAdsWatched) ?? 0;
  }

  static Future<void> setVasoAdsWatched(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyVasoAdsWatched, count);
  }

  static Future<int> getVasoLastAdAt() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyVasoLastAdAt) ?? 0;
  }

  static Future<void> setVasoLastAdAt(int millis) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyVasoLastAdAt, millis);
  }

  static Future<int> getVasoBrindados() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyVasoBrindados) ?? 0;
  }

  static Future<void> setVasoBrindados(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyVasoBrindados, count);
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
    required String matchId,
    required DateTime matchStartedAt,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyNosotrosScore, nosotros);
    await prefs.setInt(keyEllosScore, ellos);
    await prefs.setString(keyNosotrosName, nosotrosName);
    await prefs.setString(keyEllosName, ellosName);
    await prefs.setBool(keyFinishedMalasNosotros, finishedMalasNosotros);
    await prefs.setBool(keyFinishedMalasEllos, finishedMalasEllos);
    await prefs.setString(keyCurrentMatchId, matchId);
    await prefs.setString(
        keyCurrentMatchStartedAt, matchStartedAt.toIso8601String());
  }

  static Future<List<MatchRecord>> loadMatchHistory() async {
    final prefs = await _getPrefs();
    final serialized = prefs.getStringList(keyMatchHistory) ?? const [];
    final records = <MatchRecord>[];
    for (final value in serialized) {
      try {
        records.add(MatchRecord.decode(value));
      } catch (_) {
        // Ignorar registros dañados sin perder el resto del historial.
      }
    }
    records.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return records;
  }

  static Future<void> saveCompletedMatch(MatchRecord record) async {
    final prefs = await _getPrefs();
    final records = await loadMatchHistory();
    records.removeWhere((item) => item.id == record.id);
    records.insert(0, record);
    await prefs.setStringList(
      keyMatchHistory,
      records.take(100).map((item) => item.encode()).toList(),
    );
  }

  static Future<void> deleteCompletedMatch(String id) async {
    final prefs = await _getPrefs();
    final records = await loadMatchHistory();
    records.removeWhere((item) => item.id == id);
    await prefs.setStringList(
        keyMatchHistory, records.map((item) => item.encode()).toList());
  }

  static Future<void> clearMatchHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyMatchHistory);
  }

  static Future<void> saveScoreHistory(List<String> serialized) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(keyScoreHistory, serialized);
  }

  static Future<List<String>> loadScoreHistory() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(keyScoreHistory) ?? [];
  }

  static Future<void> clearGameState() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyNosotrosScore);
    await prefs.remove(keyEllosScore);
    await prefs.remove(keyFinishedMalasNosotros);
    await prefs.remove(keyFinishedMalasEllos);
    await prefs.remove(keyScoreHistory);
    await prefs.remove(keyCurrentMatchId);
    await prefs.remove(keyCurrentMatchStartedAt);
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
      keyCurrentMatchId: prefs.getString(keyCurrentMatchId),
      keyCurrentMatchStartedAt: prefs.getString(keyCurrentMatchStartedAt),
    };
  }
}
