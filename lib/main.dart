import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/ad_service.dart';
import 'providers/score_provider.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  AdService.loadInterstitial();
  
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ScoreProvider())],
      child: const TrucoProApp(),
    ),
  );
}

class TrucoProApp extends StatelessWidget {
  const TrucoProApp({super.key});

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
      home: const MainScreen(),
    );
  }
}
