import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  static final VersionChecker _instance = VersionChecker._internal();
  factory VersionChecker() => _instance;
  VersionChecker._internal();

  bool _isUpdateRequired = false;
  String? _storeUrl;

  bool get isUpdateRequired => _isUpdateRequired;
  String? get storeUrl => _storeUrl;

  Future<void> checkVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      // Configuración de Remote Config
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero, // Para probar ahora mismo
      ));

      // Valores por defecto
      await remoteConfig.setDefaults({
        'min_version': packageInfo.version,
        'store_url': Platform.isAndroid 
            ? 'https://play.google.com/store/apps/details?id=com.mregas.truco.anotador'
            : 'https://apps.apple.com/app/idYOUR_APP_ID',
      });

      await remoteConfig.fetchAndActivate();

      final String minVersion = remoteConfig.getString('min_version');
      _storeUrl = remoteConfig.getString('store_url');
      
      final String currentVersion = packageInfo.version;

      _isUpdateRequired = _shouldUpdate(currentVersion, minVersion);
    } catch (e) {
      print('Error al chequear versión: $e');
    }
  }

  bool _shouldUpdate(String current, String minimum) {
    try {
      final List<int> currentParts = current.split('.').map(int.parse).toList();
      final List<int> minParts = minimum.split('.').map(int.parse).toList();

      for (int i = 0; i < minParts.length; i++) {
        if (i >= currentParts.length || currentParts[i] < minParts[i]) {
          return true;
        } else if (currentParts[i] > minParts[i]) {
          return false;
        }
      }
    } catch (e) {
      print('Error comparando versiones: $e');
    }
    return false;
  }
}
