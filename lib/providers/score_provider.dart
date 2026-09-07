import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';
import '../services/persistence_service.dart';
import '../theme/app_theme.dart';
import '../services/bean_image_manager.dart';
import 'premium_provider.dart';
import '../models/match_record.dart';
import '../models/live_match_state.dart';
import '../services/live_match_service.dart';

/// Pure malas/buenas display rules, shared by the host scoreboard
/// (via [ScoreProvider]) and the live spectator view, so both always
/// agree on when a team switches from "malas" to "buenas" and what
/// number/label to show.
class ScorePhase {
  static bool isBuenas({
    required int score,
    required int milestone,
    required bool hasBuenas,
    required bool finishedMalas,
  }) {
    if (!hasBuenas) return false;
    return score > milestone || (score == milestone && finishedMalas);
  }

  static int displayPoints({
    required int score,
    required int milestone,
    required bool hasBuenas,
    required bool finishedMalas,
  }) {
    if (score == 0) return 0;
    if (!hasBuenas) return score;
    if (score < milestone) return score;
    if (score == milestone) return finishedMalas ? 0 : milestone;
    return score - milestone;
  }

  static String label({
    required int score,
    required int milestone,
    required bool hasBuenas,
    required bool finishedMalas,
  }) {
    return isBuenas(
      score: score,
      milestone: milestone,
      hasBuenas: hasBuenas,
      finishedMalas: finishedMalas,
    )
        ? 'BUENAS'
        : 'MALAS';
  }
}

class ScoreEvent {
  final String team;
  final int delta;
  final DateTime timestamp;
  final int nosotrosTotal;
  final int ellosTotal;

  const ScoreEvent({
    required this.team,
    required this.delta,
    required this.timestamp,
    required this.nosotrosTotal,
    required this.ellosTotal,
  });
}

class GameMode {
  final String label;
  final int totalPoints;
  final bool hasBuenas;

  const GameMode({
    required this.label,
    required this.totalPoints,
    required this.hasBuenas,
  });

  int get milestone => hasBuenas ? (totalPoints / 2).floor() : totalPoints;
}

class MatchstickPalette {
  final String name;
  final List<Color> headColors;

  const MatchstickPalette({required this.name, required this.headColors});
}

const List<MatchstickPalette> availablePalettes = [
  MatchstickPalette(
    name: "ROJO CLÁSICO",
    headColors: [Color(0xFFFF5252), Color(0xFFD32F2F), Color(0xFF8B0000)],
  ),
  MatchstickPalette(
    name: "BORDÓ",
    headColors: [Color(0xFFB03A2E), Color(0xFF7B241C), Color(0xFF4D1111)],
  ),
  MatchstickPalette(
    name: "AZUL NOCHE",
    headColors: [Color(0xFF2E86C1), Color(0xFF1B4F72), Color(0xFF0E2F44)],
  ),
  MatchstickPalette(
    name: "BOSQUE",
    headColors: [Color(0xFF229954), Color(0xFF186A3B), Color(0xFF0B3B17)],
  ),
  MatchstickPalette(
    name: "ORO",
    headColors: [Color(0xFFD4AC0D), Color(0xFF9A7D0A), Color(0xFF7D6608)],
  ),
  MatchstickPalette(
    name: "VIOLETA",
    headColors: [Color(0xFFAF7AC5), Color(0xFF884EA0), Color(0xFF4A235A)],
  ),
  MatchstickPalette(
    name: "NARANJA",
    headColors: [Color(0xFFF39C12), Color(0xFFD35400), Color(0xFF873600)],
  ),
  MatchstickPalette(
    name: "ROSA",
    headColors: [Color(0xFFF06292), Color(0xFFE91E63), Color(0xFF880E4F)],
  ),
  MatchstickPalette(
    name: "CIAN",
    headColors: [Color(0xFF4DD0E1), Color(0xFF00BCD4), Color(0xFF006064)],
  ),
  MatchstickPalette(
    name: "LIMA",
    headColors: [Color(0xFFDCE775), Color(0xFFCDDC39), Color(0xFF827717)],
  ),
  MatchstickPalette(
    name: "TURQUESA",
    headColors: [Color(0xFF4DB6AC), Color(0xFF009688), Color(0xFF004D40)],
  ),
  MatchstickPalette(
    name: "CHOCOLATE",
    headColors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
  ),
  MatchstickPalette(
    name: "GRIS METAL",
    headColors: [Color(0xFFB0BEC5), Color(0xFF607D8B), Color(0xFF263238)],
  ),
  MatchstickPalette(
    name: "MENTA",
    headColors: [Color(0xFFA9DFBF), Color(0xFF52BE80), Color(0xFF1E8449)],
  ),
  MatchstickPalette(
    name: "COBRE",
    headColors: [Color(0xFFDC7633), Color(0xFFA04000), Color(0xFF6E2C00)],
  ),
];

