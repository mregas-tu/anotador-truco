import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/analytics_service.dart';
import '../services/support_service.dart';
import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../services/persistence_service.dart';
import '../services/live_match_service.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';
import 'bean_widget.dart';
import 'game_dialogs.dart';
import 'theme_background.dart';
import 'match_history_content.dart';

class SettingsDialogContent extends StatefulWidget {
  final Function(String) onThemeLockedTap;
  final Function(int) onPaletteLockedTap;
  final Function(int) onBeanPaletteLockedTap;
  final VoidCallback onPremiumTap;
  final VoidCallback onRepeatTutorial;

  const SettingsDialogContent({
    super.key,
    required this.onThemeLockedTap,
    required this.onPaletteLockedTap,
    required this.onBeanPaletteLockedTap,
    required this.onPremiumTap,
    required this.onRepeatTutorial,
  });

  @override
  State<SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<SettingsDialogContent> {
  int currentPane = 0; // 0: Main, 1: Customization, 2: Game Mode
  Timer? _timer;
  final ScrollController _gameModeScrollController = ScrollController();
  final MobileScannerController _liveScannerController =
      MobileScannerController();
  String _appVersion = "1.1.4"; // Initial fallback
  VoidCallback? _historyBackAction;
  bool _isStartingLiveHost = false;
  bool _handledLiveScan = false;
  bool _linkCopied = false;
  final ScrollController _linkScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
    _runLinkMarquee();
  }

