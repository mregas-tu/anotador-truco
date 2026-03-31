import 'package:flutter/material.dart';
import '../services/audio_service.dart';

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

const List<GameMode> availableModes = [
  GameMode(label: "12 puntos (12 malas)", totalPoints: 12, hasBuenas: false),
  GameMode(label: "15 puntos (15 malas)", totalPoints: 15, hasBuenas: false),
  GameMode(label: "18 puntos (18 malas)", totalPoints: 18, hasBuenas: false),
  GameMode(label: "20 puntos (20 malas)", totalPoints: 20, hasBuenas: false),
  GameMode(label: "18 puntos (9 malas + 9 buenas)", totalPoints: 18, hasBuenas: true),
  GameMode(label: "20 puntos (10 malas + 10 buenas)", totalPoints: 20, hasBuenas: true),
  GameMode(label: "24 puntos (12 malas + 12 buenas)", totalPoints: 24, hasBuenas: true),
  GameMode(label: "30 puntos (15 malas + 15 buenas)", totalPoints: 30, hasBuenas: true),
  GameMode(label: "40 puntos (20 malas + 20 buenas)", totalPoints: 40, hasBuenas: true),
];

class ScoreProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  GameMode _currentGameMode = availableModes[7]; // Default to 30 pts (15+15)
  bool _isMuted = false;
  int _nosotros = 0;
  int _ellos = 0;
  String _nosotrosName = "NOSOTROS";
  String _ellosName = "ELLOS";
  int _totalRemainingMatchsticks = 60;
  Offset? _lastDropOffset;
  String? _lastPointTeam;
  bool _isResetting = false;
  bool _nosotrosResetting = false;
  bool _ellosResetting = false;
  bool _nosotrosWaiting = false;
  bool _ellosWaiting = false;
  
  bool _nosotrosFinishedMalas = false;
  bool _ellosFinishedMalas = false;

  String? _winner;

  Offset? _lastStickPosNosotros;
  Offset? _lastStickPosEllos;
  bool _isDraggingBackNosotros = false;
  bool _isDraggingBackEllos = false;
  
  // Revert animation state
  Offset? _revertOffset;
  String? _revertTeam;
  bool _isReverting = false;

  GameMode get currentGameMode => _currentGameMode;
  bool get isMuted => _isMuted;
  int get nosotros => _nosotros;
  int get ellos => _ellos;
  String get nosotrosName => _nosotrosName;
  String get ellosName => _ellosName;
  int get maxScore => _currentGameMode.totalPoints;
  String? get winner => _winner;
  int get totalRemainingMatchsticks => _totalRemainingMatchsticks;
  Offset? get lastDropOffset => _lastDropOffset;
  String? get lastPointTeam => _lastPointTeam;
  bool get isResetting => _isResetting;
  bool get nosotrosResetting => _nosotrosResetting || _isResetting;
  bool get ellosResetting => _ellosResetting || _isResetting;
  bool get nosotrosShowMilestone => _nosotrosWaiting || _nosotrosResetting || _isResetting;
  bool get ellosShowMilestone => _ellosWaiting || _ellosResetting || _isResetting;
  
  Offset? get lastStickPosNosotros => _lastStickPosNosotros;
  Offset? get lastStickPosEllos => _lastStickPosEllos;
  bool get isDraggingBackNosotros => _isDraggingBackNosotros;
  bool get isDraggingBackEllos => _isDraggingBackEllos;
  Offset? get revertOffset => _revertOffset;
  String? get revertTeam => _revertTeam;
  bool get isReverting => _isReverting;

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
      if (!_isMuted) _audioService.playStick(); // Play lift sound
    }
    notifyListeners();
  }

  Future<void> triggerRevert(String team, Offset fromOffset) async {
    _revertTeam = team;
    _revertOffset = fromOffset;
    _isReverting = true;
    
    if (team == "nosotros") _isDraggingBackNosotros = true;
    else _isDraggingBackEllos = true;
    
    notifyListeners();
    
    // Wait for fly-back animation (400ms)
    await Future.delayed(const Duration(milliseconds: 400));
    
    _isReverting = false;
    _revertTeam = null;
    _revertOffset = null;
    
    if (team == "nosotros") _isDraggingBackNosotros = false;
    else _isDraggingBackEllos = false;
    
    _audioService.playStick(); // Play return/click sound
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
        _nosotrosWaiting = true;
        if (!_isMuted) _audioService.playStick();
        notifyListeners();
        // Wait for landing animation
        await Future.delayed(const Duration(milliseconds: 500));
        
        _nosotrosWaiting = false;
        _nosotrosResetting = true;
        if (!_isMuted) _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation
        await Future.delayed(const Duration(milliseconds: 700));
        _nosotrosResetting = false;
        _nosotrosFinishedMalas = true;
      } else if (_nosotros == _currentGameMode.totalPoints) {
        _winner = "nosotros";
        if (!_isMuted) _audioService.playStick();
      } else {
        if (!_isMuted) _audioService.playStick();
      }
      notifyListeners();
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
    }
  }

  void addPointEllos([Offset? dropOffset]) async {
    if (_ellos < _currentGameMode.totalPoints && _winner == null && _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";

      if (_currentGameMode.hasBuenas && _ellos == _currentGameMode.milestone) {
        _ellosWaiting = true;
        if (!_isMuted) _audioService.playStick();
        notifyListeners();
        // Wait for landing animation
        await Future.delayed(const Duration(milliseconds: 500));

        _ellosWaiting = false;
        _ellosResetting = true;
        if (!_isMuted) _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation
        await Future.delayed(const Duration(milliseconds: 700));
        _ellosResetting = false;
        _ellosFinishedMalas = true;
      } else if (_ellos == _currentGameMode.totalPoints) {
        _winner = "ellos";
        if (!_isMuted) _audioService.playStick();
      } else {
        if (!_isMuted) _audioService.playStick();
      }
      notifyListeners();
    }
  }

  void setTeamName(String team, String name) {
    if (team == "nosotros") {
      _nosotrosName = name.trim().toUpperCase();
    } else {
      _ellosName = name.trim().toUpperCase();
    }
    notifyListeners();
  }

  Future<void> triggerReset({bool keepNames = true}) async {
    _isResetting = true;
    if (!_isMuted) _audioService.playClear();
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
    _totalRemainingMatchsticks = _currentGameMode.totalPoints * 2;
    _lastDropOffset = null;
    _lastPointTeam = null;
    _isResetting = false;
    notifyListeners();
  }

  void setGameMode(GameMode mode) {
    _currentGameMode = mode;
    triggerReset(keepNames: true);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    notifyListeners();
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
    }
  }

  void reset() {
    _nosotros = 0;
    _ellos = 0;
    notifyListeners();
  }

  // Eliminated setMaxScore - handled by setGameMode
}
