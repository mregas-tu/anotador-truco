import 'package:flutter/material.dart';

class ScoreProvider with ChangeNotifier {
  int _nosotros = 0;
  int _ellos = 0;
  int _maxScore = 30;
  int _totalRemainingMatchsticks = 60;
  Offset? _lastDropOffset;
  String? _lastPointTeam;
  bool _isResetting = false;

  int get nosotros => _nosotros;
  int get ellos => _ellos;
  int get maxScore => _maxScore;
  int get totalRemainingMatchsticks => _totalRemainingMatchsticks;
  Offset? get lastDropOffset => _lastDropOffset;
  String? get lastPointTeam => _lastPointTeam;
  bool get isResetting => _isResetting;

  bool isBuenas(int score) => score > 15;

  int getDisplayPoints(int score) {
    if (score == 0) return 0;
    if (score <= 15) return score;
    return score - 15;
  }

  String getLabel(int score) {
    if (score == 0) return "0 Malas";
    if (score <= 15) return "$score Malas";
    return "${score - 15} Buenas";
  }

  void addPointNosotros([Offset? dropOffset]) {
    if (_nosotros < _maxScore && _totalRemainingMatchsticks > 0) {
      _nosotros++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "nosotros";
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

  void addPointEllos([Offset? dropOffset]) {
    if (_ellos < _maxScore && _totalRemainingMatchsticks > 0) {
      _ellos++;
      _totalRemainingMatchsticks--;
      _lastDropOffset = dropOffset;
      _lastPointTeam = "ellos";
      notifyListeners();
    }
  }

  Future<void> triggerReset() async {
    _isResetting = true;
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
