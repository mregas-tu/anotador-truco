import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/version_checker.dart';
import 'providers/score_provider.dart';
import 'providers/premium_provider.dart';
import 'widgets/force_update_screen.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();
  await AnalyticsService.logAppOpen();
  
  // Nuevo: Chequeo de versión
  final versionChecker = VersionChecker();
  await versionChecker.checkVersion();

  await AdService.initialize();
  AdService.loadInterstitial();
  AdService.loadRewardedAd();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
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
