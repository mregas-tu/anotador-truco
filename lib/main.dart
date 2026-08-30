import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
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
import 'services/live_match_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  WakelockPlus.enable();

  await Firebase.initializeApp();

  // Crashlytics: Capturar errores de Flutter
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: Capturar errores fuera de Flutter (errores asíncronos nativos)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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
    return _DeepLinkListener(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
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
      ),
    );
  }
}

class _DeepLinkListener extends StatefulWidget {
  final Widget child;

  const _DeepLinkListener({required this.child});

  @override
  State<_DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<_DeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleInitialLink();
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {
        // Ignoramos fallas del stream nativo del sistema operativo.
      },
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (_) {
      // Ignoramos links inválidos o fallas del sistema operativo.
    }
  }

  void _handleUri(Uri uri) {
    final matchId = LiveMatchService.parseMatchId(uri.toString());
    if (matchId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;
      context.read<ScoreProvider>().startWatchingLiveMatch(matchId);
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
