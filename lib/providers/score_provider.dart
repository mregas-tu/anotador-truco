import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';
import '../services/persistence_service.dart';
import '../theme/app_theme.dart';

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
];

const List<GameMode> availableModes = [
  GameMode(label: "12 puntos - 12 malas", totalPoints: 12, hasBuenas: false),
  GameMode(label: "15 puntos - 15 malas", totalPoints: 15, hasBuenas: false),
  GameMode(label: "20 puntos - 20 malas", totalPoints: 20, hasBuenas: false),
  GameMode(label: "24 puntos - 12/12", totalPoints: 24, hasBuenas: true),
  GameMode(label: "30 puntos - 15/15", totalPoints: 30, hasBuenas: true),
  GameMode(label: "40 puntos - 20/20", totalPoints: 40, hasBuenas: true),
];

enum ScoringMode { drag, tap }
enum PointType { matches, beans }

class ScoreProvider with ChangeNotifier {
  final AudioService audioService = AudioService();
  GameMode _currentGameMode = availableModes[4]; // Default to 30 pts (15/15)
  MatchstickPalette _currentPalette = availablePalettes[1]; // Default to BORDÓ
  BeanPalette _currentBeanPalette = availableBeanPalettes[0]; // Default to ALUBIA
  ScoringMode _scoringMode = ScoringMode.drag;
  TrucoTheme _appTheme = TrucoTheme.navyTheme;
  bool _isMuted = false;
  bool _picaPicaEnabled = false;
  int _picaPicaStart = 5;
  int _picaPicaEnd = 20;
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

