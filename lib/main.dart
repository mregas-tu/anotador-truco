import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/version_checker.dart';
import 'providers/score_provider.dart';
import 'providers/premium_provider.dart';
import 'widgets/force_update_screen.dart';
import 'main_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  WakelockPlus.enable();

  await Firebase.initializeApp();

  // Crashlytics: Capturar errores de Flutter sin marcarlos todos como crash.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
  };

  // Crashlytics: Capturar errores asíncronos sin clasificarlos como fatales.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    return true;
  };

  await AnalyticsService.init();
  await AnalyticsService.logAppOpen();

  final versionChecker = VersionChecker();
  await versionChecker.checkVersion();

  await AdService.initialize();
  AdService.loadInterstitial();
  AdService.loadRewardedAd();

  AudioService().preload();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProxyProvider<PremiumProvider, ScoreProvider>(
          create: (_) => ScoreProvider(),
          update: (_, premium, score) =>
              score!..validatePremiumSelection(premium),
        ),
      ],
      child: TrucoProApp(
        isUpdateRequired: versionChecker.isUpdateRequired,
        storeUrl: versionChecker.storeUrl ?? '',
      ),
    ),
  );
}

class TrucoProApp extends StatelessWidget {
  final bool isUpdateRequired;
  final String storeUrl;

  const TrucoProApp({
    super.key,
    required this.isUpdateRequired,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anotador de Truco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: isUpdateRequired
          ? ForceUpdateScreen(storeUrl: storeUrl)
          : const MainScreen(),
    );
  }
}
