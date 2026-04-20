import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/billing_service.dart';
import '../services/analytics_service.dart';

class PremiumProvider with ChangeNotifier {
  static const String _keyIsPremium = '33_de_mano_unlocked';
  static const String _keyTempUnlocks = 'temp_unlocks';

  bool _isPremium = false;
  Map<String, DateTime> _tempUnlocks = {};
  final Map<String, Timer> _expirationTimers = {};
  SharedPreferences? _prefs;
  late BillingService _billingService;

  bool get isPremium => _isPremium;

  PremiumProvider() {
    _billingService = BillingService(
      onPremiumStatusChanged: (status) {
        if (status) {
          setPremium(true);
        }
      },
    );
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs?.getBool(_keyIsPremium) ?? false;

    final String? tempUnlocksJson = _prefs?.getString(_keyTempUnlocks);
    if (tempUnlocksJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(tempUnlocksJson);
        _tempUnlocks =
            decoded.map((key, value) => MapEntry(key, DateTime.parse(value)));

        // Clean up expired unlocks and schedule active ones
        _tempUnlocks
            .removeWhere((key, expiry) => expiry.isBefore(DateTime.now()));
        _tempUnlocks.forEach((key, expiry) => _scheduleExpiration(key, expiry));
      } catch (e) {
        debugPrint('Error loading temp unlocks: $e');
      }
    }
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _prefs?.setBool(_keyIsPremium, value);
    notifyListeners();
  }

  Future<void> buyPremium() async {
    AnalyticsService.logPurchaseStarted();
    await _billingService.buyPremium();
  }

  Future<void> restorePurchases() async {
    AnalyticsService.logEvent('restore_purchases_clicked');
    await _billingService.restorePurchases();
  }

  void _scheduleExpiration(String id, DateTime expiry) {
    _expirationTimers[id]?.cancel();
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) {
      _tempUnlocks.remove(id);
      _saveTempUnlocks();
      notifyListeners();
    } else {
      _expirationTimers[id] = Timer(diff, () {
        _tempUnlocks.remove(id);
        _saveTempUnlocks();
        notifyListeners();
      });
    }
  }

  Future<void> unlockTemporarily(String id) async {
    final expiry = DateTime.now().add(const Duration(hours: 24));
    _tempUnlocks[id] = expiry;
    await _saveTempUnlocks();
    _scheduleExpiration(id, expiry);
    notifyListeners();
  }

  Future<void> _saveTempUnlocks() async {
    final Map<String, String> encoded = _tempUnlocks
        .map((key, value) => MapEntry(key, value.toIso8601String()));
    await _prefs?.setString(_keyTempUnlocks, jsonEncode(encoded));
  }

  bool isUnlocked(String id) {
    if (_isPremium) return true;
    if (_tempUnlocks.containsKey(id)) {
      if (_tempUnlocks[id]!.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  String? getRemainingTime(String id) {
    if (_isPremium) return null;
    if (_tempUnlocks.containsKey(id)) {
      final expiry = _tempUnlocks[id]!;
      final diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return null;

      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      return "$hours:$minutes";
    }
    return null;
  }

  // Helper getters for specific logic
  bool isThemeUnlocked(String themeName) {
    if (themeName == "NAVY PROFUNDO") return true;
    return isUnlocked('theme_$themeName');
  }

  bool isPaletteUnlocked(int index) {
    if (index < 5) return true; // First 5 are free
    return isUnlocked('palette_$index');
  }

  bool isBeanPaletteUnlocked(int index) {
    if (index < 5) return true; // First 5 are free
    return isUnlocked('bean_palette_$index');
  }

  @override
  void dispose() {
    for (var timer in _expirationTimers.values) {
      timer.cancel();
    }
    _billingService.dispose();
    super.dispose();
  }
}
