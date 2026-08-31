import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/billing_service.dart';
import '../services/analytics_service.dart';

class PremiumProvider with ChangeNotifier {
  static const bool _debugForceNonPremium =
      kDebugMode && bool.fromEnvironment('DEBUG_FORCE_NON_PREMIUM');
  static const String _keyIsPremium = '33_de_mano_unlocked';
  static const String _keyTempUnlocks = 'temp_unlocks';
  static const String _keyGlobalTempUntil = 'global_temp_unlock_until';

  bool _isPremium = false;
  Map<String, DateTime> _tempUnlocks = {};
  DateTime? _globalTempUnlockUntil;
  final Map<String, Timer> _expirationTimers = {};
  Timer? _globalExpirationTimer;
  SharedPreferences? _prefs;
  late BillingService _billingService;

  bool get isPremium => _debugForceNonPremium ? false : _isPremium;

  bool get hasGlobalTempUnlock {
    final until = _globalTempUnlockUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  String? getGlobalTempUnlockRemaining() {
    if (!hasGlobalTempUnlock) return null;
    final diff = _globalTempUnlockUntil!.difference(DateTime.now());
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

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

    final String? globalUntilStr = _prefs?.getString(_keyGlobalTempUntil);
    if (globalUntilStr != null) {
      try {
        final DateTime dt = DateTime.parse(globalUntilStr);
        if (dt.isAfter(DateTime.now())) {
          _globalTempUnlockUntil = dt;
          _scheduleGlobalExpiration();
        } else {
          await _prefs?.remove(_keyGlobalTempUntil);
        }
      } catch (e) {
        debugPrint('Error loading global temp unlock: $e');
      }
    }
    AnalyticsService.setSuperProperties(analyticsSuperProperties);
    AnalyticsService.setPeopleProperties({'is_premium': isPremium});
    notifyListeners();

    if (_debugForceNonPremium) {
      debugPrint(
        '[PremiumProvider] DEBUG_FORCE_NON_PREMIUM activo: se omite sync con la tienda.',
      );
      return;
    }

    _syncPremiumStatusWithStore();
  }

  Future<void> _syncPremiumStatusWithStore() async {
    final verified = await _billingService.verifyPremiumStatus();

    if (verified == true && !_isPremium) {
      debugPrint(
          '[PremiumProvider] Compra premium recuperada desde la tienda.');
      AnalyticsService.logEvent('premium_restored_silently');
      await setPremium(true);
      return;
    }

    // Solo revoca si la tienda confirma explícitamente que no hay compra.
    // null = error/sin conexión/plataforma sin query silenciosa -> conservador.
    if (verified == false && _isPremium) {
      debugPrint(
        '[PremiumProvider] Compra revocada por la tienda. Removiendo premium.',
      );
      AnalyticsService.logEvent('premium_revoked_by_store');
      await setPremium(false);
    }
  }

  Map<String, dynamic> get analyticsSuperProperties => {
        'is_premium': isPremium,
      };

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _prefs?.setBool(_keyIsPremium, value);
    AnalyticsService.setSuperProperties(analyticsSuperProperties);
    AnalyticsService.setPeopleProperties({'is_premium': isPremium});
    notifyListeners();
  }

  Future<void> buyPremium({String source = 'unknown'}) async {
    AnalyticsService.logEvent('premium_purchase_started',
        parameters: {'source': source});
    await _billingService.buyPremium();
  }

  Future<void> restorePurchases() async {
    AnalyticsService.logEvent('premium_restore_attempted');
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

  void _scheduleGlobalExpiration() {
    _globalExpirationTimer?.cancel();
    final until = _globalTempUnlockUntil;
    if (until == null) return;
    final diff = until.difference(DateTime.now());
    if (diff.isNegative) {
      _globalTempUnlockUntil = null;
      _prefs?.remove(_keyGlobalTempUntil);
      notifyListeners();
      return;
    }
    _globalExpirationTimer = Timer(diff, () {
      _globalTempUnlockUntil = null;
      _prefs?.remove(_keyGlobalTempUntil);
      notifyListeners();
    });
  }

  Future<void> extendGlobalTempUnlock(Duration duration) async {
    final now = DateTime.now();
    final base =
        (_globalTempUnlockUntil != null && _globalTempUnlockUntil!.isAfter(now))
            ? _globalTempUnlockUntil!
            : now;
    _globalTempUnlockUntil = base.add(duration);
    await _prefs?.setString(
        _keyGlobalTempUntil, _globalTempUnlockUntil!.toIso8601String());
    _scheduleGlobalExpiration();
    notifyListeners();
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
    if (isPremium) return true;
    if (hasGlobalTempUnlock) return true;
    if (_tempUnlocks.containsKey(id)) {
      if (_tempUnlocks[id]!.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  String? getRemainingTime(String id) {
    if (isPremium) return null;
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
    _globalExpirationTimer?.cancel();
    _billingService.dispose();
    super.dispose();
  }
}