  GameMode get currentGameMode => _currentGameMode;
  MatchstickPalette get currentPalette => _currentPalette;
  BeanPalette get currentBeanPalette => _currentBeanPalette;
  ScoringMode get scoringMode => _scoringMode;
  bool get isMuted => _isMuted;
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
    if (isDragging) {
      if (!_isMuted) audioService.playMarker(_pointType == PointType.beans); // Play lift sound
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

  Future<void> triggerRevert(String team, Offset fromOffset) async {
    _revertTeam = team;
    _revertOffset = fromOffset;
    _isReverting = true;
    
    if (team == "nosotros") _isDraggingBackNosotros = false;
    else _isDraggingBackEllos = false;
    
    notifyListeners();
    
    // Wait for fly-back animation (400ms)
    await Future.delayed(const Duration(milliseconds: 400));
    
    _isReverting = false;
    _revertTeam = null;
    _revertOffset = null;
    
    if (team == "nosotros") _isDraggingBackNosotros = false;
    else _isDraggingBackEllos = false;
    
    if (!_isMuted) audioService.playMarker(_pointType == PointType.beans); // Play return/click sound
    notifyListeners();
  }

  bool isBuenas(String team) {
    if (!_currentGameMode.hasBuenas) return false;
    final int score = team == "nosotros" ? _nosotros : _ellos;
    final bool finishedMalas = team == "nosotros" ? _nosotrosFinishedMalas : _ellosFinishedMalas;
    return score > _currentGameMode.milestone || (score == _currentGameMode.milestone && finishedMalas);
  }

  int getDisplayPoints(String team) {
    final int score = team == "nosotros" ? _nosotros : _ellos;
    final bool finishedMalas = team == "nosotros" ? _nosotrosFinishedMalas : _ellosFinishedMalas;
    
    if (score == 0) return 0;
    
    if (!_currentGameMode.hasBuenas) return score;

    final int milestone = _currentGameMode.milestone;
    if (score < milestone) return score;
    if (score == milestone) return finishedMalas ? 0 : milestone;
    if (score == _currentGameMode.totalPoints) return milestone;
    return score - milestone;
  }

  String getLabel(String team) {
    return isBuenas(team) ? "BUENAS" : "MALAS";
  }

  void addPointNosotros([Offset? dropOffset]) async {
    if (_nosotros < _currentGameMode.totalPoints && _winner == null && _totalRemainingMatchsticks > 0) {
      _nosotros++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "nosotros";

      if (_currentGameMode.hasBuenas && _nosotros == _currentGameMode.milestone) {
        if (!_isMuted) audioService.playBuenas();
        _nosotrosFinishedMalas = true;
      } else if (_nosotros == _currentGameMode.totalPoints) {
        _winner = "nosotros";
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      } else {
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      }
      notifyListeners();
      _saveCurrentState();
    }
  }

  void removePointNosotros() {
    if (_nosotros > 0) {
      if (_currentGameMode.hasBuenas && _nosotros == _currentGameMode.milestone) {
        _nosotrosFinishedMalas = false;
      }
      _nosotros--;
      _winner = null; // Clear winner if score decreased
      _totalRemainingMatchsticks++;
      notifyListeners();
      _saveCurrentState();
    }
  }

  void addPointEllos([Offset? dropOffset]) async {
    if (_ellos < _currentGameMode.totalPoints && _winner == null && _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";

      if (_currentGameMode.hasBuenas && _ellos == _currentGameMode.milestone) {
        if (!_isMuted) audioService.playBuenas();
        _ellosFinishedMalas = true;
      } else if (_ellos == _currentGameMode.totalPoints) {
        _winner = "ellos";
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      } else {
        if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
      }
      notifyListeners();
      _saveCurrentState();
    }
  }

  void removePointEllos() {
    if (_ellos > 0) {
      if (_currentGameMode.hasBuenas && _ellos == _currentGameMode.milestone) {
        _ellosFinishedMalas = false;
      }
      _ellos--;
      _winner = null; // Clear winner if score decreased
      _totalRemainingMatchsticks++;
      notifyListeners();
      _saveCurrentState();
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
    _totalRemainingMatchsticks = (_currentGameMode.totalPoints * 2);
    _lastDropOffset = null;
    _lastPointTeam = null;
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
    
    // Actually remove the point after animation
    if (team == "nosotros") {
      removePointNosotros();
    } else {
      removePointEllos();
    }
    
    if (!_isMuted) audioService.playMarker(_pointType == PointType.beans);
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
      _picaPicaStart = (_picaPicaEnd - 5).clamp(0, _currentGameMode.totalPoints);
    }

    triggerReset(keepNames: true);
    _saveCurrentSettings();
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setAppTheme(TrucoTheme theme) {
    _appTheme = theme;
    AnalyticsService.logThemeChanged(theme.name);
    notifyListeners();
    _saveCurrentSettings();
  }

  void setPalette(MatchstickPalette palette) {
    _currentPalette = palette;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setBeanPalette(BeanPalette beanPalette) {
    _currentBeanPalette = beanPalette;
    notifyListeners();
    _saveCurrentSettings();
  }

  void setPointType(PointType type) {
    _pointType = type;
    notifyListeners();
    _saveCurrentSettings();
  }

  void _saveCurrentState() {
    PersistenceService.saveGameState(
      nosotros: _nosotros,
      ellos: _ellos,
      nosotrosName: _nosotrosName,
      ellosName: _ellosName,
      finishedMalasNosotros: _nosotrosFinishedMalas,
      finishedMalasEllos: _ellosFinishedMalas,
    );
  }

  void _saveCurrentSettings() {
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
    );
  }

  Future<void> restoreGame(Map<String, dynamic> data) async {
    _nosotros = data[PersistenceService.keyNosotrosScore] ?? 0;
    _ellos = data[PersistenceService.keyEllosScore] ?? 0;
    _nosotrosName = data[PersistenceService.keyNosotrosName] ?? "NOSOTROS";
    _ellosName = data[PersistenceService.keyEllosName] ?? "ELLOS";
    _nosotrosFinishedMalas = data[PersistenceService.keyFinishedMalasNosotros] ?? false;
    _ellosFinishedMalas = data[PersistenceService.keyFinishedMalasEllos] ?? false;
    
    // Recalculate matchsticks based on scores
    _totalRemainingMatchsticks = (_currentGameMode.totalPoints * 2) - _nosotros - _ellos;
    
    notifyListeners();
    _saveCurrentState();
  }

  Future<void> loadSettings() async {
    final data = await PersistenceService.loadAll();
    
    if (data[PersistenceService.keyGameModeIndex] != null) {
      _currentGameMode = availableModes[data[PersistenceService.keyGameModeIndex]];
    }
    if (data[PersistenceService.keyThemeId] != null) {
      _appTheme = TrucoTheme.allThemes.firstWhere(
        (t) => t.name == data[PersistenceService.keyThemeId],
        orElse: () => TrucoTheme.navyTheme,
      );
    }
    if (data[PersistenceService.keyPaletteIndex] != null) {
      _currentPalette = availablePalettes[data[PersistenceService.keyPaletteIndex]];
    }
    if (data[PersistenceService.keyBeanPaletteIndex] != null) {
      _currentBeanPalette = availableBeanPalettes[data[PersistenceService.keyBeanPaletteIndex]];
    }
    if (data[PersistenceService.keyScoringMode] != null) {
      _scoringMode = data[PersistenceService.keyScoringMode] == ScoringMode.tap.name 
          ? ScoringMode.tap 
          : ScoringMode.drag;
    }
    if (data[PersistenceService.keyIsMuted] != null) {
      _isMuted = data[PersistenceService.keyIsMuted];
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

    notifyListeners();
  }

  void reset() {
    _nosotros = 0;
    _ellos = 0;
    notifyListeners();
  }
}