enum BeanType {
  alubia,
  negro,
  fideo,
  pinto,
  manteca,
  bandera,
  cisne,
  borlotto,
  magnum,
  frutilla,
  arveja,
  lenteja,
  ojonegro,
  garbanzo,
  soja,
}

class BeanPalette {
  final String name;
  final BeanType type;

  const BeanPalette({required this.name, required this.type});
}

const List<BeanPalette> availableBeanPalettes = [
  BeanPalette(name: "ALUBIA", type: BeanType.alubia),
  BeanPalette(name: "NEGRO", type: BeanType.negro),
  BeanPalette(name: "FIDEO", type: BeanType.fideo),
  BeanPalette(name: "PINTO", type: BeanType.pinto),
  BeanPalette(name: "MANTECA", type: BeanType.manteca),
  BeanPalette(name: "BANDERA", type: BeanType.bandera),
  BeanPalette(name: "CISNE", type: BeanType.cisne),
  BeanPalette(name: "BORLOTTO", type: BeanType.borlotto),
  BeanPalette(name: "MAGNUM", type: BeanType.magnum),
  BeanPalette(name: "FRUTILLA", type: BeanType.frutilla),
  BeanPalette(name: "ARVEJA", type: BeanType.arveja),
  BeanPalette(name: "LENTEJA", type: BeanType.lenteja),
  BeanPalette(name: "OJO NEGRO", type: BeanType.ojonegro),
  BeanPalette(name: "GARBANZO", type: BeanType.garbanzo),
  BeanPalette(name: "SOJA", type: BeanType.soja),
];

const List<GameMode> availableModes = [
  GameMode(label: "12 puntos - 12 malas", totalPoints: 12, hasBuenas: false),
  GameMode(label: "15 puntos - 15 malas", totalPoints: 15, hasBuenas: false),
  GameMode(label: "20 puntos - 20 malas", totalPoints: 20, hasBuenas: false),
  GameMode(label: "24 puntos - 12/12", totalPoints: 24, hasBuenas: true),
  GameMode(label: "30 puntos - 15/15", totalPoints: 30, hasBuenas: true),
  GameMode(label: "40 puntos - 20/20", totalPoints: 40, hasBuenas: true),
];

enum ScoringMode { drag, tap, classic }

enum PointType { matches, beans }

class ScoreProvider with ChangeNotifier {
  final AudioService audioService = AudioService();
  GameMode _currentGameMode = availableModes[4]; // Default to 30 pts (15/15)
  MatchstickPalette _currentPalette = availablePalettes[1]; // Default to BORDÓ
  BeanPalette _currentBeanPalette =
      availableBeanPalettes[0]; // Default to ALUBIA
  ScoringMode _scoringMode = ScoringMode.drag;
  TrucoTheme _appTheme = TrucoTheme.navyTheme;
  bool _isMuted = false;
  bool _vibrationEnabled = true;
  bool _picaPicaEnabled = false;
  int _picaPicaStart = 5;
  int _picaPicaEnd = 20;
  bool _picaPicaStartTriggered = false;
  bool _picaPicaEndTriggered = false;
  final StreamController<String> _picaPicaEventsController =
      StreamController<String>.broadcast();
  Stream<String> get picaPicaEvents => _picaPicaEventsController.stream;
  int _nosotros = 0;
  int _ellos = 0;
  String _nosotrosName = "NOSOTROS";
  String _ellosName = "ELLOS";
  int _totalRemainingMatchsticks = 60; // Initial for 30pts
  Offset? _lastDropOffset;
  String? _lastPointTeam;
  bool _isResetting = false;
  bool _nosotrosFinishedMalas = false;
  bool _ellosFinishedMalas = false;
  PointType _pointType = PointType.matches;

