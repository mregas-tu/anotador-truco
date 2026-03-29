import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class ScoreProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  int _nosotros = 0;
  int _ellos = 0;
  int _maxScore = 30;
  int _totalRemainingMatchsticks = 60;
  Offset? _lastDropOffset;
  String? _lastPointTeam;
  bool _isResetting = false;
  bool _nosotrosResetting = false;
  bool _ellosResetting = false;
  bool _nosotrosWaiting = false;
  bool _ellosWaiting = false;

  int get nosotros => _nosotros;
  int get ellos => _ellos;
  int get maxScore => _maxScore;
  int get totalRemainingMatchsticks => _totalRemainingMatchsticks;
  Offset? get lastDropOffset => _lastDropOffset;
  String? get lastPointTeam => _lastPointTeam;
  bool get isResetting => _isResetting;
  bool get nosotrosResetting => _nosotrosResetting || _isResetting;
  bool get ellosResetting => _ellosResetting || _isResetting;
  bool get nosotrosShowMilestone => _nosotrosWaiting || _nosotrosResetting || _isResetting;
  bool get ellosShowMilestone => _ellosWaiting || _ellosResetting || _isResetting;

  bool isBuenas(int score) => score > 15;

  int getDisplayPoints(int score) {
    if (score == 0 || score == 15 || score == 30) return 0;
    if (score < 15) return score;
    return score - 15;
  }

  String getLabel(int score) {
    if (score == 0) return "0 Malas";
    if (score <= 15) return "$score Malas";
    return "${score - 15} Buenas";
  }

  void addPointNosotros([Offset? dropOffset]) async {
    if (_nosotros < _maxScore && _totalRemainingMatchsticks > 0) {
      _nosotros++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "nosotros";

      if (_nosotros == 15) {
        _nosotrosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        // Wait for landing animation (400ms)
        await Future.delayed(const Duration(milliseconds: 500));
        
        _nosotrosWaiting = false;
        _nosotrosResetting = true;
        _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation (700ms)
        await Future.delayed(const Duration(milliseconds: 700));
        _nosotrosResetting = false;
      } else if (_nosotros == 30) {
        _nosotrosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));

        _nosotrosWaiting = false;
        _nosotrosResetting = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 700));
        _nosotrosResetting = false;
      } else {
        _audioService.playStick();
      }
      notifyListeners();
    }
  }

  void removePointNosotros() {
    if (_nosotros > 0) {
      _nosotros--;
      _totalRemainingMatchsticks++;
      notifyListeners();
    }
  }

  void addPointEllos([Offset? dropOffset]) async {
    if (_ellos < _maxScore && _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";

      if (_ellos == 15) {
        _ellosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        // Wait for landing animation (400ms)
        await Future.delayed(const Duration(milliseconds: 500));

        _ellosWaiting = false;
        _ellosResetting = true;
        _audioService.playBuenas();
        notifyListeners();
        // Wait for clear animation (700ms)
        await Future.delayed(const Duration(milliseconds: 700));
        _ellosResetting = false;
      } else if (_ellos == 30) {
        _ellosWaiting = true;
        _audioService.playStick();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));

        _ellosWaiting = false;
        _ellosResetting = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 700));
        _ellosResetting = false;
      } else {
        _audioService.playStick();
      }
      notifyListeners();
    }
  }

  Future<void> triggerReset() async {
    _isResetting = true;
    _audioService.playClear();
    notifyListeners();
    // Wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 600));
    _nosotros = 0;
    _ellos = 0;
    _totalRemainingMatchsticks = 60;
    _lastDropOffset = null;
    _lastPointTeam = null;
    _isResetting = false;
    notifyListeners();
  }

  void removePointEllos() {
    if (_ellos > 0) {
      _ellos--;
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
