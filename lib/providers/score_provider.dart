import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class ScoreProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  int _nosotros = 0;
  int _ellos = 0;
  String _nosotrosName = "NOSOTROS";
  String _ellosName = "ELLOS";
  int _maxScore = 30;
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

  int get nosotros => _nosotros;
  int get ellos => _ellos;
  String get nosotrosName => _nosotrosName;
  String get ellosName => _ellosName;
  int get maxScore => _maxScore;
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
      _audioService.playStick(); // Play lift sound
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
    if (team == "nosotros") return _nosotros > 15 || (_nosotros == 15 && _nosotrosFinishedMalas);
    return _ellos > 15 || (_ellos == 15 && _ellosFinishedMalas);
  }

  int getDisplayPoints(String team) {
    final int score = team == "nosotros" ? _nosotros : _ellos;
    final bool finishedMalas = team == "nosotros" ? _nosotrosFinishedMalas : _ellosFinishedMalas;
    
    if (score == 0) return 0;
    if (score < 15) return score;
    if (score == 15) return finishedMalas ? 0 : 15;
    if (score == 30) return 15;
    return score - 15;
  }

  String getLabel(String team) {
    return isBuenas(team) ? "BUENAS" : "MALAS";
  }

  void addPointNosotros([Offset? dropOffset]) async {
    if (_nosotros < _maxScore && _winner == null && _totalRemainingMatchsticks > 0) {
      _nosotros++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "nosotros";

      if (_nosotros == 15) {
        _nosotrosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        // Wait for landing animation
        await Future.delayed(const Duration(milliseconds: 500));
        
        _nosotrosWaiting = false;
        _nosotrosResetting = true;
        _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation
        await Future.delayed(const Duration(milliseconds: 700));
        _nosotrosResetting = false;
        _nosotrosFinishedMalas = true;
      } else if (_nosotros == 30) {
        _winner = "nosotros";
        _audioService.playStick();
        // No clear animation at 30 anymore, handled by popup
      } else {
        _audioService.playStick();
      }
      notifyListeners();
    }
  }

  void removePointNosotros() {
    if (_nosotros > 0) {
      if (_nosotros == 15) {
        _nosotrosFinishedMalas = false;
      }
      _nosotros--;
      _winner = null; // Clear winner if score decreased
      _totalRemainingMatchsticks++;
      notifyListeners();
    }
  }

  void addPointEllos([Offset? dropOffset]) async {
    if (_ellos < _maxScore && _winner == null && _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";

      if (_ellos == 15) {
        _ellosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        // Wait for landing animation
        await Future.delayed(const Duration(milliseconds: 500));

        _ellosWaiting = false;
        _ellosResetting = true;
        _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation
        await Future.delayed(const Duration(milliseconds: 700));
        _ellosResetting = false;
        _ellosFinishedMalas = true;
      } else if (_ellos == 30) {
        _winner = "ellos";
        _audioService.playStick();
        // No clear animation at 30 anymore, handled by popup
      } else {
        _audioService.playStick();
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

  Future<void> triggerReset() async {
    _isResetting = true;
    _audioService.playClear();
    notifyListeners();
    // Wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 600));
    _nosotros = 0;
    _ellos = 0;
    _winner = null;
    _nosotrosName = "NOSOTROS";
    _ellosName = "ELLOS";
    _nosotrosFinishedMalas = false;
    _ellosFinishedMalas = false;
    _totalRemainingMatchsticks = 60;
    _lastDropOffset = null;
    _lastPointTeam = null;
    _isResetting = false;
    notifyListeners();
  }

  void removePointEllos() {
    if (_ellos > 0) {
      if (_ellos == 15) {
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

  void setMaxScore(int score) {
    _maxScore = score;
    notifyListeners();
  }
}