  String? _winner;

  Offset? _lastStickPosNosotros;
  Offset? _lastStickPosEllos;
  bool _isDraggingBackNosotros = false;
  bool _isDraggingBackEllos = false;

  // Revert animation state
  Offset? _revertOffset;
  String? _revertTeam;
  bool _isReverting = false;

  // Fly-out animation state (Fly to box)
  Offset? _flyOutTarget;
  String? _flyOutTeam;
  bool _isFlyingOut = false;

  final List<ScoreEvent> _scoreHistory = [];
  String _matchId = DateTime.now().microsecondsSinceEpoch.toString();
  DateTime _matchStartedAt = DateTime.now();
  bool _isLiveHosting = false;
  bool _isPublishingLive = false;
  bool _hasPendingLivePublish = false;
  int _publishedLiveEventCount = 0;
  String? _watchingLiveMatchId;
  List<ScoreEvent> get scoreHistory => List.unmodifiable(_scoreHistory);

  GameMode get currentGameMode => _currentGameMode;
  MatchstickPalette get currentPalette => _currentPalette;
  BeanPalette get currentBeanPalette => _currentBeanPalette;
  ScoringMode get scoringMode => _scoringMode;
  bool get isMuted => _isMuted;
  bool get vibrationEnabled => _vibrationEnabled;
  int get nosotros => _nosotros;
  int get ellos => _ellos;
  String get nosotrosName => _nosotrosName;
  String get ellosName => _ellosName;
  TrucoTheme get appTheme => _appTheme;
  bool get picaPicaEnabled => _picaPicaEnabled;
  int get picaPicaStart => _picaPicaStart;
  int get picaPicaEnd => _picaPicaEnd;
  int get maxScore => _currentGameMode.totalPoints;
  String? get winner => _winner;
  int get totalRemainingMatchsticks => _totalRemainingMatchsticks;
  Offset? get lastDropOffset => _lastDropOffset;
  String? get lastPointTeam => _lastPointTeam;
  bool get isResetting => _isResetting;
  bool get nosotrosShowMilestone => _isResetting;
  bool get ellosShowMilestone => _isResetting;

  Offset? get lastStickPosNosotros => _lastStickPosNosotros;
  Offset? get lastStickPosEllos => _lastStickPosEllos;
  bool get isDraggingBackNosotros => _isDraggingBackNosotros;
  bool get isDraggingBackEllos => _isDraggingBackEllos;
  Offset? get revertOffset => _revertOffset;
  String? get revertTeam => _revertTeam;
  bool get isReverting => _isReverting;

  Offset? get flyOutTarget => _flyOutTarget;
  String? get flyOutTeam => _flyOutTeam;
  bool get isFlyingOut => _isFlyingOut;
  PointType get pointType => _pointType;
  String get matchId => _matchId;
  bool get isLiveHosting => _isLiveHosting;
  String? get watchingLiveMatchId => _watchingLiveMatchId;
  String? get liveShareValue =>
      _isLiveHosting ? LiveMatchService.buildShareValue(_matchId) : null;

  void _recordEvent(String team, int delta) {
    _scoreHistory.add(ScoreEvent(
      team: team,
      delta: delta,
      timestamp: DateTime.now(),
      nosotrosTotal: _nosotros,
      ellosTotal: _ellos,
    ));
    PersistenceService.saveScoreHistory(
      _scoreHistory
          .map((e) =>
              '${e.team}:${e.delta}:${e.timestamp.millisecondsSinceEpoch}:${e.nosotrosTotal}:${e.ellosTotal}')
          .toList(),
    );
  }