  /// Scrolls the shared-link text right to its end, holds, scrolls back to
  /// the start, holds, and repeats — for links wider than their row. Loops
  /// for the lifetime of this dialog; harmlessly idles (checking every so
  /// often) whenever the link row isn't the currently visible pane, or the
  /// link fits without overflowing.
  Future<void> _runLinkMarquee() async {
    while (mounted) {
      if (!_linkScrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
      final maxExtent = _linkScrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      final scrollDuration = Duration(
        milliseconds: (maxExtent * 25).clamp(900, 4000).round(),
      );
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || !_linkScrollController.hasClients) continue;
        await _linkScrollController.animateTo(
          maxExtent,
          duration: scrollDuration,
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || !_linkScrollController.hasClients) continue;
        await _linkScrollController.animateTo(
          0,
          duration: scrollDuration,
          curve: Curves.easeInOut,
        );
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint("Error loading version: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _linkScrollController.dispose();
    _gameModeScrollController.dispose();
    _liveScannerController.dispose();
    super.dispose();
  }

  void _scrollToSelectedMode(ScoreProvider scoreProvider) {
    if (!mounted) return;
    final index = availableModes
        .indexWhere((m) => m.label == scoreProvider.currentGameMode.label);
    if (index != -1) {
      // ListTile height with internal padding is approx 48-52
      const double itemHeight = 48.0;
      final double offset = index * (itemHeight + 1.0);

      _gameModeScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      // Para un botón manual en ajustes, usamos openStoreListing() ya que requestReview()
      // puede ser ignorado silenciosamente por el sistema operativo.
      await inAppReview.openStoreListing();
      await PersistenceService.setHasRatedApp(true);
    } catch (e) {
      debugPrint("Error opening store listing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final bool isSmallScreen = MediaQuery.of(context).size.height < 700;

    String title = "AJUSTES";
    if (currentPane == 1) title = "DISEÑO";
    if (currentPane == 2) title = "MODO DE JUEGO";
    if (currentPane == 3) title = "AYUDA Y SOPORTE";
    if (currentPane == 4) title = "ACERCA DE";
    if (currentPane == 5) title = "VALORES Y SEÑAS";
    if (currentPane == 6) title = "BRINDIS";
    if (currentPane == 7) title = "HISTORIAL DE PARTIDAS";
    if (currentPane == 8) title = "PARTIDA EN VIVO";
    if (currentPane == 9) title = "ANFITRIÓN";
    if (currentPane == 10) title = "ESCANEAR QR";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Back icon, Title, Close icon)
        Stack(
          alignment: Alignment.center,
          children: [
            if (currentPane != 0)
              Positioned(
                left: 0,
                child: IconButton(
                  onPressed: () {
                    if (currentPane == 7 && _historyBackAction != null) {
                      _historyBackAction!();
                      _historyBackAction = null;
                      return;
                    }
                    setState(() {
                      if (currentPane == 4 || currentPane == 5) {
                        currentPane = 3;
                      } else if (currentPane == 9 || currentPane == 10) {
                        if (currentPane == 10) {
                          _liveScannerController.stop();
                        }
                        currentPane = 8;
                      } else {
                        currentPane = 0;
                      }
                    });
                    _historyBackAction = null;
                  },
                  icon: Icon(Icons.arrow_back,
                      color: scoreProvider.appTheme.cream),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 20,
                color: scoreProvider.appTheme.cream,
                letterSpacing: 0,
              ),
            ),
            if (currentPane == 8 || currentPane == 9 || currentPane == 10)
              Positioned(
                right: 40,
                child: IconButton(
                  onPressed: () => _showLiveHelp(scoreProvider),
                  icon: Icon(Icons.help_outline,
                      color: scoreProvider.appTheme.cream),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Positioned(
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: scoreProvider.appTheme.cream),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        SizedBox(height: currentPane == 1 ? 8 : 24),

        if (currentPane == 0) ...[
          // --- PANE 0: MAIN SETTINGS ---
          _buildMenuActionItem(
            label: "SONIDO",
            iconAsset: 'assets/images/menu_icons/sound_icon.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: Switch(
              value: !scoreProvider.isMuted,
              onChanged: (val) {
                scoreProvider.setMuted(!val);
              },
              activeColor: Colors.white,
              activeTrackColor: scoreProvider.appTheme.accentColor,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuActionItem(
            label: "VIBRACIÓN",
            iconAsset: 'assets/images/menu_icons/vibration.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: Switch(
              value: scoreProvider.vibrationEnabled,
              onChanged: (val) {
                scoreProvider.setVibrationEnabled(val);
              },
              activeColor: Colors.white,
              activeTrackColor: scoreProvider.appTheme.accentColor,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuActionItem(
            label: "MODO DE CONTROL",
            iconAsset: 'assets/images/menu_icons/control_mode_icon.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor:
                    scoreProvider.appTheme.slate.withValues(alpha: 0.1),
              ),
              onPressed: () {
                final nextMode = scoreProvider.scoringMode == ScoringMode.drag
                    ? ScoringMode.tap
                    : scoreProvider.scoringMode == ScoringMode.tap
                        ? ScoringMode.classic
                        : ScoringMode.drag;
                scoreProvider.setScoringMode(nextMode);
              },
              child: Text(
                scoreProvider.scoringMode == ScoringMode.drag
                    ? "ARRASTRE"
                    : scoreProvider.scoringMode == ScoringMode.tap
                        ? "TOQUE"
                        : "CLÁSICO",
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 14,
                  color: scoreProvider.appTheme.cream,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "MODO DE JUEGO",
            iconAsset: 'assets/images/menu_icons/game_mode_icon.svg',
            onTap: () {
              setState(() => currentPane = 2);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedMode(scoreProvider);
              });
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "DISEÑO",
            iconAsset: 'assets/images/menu_icons/design_icon.svg',
            onTap: () {
              AnalyticsService.logDesignMenu();
              setState(() => currentPane = 1);
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "HISTORIAL DE PARTIDAS",
            iconData: Icons.emoji_events_outlined,
            onTap: () => setState(() => currentPane = 7),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "BRINDIS",
            iconAsset: 'assets/images/menu_icons/cheers_icon.svg',
            onTap: () {
              setState(() => currentPane = 6);
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "AYUDA Y SOPORTE",
            iconAsset: 'assets/images/menu_icons/support_icon.svg',
            onTap: () {
              setState(() => currentPane = 3);
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          if (!premiumProvider.isPremium) ...[
            _buildMenuNavigationItem(
              label: "HACERME PREMIUM",
              iconAsset: 'assets/images/menu_icons/premium_icon.svg',
              onTap: () {
                Navigator.pop(context);
                GameDialogs.showPremiumBenefits(context, source: 'settings');
              },
              scoreProvider: scoreProvider,
              isSmallScreen: isSmallScreen,
            ),
            Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          ],

          const SizedBox(height: 24),

          _buildLiveEntryButton(scoreProvider),
        ] else if (currentPane == 1) ...[
          // --- PANE 1: DESIGN (THEMES & PALETTES) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("TEMA DE LA APP",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: TrucoTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = TrucoTheme.allThemes[index];
                  final isSelected = scoreProvider.appTheme.name == theme.name;
                  final isLocked = !premiumProvider.isThemeUnlocked(theme.name);

                  return GestureDetector(
                    onTap: () {
                      if (isLocked) {
                        widget.onThemeLockedTap(theme.name);
                      } else {
                        scoreProvider.setAppTheme(theme);
                        AnalyticsService.logThemeChanged(theme.name);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.navy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white10,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          children: [
                            if (theme.thumbnailAsset != null)
                              Positioned.fill(
                                child: Image.asset(
                                  theme.thumbnailAsset!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (theme.backgroundAsset != null)
                              Positioned.fill(
                                child: ThemeBackground(theme: theme),
                              ),
                            if (isLocked)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                    child: Icon(Icons.lock,
                                        color: Colors.white70, size: 24)),
                              )
                            else if (premiumProvider
                                    .getRemainingTime('theme_${theme.name}') !=
                                null)
                              Container(
                                color: Colors.black45,
                                alignment: Alignment.center,
                                child: Text(
                                  premiumProvider
                                      .getRemainingTime('theme_${theme.name}')!,
                                  style: const TextStyle(
                                    fontFamily: AppFonts.oswald,
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                  ),
                                ),
                              )
                            else if (isSelected)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.check,
                                      size: 12, color: theme.navy),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("TIPO DE FICHAS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        scoreProvider.setPointType(PointType.matches);
                        AnalyticsService.logPieceStyleSelected('fosforos');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: scoreProvider.pointType == PointType.matches
                              ? scoreProvider.appTheme.cream
                                  .withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scoreProvider.pointType == PointType.matches
                                ? scoreProvider.appTheme.cream
                                : Colors.white10,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "FÓSFOROS",
                          style: TextStyle(
                            fontFamily: AppFonts.oswald,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        scoreProvider.setPointType(PointType.beans);
                        AnalyticsService.logPieceStyleSelected('porotos');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: scoreProvider.pointType == PointType.beans
                              ? scoreProvider.appTheme.cream
                                  .withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scoreProvider.pointType == PointType.beans
                                ? scoreProvider.appTheme.cream
                                : Colors.white10,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "POROTOS",
                          style: TextStyle(
                            fontFamily: AppFonts.oswald,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                    scoreProvider.pointType == PointType.matches
                        ? "DISEÑO DE FÓSFOROS"
                        : "DISEÑO DE POROTOS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              if (scoreProvider.pointType == PointType.matches)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 5;
                    final spacing = isSmallScreen ? 12.0 : 16.0;
                    final availableItemSize = (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                        crossAxisCount;
                    final defaultItemSize = isSmallScreen ? 44.0 : 48.0;
                    final itemSize = availableItemSize < defaultItemSize
                        ? availableItemSize
                        : defaultItemSize;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: availablePalettes.length,
                      itemBuilder: (context, index) {
                        final palette = availablePalettes[index];
                        final isSelected =
                            scoreProvider.currentPalette.name == palette.name;
                        final isLocked =
                            !premiumProvider.isPaletteUnlocked(index);
                        final timeLeft =
                            premiumProvider.getRemainingTime('palette_$index');

                        return GestureDetector(
                          onTap: () {
                            if (isLocked) {
                              widget.onPaletteLockedTap(index);
                            } else {
                              scoreProvider.setPalette(palette);
                            }
                          },
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: itemSize,
                                  height: itemSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        palette.headColors[0],
                                        palette.headColors.last
                                      ],
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white10,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: palette.headColors.first
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2)
                                          ]
                                        : null,
                                  ),
                                ),
                                if (isLocked)
                                  const Icon(Icons.lock,
                                      color: Colors.white, size: 18),
                                if (timeLeft != null)
                                  Container(
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black45),
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      timeLeft,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.oswald,
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 5;
                    final spacing = isSmallScreen ? 12.0 : 16.0;
                    final availableItemSize = (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                        crossAxisCount;
                    final defaultItemSize = isSmallScreen ? 44.0 : 48.0;
                    final itemSize = availableItemSize < defaultItemSize
                        ? availableItemSize
                        : defaultItemSize;
                    final beanSize = itemSize * 0.42;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: availableBeanPalettes.length,
                      itemBuilder: (context, index) {
                        final palette = availableBeanPalettes[index];
                        final isSelected =
                            scoreProvider.currentBeanPalette.name ==
                                palette.name;
                        final isLocked =
                            !premiumProvider.isBeanPaletteUnlocked(index);
                        final timeLeft = premiumProvider
                            .getRemainingTime('bean_palette_$index');

                        return GestureDetector(
                          onTap: () {
                            if (isLocked) {
                              widget.onBeanPaletteLockedTap(index);
                            } else {
                              scoreProvider.setBeanPalette(palette);
                            }
                          },
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: itemSize,
                                  height: itemSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white10,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                spreadRadius: 2)
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: BeanWidget(
                                      size: beanSize,
                                      beanType: palette.type,
                                      seed: index,
                                      useCache: false,
                                    ),
                                  ),
                                ),
                                if (isLocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black45,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.lock,
                                            color: Colors.white70, size: 20),
                                      ),
                                    ),
                                  ),
                                if (timeLeft != null)
                                  Positioned(
                                    bottom: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        timeLeft,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.oswald,
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ] else if (currentPane == 2) ...[
          // --- PANE 2: GAME MODE ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              controller: _gameModeScrollController,
              shrinkWrap: true,
              itemCount: availableModes.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final mode = availableModes[index];
                final isSelected =
                    scoreProvider.currentGameMode.label == mode.label;

                return ListTile(
                  dense: isSmallScreen,
                  visualDensity: isSmallScreen
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    mode.label,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 16,
                      color: isSelected
                          ? scoreProvider.appTheme.cream
                          : Colors.white70,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.radio_button_checked,
                          color: scoreProvider.appTheme.cream, size: 20)
                      : Icon(Icons.radio_button_off,
                          color: scoreProvider.appTheme.white
                              .withValues(alpha: 0.2),
                          size: 20),
                  onTap: () {
                    scoreProvider.setGameMode(mode);
                  },
                );
              },
            ),
          ),

          // Pica Pica Settings - Exclusive to 30 or 40 point modes
          if (scoreProvider.currentGameMode.totalPoints >= 30) ...[
            const SizedBox(height: 20),
            Divider(
                color: scoreProvider.appTheme.dialogSeparator
                    .withValues(alpha: 0.6),
                height: 1),
            const SizedBox(height: 12),

            // Checkbox Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  final bool newValue = !scoreProvider.picaPicaEnabled;
                  scoreProvider.setPicaPicaEnabled(newValue);
                  AnalyticsService.logPicaPicaToggled(newValue);
                },
                child: Row(
                  children: [
                    // Customized Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scoreProvider.picaPicaEnabled
                              ? scoreProvider.appTheme.cream
                              : scoreProvider.appTheme.dialogSeparator
                                  .withValues(alpha: 0.85),
                          width: 2,
                        ),
                      ),
                      child: scoreProvider.picaPicaEnabled
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scoreProvider.appTheme.cream,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scoreProvider.appTheme.cream
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "PICA PICA",
                      style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.picaPicaEnabled
                            ? scoreProvider.appTheme.cream
                            : scoreProvider.appTheme.dialogSeparator
                                .withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Range Slider with labels
            Opacity(
              opacity: scoreProvider.picaPicaEnabled ? 1.0 : 0.45,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DESDE: ${scoreProvider.picaPicaStart}",
                          style: TextStyle(
                            fontFamily: AppFonts.caminito,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                          ),
                        ),
                        Text(
                          "HASTA: ${scoreProvider.picaPicaEnd}",
                          style: TextStyle(
                            fontFamily: AppFonts.caminito,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scoreProvider.appTheme.cream,
                      inactiveTrackColor:
                          scoreProvider.appTheme.slate.withValues(alpha: 0.1),
                      thumbColor: scoreProvider.appTheme.cream,
                      overlayColor:
                          scoreProvider.appTheme.cream.withValues(alpha: 0.1),
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 8),
                      activeTickMarkColor: scoreProvider.appTheme.cream,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        scoreProvider.picaPicaStart.toDouble(),
                        scoreProvider.picaPicaEnd.toDouble(),
                      ),
                      min: 0,
                      max: scoreProvider.currentGameMode.totalPoints.toDouble(),
                      divisions: scoreProvider.currentGameMode.totalPoints ~/ 5,
                      onChanged: scoreProvider.picaPicaEnabled
                          ? (RangeValues values) {
                              int start = values.start.round();
                              int end = values.end.round();

                              // Enforce 5 point minimum difference
                              if (end - start < 5) {
                                if (start != scoreProvider.picaPicaStart) {
                                  // Start was moved up
                                  start = end - 5;
                                } else {
                                  // End was moved down
                                  end = start + 5;
                                }
                              }

                              if (start < 0) start = 0;
                              if (end >
                                  scoreProvider.currentGameMode.totalPoints) {
                                end = scoreProvider.currentGameMode.totalPoints;
                                if (end - start < 5) start = end - 5;
                              }

                              scoreProvider.setPicaPicaRange(start, end);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (currentPane == 3) ...[
          _buildMenuNavigationItem(
            label: "VALORES Y SEÑAS",
            onTap: () {
              AnalyticsService.logViewRules();
              setState(() => currentPane = 5);
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          // --- PANE 3: HELP & SUPPORT ---
          _buildMenuNavigationItem(
            label: "REPETIR TUTORIAL",
            onTap: () {
              Navigator.pop(context);
              widget.onRepeatTutorial();
              AnalyticsService.logTutorialRepeat();
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "ESCRIBINOS",
            onTap: () {
              SupportService.sendFeedbackEmail();
              AnalyticsService.logContactUs();
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          _buildMenuNavigationItem(
            label: "VALORAR APP",
            onTap: () {
              _rateApp();
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          if (!premiumProvider.isPremium) ...[
            _buildMenuNavigationItem(
              label: "RESTAURAR COMPRAS",
              onTap: () {
                premiumProvider.restorePurchases();
              },
              scoreProvider: scoreProvider,
              isSmallScreen: isSmallScreen,
            ),
            Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
          ],
          _buildMenuNavigationItem(
            label: "ACERCA DE",
            onTap: () {
              setState(() => currentPane = 4);
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
        ] else if (currentPane == 4) ...[
          // --- PANE 4: ABOUT ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/about.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Versión $_appVersion",
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 14,
                    color: scoreProvider.appTheme.slate,
                  ),
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Falta envido y truco. La forma más práctica de anotar los puntos en cada asado.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 16,
                    color: scoreProvider.appTheme.cream,
                  ),
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Desarrollado con ❤️ en Argentina",
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scoreProvider.appTheme.slate,
                  ),
                ),
              ],
            ),
          ),
        ] else if (currentPane == 5) ...[
          // --- PANE 5: CARD VALUES & SIGNS ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trucoCardHierarchy.length,
              itemBuilder: (context, index) {
                final item = trucoCardHierarchy[index];
                final cardGroup = item['assets'] as List<String>;
                final signAsset = item['sign'] as String?;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 32, right: 32, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          // Cards (Left)
                          SizedBox(
                            height: 66,
                            width: 100,
                            child: Stack(
                              children: cardGroup.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final asset = entry.value;
                                return Positioned(
                                  left: idx * 16.0,
                                  child: _buildSmallCard(asset),
                                );
                              }).toList(),
                            ),
                          ),
                          const Spacer(),
                          if (signAsset != null) ...[
                            // Sign (Right)
                            Column(
                              children: [
                                Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      signAsset,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Text(
                                  item['signName'] ?? "",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.oswald,
                                    fontSize: 10,
                                    color: scoreProvider.appTheme.slate,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            const SizedBox(width: 75), // Mantener alineación
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ] else if (currentPane == 6) ...[
          // --- PANE 6: BRINDIS ---
          GameDialogs.buildVasoBody(context),
        ] else if (currentPane == 7) ...[
          MatchHistoryContent(
            onBackActionChanged: (action) => _historyBackAction = action,
          ),
        ] else if (currentPane == 8) ...[
          _buildLiveMatchHome(scoreProvider, isSmallScreen),
        ] else if (currentPane == 9) ...[
          _buildLiveHostPane(scoreProvider, isSmallScreen),
        ] else if (currentPane == 10) ...[
          _buildLiveScannerPane(scoreProvider, isSmallScreen),
        ],
      ],
    );
  }

  Widget _buildLiveMatchHome(
    ScoreProvider scoreProvider,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLiveBetaNotice(scoreProvider),
        const SizedBox(height: 18),
        _buildLiveRoleTile(
          icon: Icons.qr_code_2,
          title: 'SOY ANFITRIÓN',
          subtitle: 'Genero el QR y comparto este tanteador.',
          scoreProvider: scoreProvider,
          isSmallScreen: isSmallScreen,
          onTap: () => setState(() => currentPane = 9),
        ),
        Divider(color: scoreProvider.appTheme.dialogSeparator, height: 1),
        _buildLiveRoleTile(
          icon: Icons.qr_code_scanner,
          title: 'SOY ESPECTADOR',
          subtitle: 'Escaneo un QR para seguir una partida.',
          scoreProvider: scoreProvider,
          isSmallScreen: isSmallScreen,
          onTap: () {
            _liveScannerController.start();
            setState(() {
              currentPane = 10;
              _handledLiveScan = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLiveHostPane(
    ScoreProvider scoreProvider,
    bool isSmallScreen,
  ) {
    final shareValue = scoreProvider.liveShareValue;
    if (shareValue == null) {
      return PrimaryButton(
        text: _isStartingLiveHost ? 'Creando...' : 'Generar QR',
        width: double.infinity,
        onPressed: () async {
          if (_isStartingLiveHost) return;
          setState(() => _isStartingLiveHost = true);
          try {
            await scoreProvider.startLiveHosting();
          } catch (error) {
            if (mounted) _showLiveMessage(_liveMatchErrorMessage(error));
          } finally {
            if (mounted) setState(() => _isStartingLiveHost = false);
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: shareValue,
              version: QrVersions.auto,
              size: isSmallScreen ? 190 : 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: StreamBuilder<int>(
            stream: LiveMatchService.watchViewerCount(scoreProvider.matchId),
            initialData: 0,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              // theme.slate can be identical to theme.navy (e.g. MALVINAS,
              // MATE), making this invisible against the dialog background.
              final color = scoreProvider.appTheme.cream.withValues(alpha: 0.75);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    count == 1
                        ? '1 persona mirando'
                        : '$count personas mirando',
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _buildLiveLinkRow(scoreProvider, shareValue),
        const SizedBox(height: 10),
        SecondaryButton(
          text: 'Detener vivo',
          width: double.infinity,
          onPressed: () async {
            await scoreProvider.stopLiveHosting();
            if (mounted) _showLiveMessage('Vivo detenido.');
          },
        ),
      ],
    );
  }

  Widget _buildLiveLinkRow(ScoreProvider scoreProvider, String shareValue) {
    final theme = scoreProvider.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.secondaryButtonBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _linkScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                shareValue,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 13,
                  color: theme.secondaryButtonText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: shareValue));
              if (!mounted) return;
              setState(() => _linkCopied = true);
            },
            child: Text(
              _linkCopied ? 'COPIADO' : 'COPIAR',
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScannerPane(
    ScoreProvider scoreProvider,
    bool isSmallScreen,
  ) {
    final scannerSize = isSmallScreen ? 240.0 : 300.0;
    return Center(
      child: SizedBox(
        width: scannerSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: scannerSize,
                height: scannerSize,
                child: MobileScanner(
                  controller: _liveScannerController,
                  onDetect: _handleLiveBarcode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBetaNotice(ScoreProvider scoreProvider) {
    final theme = scoreProvider.appTheme;
    // theme.slate can end up identical to navyLight in some themes (e.g.
    // MALVINAS, MATE), making this text invisible against the box below.
    // theme.cream is chosen per-theme to contrast against the dark/navy
    // colors, so it stays readable everywhere; dimmed here to read as
    // secondary next to the full-opacity "acá" link.
    final defaultStyle = TextStyle(
      fontFamily: AppFonts.oswald,
      color: theme.cream.withValues(alpha: 0.75),
      fontSize: 14,
      height: 1.2,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dialogSeparator),
        color: theme.navyLight.withValues(alpha: 0.35),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: defaultStyle,
          children: [
            const TextSpan(
              text:
                  'Esta función está en beta. Si algo no funciona como esperabas, escribinos desde ',
            ),
            TextSpan(
              text: 'acá',
              style: defaultStyle.copyWith(
                color: theme.cream,
                decoration: TextDecoration.underline,
                decorationColor: theme.cream,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => SupportService.sendFeedbackEmail(
                      email: SupportService.betaFeedbackEmail,
                      subject: 'Puro Truco - Partida en vivo beta',
                    ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveEntryButton(ScoreProvider scoreProvider) {
    final theme = scoreProvider.appTheme;
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: () {
          AnalyticsService.logShareMenu();
          setState(() => currentPane = 8);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeShowLiveMatchTutorial(scoreProvider),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.secondaryButtonBorder, width: 1.5),
          foregroundColor: theme.secondaryButtonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 18,
                color: theme.secondaryButtonText,
              ),
              const SizedBox(width: 8),
              Text(
                'Partida en vivo',
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 14,
                  color: theme.secondaryButtonText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveRoleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    final theme = scoreProvider.appTheme;
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Icon(icon, color: theme.cream, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          color: theme.cream,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          // theme.slate can be identical to theme.navy (e.g. MALVINAS,
          // MATE), making this invisible against the tile's background.
          color: theme.cream.withValues(alpha: 0.75),
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.cream),
      onTap: onTap,
    );
  }

  void _handleLiveBarcode(BarcodeCapture capture) {
    if (_handledLiveScan) return;
    String? value;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        value = barcode.rawValue;
        break;
      }
    }

    final matchId = value == null ? null : LiveMatchService.parseMatchId(value);
    if (matchId == null) return;

    _handledLiveScan = true;
    _liveScannerController.stop();
    Provider.of<ScoreProvider>(context, listen: false)
        .startWatchingLiveMatch(matchId);
    Navigator.pop(context);
  }

  Future<void> _maybeShowLiveMatchTutorial(ScoreProvider scoreProvider) async {
    final alreadyShown = await PersistenceService.getLiveMatchTutorialShown();
    if (alreadyShown) return;
    await PersistenceService.setLiveMatchTutorialShown(true);
    if (!mounted) return;
    _showLiveHelp(scoreProvider);
  }

  void _showLiveHelp(ScoreProvider scoreProvider) {
    final theme = scoreProvider.appTheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.navy,
        title: Text(
          'PARTIDA EN VIVO',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            color: theme.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Olvidate de preguntarle al que anota cuántos puntos van: ahora '
          'podés seguir la partida en vivo desde otro celular. El "anfitrión" '
          'genera un QR, mientras que el "espectador" escanea ese QR para '
          'mirar la partida en vivo.',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            // theme.slate can be identical to theme.navy (e.g. MALVINAS,
            // MATE), making this invisible against the dialog background.
            color: theme.cream.withValues(alpha: 0.75),
            height: 1.25,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                color: theme.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveMessage(String message) {
    final theme = Provider.of<ScoreProvider>(context, listen: false).appTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppFonts.oswald),
        ),
        backgroundColor: theme.accentColor,
      ),
    );
  }

  String _liveMatchErrorMessage(Object error) {
    debugPrint('[LiveMatch] Create failed: $error');
    if (error is FirebaseException) {
      return 'No se pudo crear la partida (${error.code}).';
    }
    if (error is TimeoutException) {
      return 'No se pudo crear la partida: la base en vivo no respondió.';
    }
    return 'No se pudo crear la partida en vivo.';
  }

  Widget _buildMenuActionItem({
    required String label,
    String? iconAsset,
    required Widget trailing,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                scoreProvider.appTheme.cream,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 16,
              color: scoreProvider.appTheme.cream,
            ),
          ),
        ],
      ),
      trailing: trailing,
    );
  }

  Widget _buildMenuNavigationItem({
    required String label,
    String? iconAsset,
    IconData? iconData,
    required VoidCallback onTap,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
    Color? textColor,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                scoreProvider.appTheme.cream,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (iconData != null) ...[
            Icon(
              iconData,
              size: 20,
              color: scoreProvider.appTheme.cream,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 16,
              color: textColor ?? scoreProvider.appTheme.cream,
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: scoreProvider.appTheme.cream),
      onTap: onTap,
    );
  }

  Widget _buildSmallCard(String asset) {
    return Container(
      width: 44,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          asset,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white12,
            child: const Icon(Icons.error, color: Colors.white24, size: 16),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> trucoCardHierarchy = [
  {
    'assets': ['assets/images/cards/espada_1.png'],
    'sign': 'assets/images/signs/1_espada_sign.png',
    'signName': 'Levantar cejas'
  },
  {
    'assets': ['assets/images/cards/basto_1.png'],
    'sign': 'assets/images/signs/1_basto_sign.png',
    'signName': 'Guiñar un ojo'
  },
  {
    'assets': ['assets/images/cards/espada_7.png'],
    'sign': 'assets/images/signs/7_espada_sign.png',
    'signName': 'Boca a la derecha'
  },
  {
    'assets': ['assets/images/cards/oro_7.png'],
    'sign': 'assets/images/signs/7_oro_sign.png',
    'signName': 'Boca a la izquierda'
  },
  {
    'assets': [
      'assets/images/cards/oro_3.png',
      'assets/images/cards/copa_3.png',
      'assets/images/cards/espada_3.png',
      'assets/images/cards/basto_3.png'
    ],
    'sign': 'assets/images/signs/3_sign.png',
    'signName': 'Morder el labio'
  },
  {
    'assets': [
      'assets/images/cards/oro_2.png',
      'assets/images/cards/copa_2.png',
      'assets/images/cards/espada_2.png',
      'assets/images/cards/basto_2.png'
    ],
    'sign': 'assets/images/signs/2_sign.png',
    'signName': 'Hacer pico / beso'
  },
  {
    'assets': [
      'assets/images/cards/oro_1.png',
      'assets/images/cards/copa_1.png'
    ],
    'sign': 'assets/images/signs/1_sign.png',
    'signName': 'Abrir la boca'
  },
  {
    'assets': [
      'assets/images/cards/oro_12.png',
      'assets/images/cards/copa_12.png',
      'assets/images/cards/espada_12.png',
      'assets/images/cards/basto_12.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_11.png',
      'assets/images/cards/copa_11.png',
      'assets/images/cards/espada_11.png',
      'assets/images/cards/basto_11.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_10.png',
      'assets/images/cards/copa_10.png',
      'assets/images/cards/espada_10.png',
      'assets/images/cards/basto_10.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/copa_7.png',
      'assets/images/cards/basto_7.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_6.png',
      'assets/images/cards/copa_6.png',
      'assets/images/cards/espada_6.png',
      'assets/images/cards/basto_6.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_5.png',
      'assets/images/cards/copa_5.png',
      'assets/images/cards/espada_5.png',
      'assets/images/cards/basto_5.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_4.png',
      'assets/images/cards/copa_4.png',
      'assets/images/cards/espada_4.png',
      'assets/images/cards/basto_4.png'
    ],
    'sign': null
  },
];