  Future<void> _archiveCompletedMatch() async {
    final winner = _winner;
    if (winner == null) return;
    await PersistenceService.saveCompletedMatch(MatchRecord(
      id: _matchId,
      startedAt: _matchStartedAt,
      finishedAt: DateTime.now(),
      nosotrosName: _nosotrosName,
      ellosName: _ellosName,
      nosotrosScore: _nosotros,
      ellosScore: _ellos,
      targetScore: _currentGameMode.totalPoints,
      hasBuenas: _currentGameMode.hasBuenas,
      winner: winner,
      events: _scoreHistory
          .map((event) => MatchPointEvent(
                team: event.team,
                delta: event.delta,
                timestamp: event.timestamp,
                nosotrosTotal: event.nosotrosTotal,
                ellosTotal: event.ellosTotal,
              ))
          .toList(),
    ));
  }

  LiveMatchState _buildLiveState({
    bool? isLiveOverride,
    bool stoppedByHost = false,
  }) {
    final now = DateTime.now();
    return LiveMatchState(
      id: _matchId,
      nosotrosName: _nosotrosName,
      ellosName: _ellosName,
      nosotrosScore: _nosotros,
      ellosScore: _ellos,
      targetScore: _currentGameMode.totalPoints,
      hasBuenas: _currentGameMode.hasBuenas,
      nosotrosFinishedMalas: _nosotrosFinishedMalas,
      ellosFinishedMalas: _ellosFinishedMalas,
      themeName: _appTheme.name,
      pointType: _pointType.name,
      paletteName: _pointType == PointType.beans
          ? _currentBeanPalette.name
          : _currentPalette.name,
      gameModeLabel: _currentGameMode.label,
      winner: _winner,
      finished: _winner != null,
      isLive: isLiveOverride ?? _isLiveHosting,
      stoppedByHost: stoppedByHost,
      createdAt: _matchStartedAt,
      updatedAt: now,
    );
  }

  Future<void> startLiveHosting() async {
    await LiveMatchService.createMatch(_buildLiveState(isLiveOverride: true));
    _isLiveHosting = true;
    _publishedLiveEventCount = 0;
    _publishPendingLiveEvents();
    notifyListeners();
  }

  Future<void> stopLiveHosting() async {
    if (_isLiveHosting) {
      await LiveMatchService.cancelHostPresence(_matchId).catchError((_) {});
      await LiveMatchService.updateMatch(_buildLiveState(
        isLiveOverride: false,
        stoppedByHost: true,
      )).catchError((_) {});
    }
    _isLiveHosting = false;
    notifyListeners();
  }

  void startWatchingLiveMatch(String matchId) {
    _watchingLiveMatchId = matchId;
    notifyListeners();
  }

  void stopWatchingLiveMatch() {
    _watchingLiveMatchId = null;
    notifyListeners();
  }

  void _publishLiveState() {
    if (!_isLiveHosting) return;
    if (_isPublishingLive) {
      _hasPendingLivePublish = true;
      return;
    }
    _isPublishingLive = true;
    LiveMatchService.updateMatch(_buildLiveState())
        .catchError((_) {})
        .whenComplete(
      () {
        _isPublishingLive = false;
        if (_hasPendingLivePublish) {
          _hasPendingLivePublish = false;
          _publishLiveState();
        }
        _publishPendingLiveEvents();
      },
    );
  }

  void _publishPendingLiveEvents() {
    if (!_isLiveHosting) return;
    while (_publishedLiveEventCount < _scoreHistory.length) {
      final index = _publishedLiveEventCount;
      final event = _scoreHistory[index];
      _publishedLiveEventCount++;
      LiveMatchService.addEvent(
        matchId: _matchId,
        event: LiveMatchPointEvent(
          index: index + 1,
          team: event.team,
          delta: event.delta,
          timestamp: event.timestamp,
          nosotrosTotal: event.nosotrosTotal,
          ellosTotal: event.ellosTotal,
        ),
      ).catchError((_) {
        if (_publishedLiveEventCount > index) {
          _publishedLiveEventCount = index;
        }
      });
    }
  }

  void updateLastStickPos(String team, Offset pos) {
    if (team == "nosotros") {
      if (_lastStickPosNosotros == pos) return;
      _lastStickPosNosotros = pos;
    } else {
      if (_lastStickPosEllos == pos) return;
      _lastStickPosEllos = pos;
    }
    notifyListeners();
  }

  void setDraggingBack(String team, bool isDragging) {
    if (team == "nosotros") {
      _isDraggingBackNosotros = isDragging;
    } else {
      _isDraggingBackEllos = isDragging;
    }
    notifyListeners();
  }

  void setPicaPicaEnabled(bool enabled) {
    _picaPicaEnabled = enabled;
    _saveCurrentSettings();
    notifyListeners();
  }

  void setPicaPicaRange(int start, int end) {
    _picaPicaStart = start;
    _picaPicaEnd = end;
    _saveCurrentSettings();
    notifyListeners();
  }

  void _checkPicaPicaCross() {
    if (!_picaPicaEnabled) return;
    final int maxScore = _nosotros > _ellos ? _nosotros : _ellos;
    if (!_picaPicaStartTriggered && maxScore >= _picaPicaStart) {
      _picaPicaStartTriggered = true;
      _picaPicaEventsController.add('start');
    }
    if (!_picaPicaEndTriggered && maxScore >= _picaPicaEnd) {
      _picaPicaEndTriggered = true;
      _picaPicaEventsController.add('end');
    }
  }

  void _vibrate() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> triggerRevert(String team, Offset fromOffset) async {
    _revertTeam = team;
    _revertOffset = fromOffset;
    _isReverting = true;

    if (team == "nosotros")
      _isDraggingBackNosotros = false;
    else
      _isDraggingBackEllos = false;

    notifyListeners();

    // Wait for fly-back animation (400ms)
    await Future.delayed(const Duration(milliseconds: 400));

    _isReverting = false;
    _revertTeam = null;
    _revertOffset = null;

    if (team == "nosotros")
      _isDraggingBackNosotros = false;
    else
      _isDraggingBackEllos = false;

    notifyListeners();
  }

  bool isBuenas(String team) {
    final int score = team == "nosotros" ? _nosotros : _ellos;
    final bool finishedMalas =
        team == "nosotros" ? _nosotrosFinishedMalas : _ellosFinishedMalas;
    return ScorePhase.isBuenas(
      score: score,
      milestone: _currentGameMode.milestone,
      hasBuenas: _currentGameMode.hasBuenas,
      finishedMalas: finishedMalas,
    );
  }

  int getDisplayPoints(String team) {
    final int score = team == "nosotros" ? _nosotros : _ellos;
    final bool finishedMalas =
        team == "nosotros" ? _nosotrosFinishedMalas : _ellosFinishedMalas;
    return ScorePhase.displayPoints(
      score: score,
      milestone: _currentGameMode.milestone,
      hasBuenas: _currentGameMode.hasBuenas,
      finishedMalas: finishedMalas,
    );
  }

  String getLabel(String team) {
    return isBuenas(team) ? "BUENAS" : "MALAS";
  }

  void addPointNosotros([Offset? dropOffset]) async {
    if (_nosotros < _currentGameMode.totalPoints &&
        _winner == null &&
        _totalRemainingMatchsticks > 0) {
      _nosotros++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "nosotros";
      _recordEvent("nosotros", 1);

      if (_currentGameMode.hasBuenas &&
          _nosotros == _currentGameMode.milestone) {
        if (!_isMuted) audioService.playBuenas();
        _nosotrosFinishedMalas = true;
      } else if (_nosotros == _currentGameMode.totalPoints) {
        _winner = "nosotros";
        PersistenceService.incrementMatchesCompletedCount();
        await _archiveCompletedMatch();
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      } else {
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      }
      _vibrate();
      _checkPicaPicaCross();
      notifyListeners();
      _saveCurrentState();
      _publishLiveState();
    }
  }

  void removePointNosotros() async {
    if (_nosotros > 0) {
      final wasWinner = _winner != null;
      if (_currentGameMode.hasBuenas &&
          _nosotros == _currentGameMode.milestone) {
        _nosotrosFinishedMalas = false;
      }
      if (!_isMuted) audioService.playPack(_pointType == PointType.beans);
      _nosotros--;
      _winner = null; // Clear winner if score decreased
      if (wasWinner) {
        await PersistenceService.deleteCompletedMatch(_matchId);
        await PersistenceService.decrementMatchesCompletedCount();
      }
      _totalRemainingMatchsticks++;
      _recordEvent("nosotros", -1);
      _vibrate();
      notifyListeners();
      _saveCurrentState();
      _publishLiveState();
    }
  }

  void addPointEllos([Offset? dropOffset]) async {
    if (_ellos < _currentGameMode.totalPoints &&
        _winner == null &&
        _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";
      _recordEvent("ellos", 1);

      if (_currentGameMode.hasBuenas && _ellos == _currentGameMode.milestone) {
        if (!_isMuted) audioService.playBuenas();
        _ellosFinishedMalas = true;
      } else if (_ellos == _currentGameMode.totalPoints) {
        _winner = "ellos";
        PersistenceService.incrementMatchesCompletedCount();
        await _archiveCompletedMatch();
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      } else {
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      }
      _vibrate();
      _checkPicaPicaCross();
      notifyListeners();
      _saveCurrentState();
      _publishLiveState();
    }
  }

  void removePointEllos() async {
    if (_ellos > 0) {
      final wasWinner = _winner != null;
      if (_currentGameMode.hasBuenas && _ellos == _currentGameMode.milestone) {
        _ellosFinishedMalas = false;
      }
      if (!_isMuted) audioService.playPack(_pointType == PointType.beans);
      _ellos--;
      _winner = null; // Clear winner if score decreased
      if (wasWinner) {
        await PersistenceService.deleteCompletedMatch(_matchId);
        await PersistenceService.decrementMatchesCompletedCount();
      }
      _totalRemainingMatchsticks++;
      _recordEvent("ellos", -1);
      _vibrate();
      notifyListeners();
      _saveCurrentState();
      _publishLiveState();
    }
  }

  void setTeamName(String team, String name) {
    if (team == "nosotros") {
      _nosotrosName = name.trim().toUpperCase();
    } else {
      _ellosName = name.trim().toUpperCase();
    }
    notifyListeners();
    _saveCurrentState();
    _publishLiveState();
    _pushAnalyticsContext();
  }

  Future<void> triggerReset({bool keepNames = true}) async {
    _isResetting = true;
    if (!_isMuted) audioService.playClear();
    notifyListeners();
    // Wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 600));
    _nosotros = 0;
    _ellos = 0;
    _winner = null;
    if (!keepNames) {
      _nosotrosName = "NOSOTROS";
      _ellosName = "ELLOS";
    }
    _nosotrosFinishedMalas = false;
    _ellosFinishedMalas = false;
    _picaPicaStartTriggered = false;
    _picaPicaEndTriggered = false;
    _totalRemainingMatchsticks = (_currentGameMode.totalPoints * 2);
    _lastDropOffset = null;
    _lastPointTeam = null;
    _scoreHistory.clear();
    _matchId = DateTime.now().microsecondsSinceEpoch.toString();
    _matchStartedAt = DateTime.now();
    _isLiveHosting = false;
    _isResetting = false;
    notifyListeners();
    PersistenceService.clearGameState();
  }

  Future<void> triggerFlyOut(String team, Offset targetOffset) async {
    _flyOutTeam = team;
    _flyOutTarget = targetOffset;
    _isFlyingOut = true;

    notifyListeners();

    // Wait for fly-out animation (400ms) only in drag mode
    if (_scoringMode == ScoringMode.drag) {
      await Future.delayed(const Duration(milliseconds: 400));
    }

    _isFlyingOut = false;
    _flyOutTeam = null;
    _flyOutTarget = null;

    // Actually remove the point after animation (this will trigger playPack)
    if (team == "nosotros") {
      removePointNosotros();
    } else {
      removePointEllos();
    }

    notifyListeners();
  }

  void setScoringMode(ScoringMode mode) {
    _scoringMode = mode;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setGameMode(GameMode mode) {
    _currentGameMode = mode;

    // Validate Pica Pica range against new total points
    if (_picaPicaEnd > _currentGameMode.totalPoints) {
      _picaPicaEnd = _currentGameMode.totalPoints;
    }
    if (_picaPicaStart >= _picaPicaEnd) {
      _picaPicaStart =
          (_picaPicaEnd - 5).clamp(0, _currentGameMode.totalPoints);
    }

    triggerReset(keepNames: true);
    _saveCurrentSettings();
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setAppTheme(TrucoTheme theme) {
    _appTheme = theme;
    AnalyticsService.logThemeChanged(theme.name);
    notifyListeners();
    _saveCurrentSettings();
    _publishLiveState();
  }

  void setPalette(MatchstickPalette palette) {
    _currentPalette = palette;
    notifyListeners();
    _saveCurrentSettings();
    _publishLiveState();
  }

  void setBeanPalette(BeanPalette beanPalette) {
    _currentBeanPalette = beanPalette;
    // Cachear la imagen del nuevo poroto (24 es el tamaño estándar en la mesa)
    BeanImageManager().cacheBean(beanPalette.type, 24).then((_) {
      notifyListeners();
    });
    _saveCurrentSettings();
    _publishLiveState();
  }

  void setPointType(PointType type) {
    _pointType = type;
    notifyListeners();
    _saveCurrentSettings();
    _publishLiveState();
  }

  void _saveCurrentState() {
    PersistenceService.saveGameState(
      nosotros: _nosotros,
      ellos: _ellos,
      nosotrosName: _nosotrosName,
      ellosName: _ellosName,
      finishedMalasNosotros: _nosotrosFinishedMalas,
      finishedMalasEllos: _ellosFinishedMalas,
      matchId: _matchId,
      matchStartedAt: _matchStartedAt,
    );
  }

  Map<String, dynamic> get analyticsSuperProperties => {
        'current_theme': _appTheme.name,
        'current_palette': _currentPalette.name,
        'current_bean_palette': _currentBeanPalette.name,
        'point_type': _pointType == PointType.beans ? 'porotos' : 'fosforos',
        'scoring_mode': _scoringMode.name,
        'sound_enabled': !_isMuted,
        'vibration_enabled': _vibrationEnabled,
        'pica_pica_enabled': _picaPicaEnabled,
        'current_game_mode': _currentGameMode.label,
        'has_custom_team_names':
            _nosotrosName != "NOSOTROS" || _ellosName != "ELLOS",
      };

  void _pushAnalyticsContext() {
    AnalyticsService.setSuperProperties(analyticsSuperProperties);
  }

  void _saveCurrentSettings() {
    _pushAnalyticsContext();
    PersistenceService.saveSettings(
      gameModeIndex: availableModes.indexOf(_currentGameMode),
      themeId: _appTheme.name, // Using name as ID
      paletteIndex: availablePalettes.indexOf(_currentPalette),
      beanPaletteIndex: availableBeanPalettes.indexOf(_currentBeanPalette),
      scoringMode: _scoringMode.name,
      isMuted: _isMuted,
      pointType: _pointType.name,
      picaPicaEnabled: _picaPicaEnabled,
      picaPicaStart: _picaPicaStart,
      picaPicaEnd: _picaPicaEnd,
      vibrationEnabled: _vibrationEnabled,
    );
  }

  Future<void> restoreGame(Map<String, dynamic> data) async {
    _nosotros = data[PersistenceService.keyNosotrosScore] ?? 0;
    _ellos = data[PersistenceService.keyEllosScore] ?? 0;
    _nosotrosName = data[PersistenceService.keyNosotrosName] ?? "NOSOTROS";
    _ellosName = data[PersistenceService.keyEllosName] ?? "ELLOS";
    _nosotrosFinishedMalas =
        data[PersistenceService.keyFinishedMalasNosotros] ?? false;
    _ellosFinishedMalas =
        data[PersistenceService.keyFinishedMalasEllos] ?? false;
    _matchId = data[PersistenceService.keyCurrentMatchId] ??
        DateTime.now().microsecondsSinceEpoch.toString();
    _matchStartedAt = DateTime.tryParse(
            data[PersistenceService.keyCurrentMatchStartedAt] ?? '') ??
        DateTime.now();

    // Recalculate matchsticks based on scores
    _totalRemainingMatchsticks =
        (_currentGameMode.totalPoints * 2) - _nosotros - _ellos;

    // Restore score history
    final serialized = await PersistenceService.loadScoreHistory();
    _scoreHistory.clear();
    for (final s in serialized) {
      final parts = s.split(':');
      if (parts.length == 5) {
        _scoreHistory.add(ScoreEvent(
          team: parts[0],
          delta: int.parse(parts[1]),
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
          nosotrosTotal: int.parse(parts[3]),
          ellosTotal: int.parse(parts[4]),
        ));
      }
    }

    notifyListeners();
    _saveCurrentState();
  }

  Future<void> loadSettings() async {
    final data = await PersistenceService.loadAll();

    if (data[PersistenceService.keyGameModeIndex] != null) {
      _currentGameMode =
          availableModes[data[PersistenceService.keyGameModeIndex]];
    }
    if (data[PersistenceService.keyThemeId] != null) {
      _appTheme = TrucoTheme.allThemes.firstWhere(
        (t) => t.name == data[PersistenceService.keyThemeId],
        orElse: () => TrucoTheme.navyTheme,
      );
    }
    if (data[PersistenceService.keyPaletteIndex] != null) {
      _currentPalette =
          availablePalettes[data[PersistenceService.keyPaletteIndex]];
    }
    if (data[PersistenceService.keyBeanPaletteIndex] != null) {
      _currentBeanPalette =
          availableBeanPalettes[data[PersistenceService.keyBeanPaletteIndex]];
    }
    if (data[PersistenceService.keyScoringMode] != null) {
      _scoringMode = ScoringMode.values.firstWhere(
        (mode) => mode.name == data[PersistenceService.keyScoringMode],
        orElse: () => ScoringMode.drag,
      );
    }
    if (data[PersistenceService.keyIsMuted] != null) {
      _isMuted = data[PersistenceService.keyIsMuted];
    }
    if (data[PersistenceService.keyVibrationEnabled] != null) {
      _vibrationEnabled = data[PersistenceService.keyVibrationEnabled];
    }
    if (data[PersistenceService.keyPointType] != null) {
      _pointType = data[PersistenceService.keyPointType] == PointType.beans.name
          ? PointType.beans
          : PointType.matches;
    }

    // Always load names if they exist
    if (data[PersistenceService.keyNosotrosName] != null) {
      _nosotrosName = data[PersistenceService.keyNosotrosName];
    }
    if (data[PersistenceService.keyEllosName] != null) {
      _ellosName = data[PersistenceService.keyEllosName];
    }

    _picaPicaEnabled = data[PersistenceService.keyPicaPicaEnabled] ?? false;
    _picaPicaStart = data[PersistenceService.keyPicaPicaStart] ?? 5;
    _picaPicaEnd = data[PersistenceService.keyPicaPicaEnd] ?? 20;

    // Cachear el poroto actual si estamos usando porotos
    await BeanImageManager().cacheBean(_currentBeanPalette.type, 24);

    notifyListeners();
  }

  void validatePremiumSelection(PremiumProvider premium) {
    bool changed = false;

    if (!premium.isThemeUnlocked(_appTheme.name)) {
      _appTheme = TrucoTheme.allThemes[0];
      changed = true;
    }

    int pIndex = availablePalettes.indexOf(_currentPalette);
    if (!premium.isPaletteUnlocked(pIndex)) {
      _currentPalette =
          availablePalettes[1]; // default 1 based on what they have
      changed = true;
    }

    int bpIndex = availableBeanPalettes.indexOf(_currentBeanPalette);
    if (!premium.isBeanPaletteUnlocked(bpIndex)) {
      _currentBeanPalette = availableBeanPalettes[0];
      changed = true;
    }

    if (changed) {
      _saveCurrentSettings();
      Future.microtask(() => notifyListeners());
    }
  }

  void reset() {
    _nosotros = 0;
    _ellos = 0;
    notifyListeners();
  }
}
