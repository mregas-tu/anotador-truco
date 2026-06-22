import 'dart:async';
import 'services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'providers/score_provider.dart';
import 'widgets/score_group_widget.dart';
import 'widgets/matchstick_widget.dart';
import 'widgets/bean_widget.dart';
import 'widgets/matchstick_box.dart';
import 'theme/app_theme.dart';
import 'services/support_service.dart';
import 'services/analytics_service.dart';
import 'services/persistence_service.dart';
import 'widgets/truco_dialog.dart';
import 'widgets/truco_buttons.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/tutorial_overlay.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/main_screen_widgets.dart';
import 'providers/premium_provider.dart';
import 'widgets/pica_pica_widgets.dart';
import 'services/world_cup_event.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boxKey = GlobalKey();
  final GlobalKey _nosotrosKey = GlobalKey();
  final GlobalKey _ellosKey = GlobalKey();
  final GlobalKey _limitScoreKey = GlobalKey();
  final GlobalKey _restartKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _nosPlusKey = GlobalKey();
  final GlobalKey _nosMinusKey = GlobalKey();
  final GlobalKey _ellPlusKey = GlobalKey();
  final GlobalKey _ellMinusKey = GlobalKey();

  late AnimationController _handController;
  late Animation<Offset> _handMoveAnimation;
  late Animation<double> _handOpacityAnimation;
  bool _showGhostHand = false;

  final Map<String, Timer?> _longPressTimers = {};
  Offset _lastPointerDownPos = Offset.zero;
  String? _lastWinnerShown;
  int _tutorialStep = 0;
  bool _isTutorialActive = false;
  StreamSubscription<String>? _picaPicaSub;
  String? _footerIntDragSide;

  late Animation<double> _handScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      await scoreProvider.loadSettings();

      _picaPicaSub = scoreProvider.picaPicaEvents.listen((event) {
        if (!mounted) return;
        _showPicaPicaToast(
          event == 'start' ? '¡INICIO PICA PICA!' : '¡FIN PICA PICA!',
        );
      });

      AnalyticsService.refreshStaticUserContext();
      AnalyticsService.setSuperProperties(scoreProvider.analyticsSuperProperties);
      AnalyticsService.incrementPeopleProperty('app_open_count');

      final data = await PersistenceService.loadAll();
      final nosotros = data[PersistenceService.keyNosotrosScore] ?? 0;
      final ellos = data[PersistenceService.keyEllosScore] ?? 0;
      final targetScore = scoreProvider.currentGameMode.totalPoints;

      bool blockingDialogShown = false;

      // Solo mostramos recuperar si alguien tiene puntos PERO nadie llegó al límite
      if ((nosotros > 0 || ellos > 0) &&
          (nosotros < targetScore && ellos < targetScore)) {
        if (mounted) {
          _showRecoveryDialog(context, scoreProvider, data);
          blockingDialogShown = true;
        }
      } else if (nosotros >= targetScore || ellos >= targetScore) {
        // Si ya terminó, limpiamos para que no vuelva a molestar al reiniciar
        await PersistenceService.clearGameState();
      }

      // Ghost Hand Tutorial
      final isTutorialDone = await PersistenceService.getTutorialDone();
      if (!isTutorialDone && nosotros == 0 && ellos == 0) {
        if (mounted) {
          setState(() {
            _isTutorialActive = true;
            _tutorialStep = 0;
          });
          _startGhostHandTutorial();
          blockingDialogShown = true;
        }
      }

      if (!blockingDialogShown && mounted) {
        final shownWorldCup = await _maybeShowWorldCupPopup(context);
        if (!shownWorldCup && mounted) {
          _maybeShowPremiumPrompt(context);
        }
      }
    });

    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _handOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_handController);

    _handScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _handController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    // Inicialización dummy para evitar lateness error antes del primer frame
    _handMoveAnimation = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _picaPicaSub?.cancel();
    _picaPicaToastEntry?.remove();
    _picaPicaToastEntry = null;
    _picaPicaToastTimer?.cancel();
    _handController.dispose();
    super.dispose();
  }

  OverlayEntry? _picaPicaToastEntry;
  Timer? _picaPicaToastTimer;

  void _showPicaPicaToast(String message) {
    final theme = Provider.of<ScoreProvider>(context, listen: false).appTheme;
    _picaPicaToastEntry?.remove();
    _picaPicaToastTimer?.cancel();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 16,
        left: 24,
        right: 24,
        child: IgnorePointer(
          child: _PicaPicaToast(
            message: message,
            background: theme.accentColor,
            border: theme.cream,
            textColor: theme.cream,
          ),
        ),
      ),
    );

    _picaPicaToastEntry = entry;
    overlay.insert(entry);
    _picaPicaToastTimer = Timer(const Duration(milliseconds: 2400), () {
      _picaPicaToastEntry?.remove();
      _picaPicaToastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes separately (rare events)
    final theme = context.select<ScoreProvider, TrucoTheme>((p) => p.appTheme);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.navy,
      body: Stack(
        children: [
          // 0. Global Background Image (Now static!)
          if (theme.backgroundAsset != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  theme.backgroundAsset!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 1. Header (Static during points)
                MainHeader(
                  restartKey: _restartKey,
                  settingsKey: _settingsKey,
                  onRestart: () => _showResetConfirmationDialog(context,
                      Provider.of<ScoreProvider>(context, listen: false)),
                  onSettings: _showSettingsDialog,
                ),

                const SizedBox(height: 10),

                // 2. Main Scoring Table (Granular Rebuilds)
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Row(
                        children: [
                          _buildTeamSectionGranular(context, true,
                              key: _nosotrosKey),
                          _buildVerticalDivider(theme),
                          _buildTeamSectionGranular(context, false,
                              key: _ellosKey),
                        ],
                      ),

                      // Floating Score Circle
                      CenterScoreCircle(
                        limitScoreKey: _limitScoreKey,
                      ),

                      // 4. Footer Ornament Overlaid
                      if (theme.footerAsset != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: assetWithShadows(
                                  asset: theme.footerAsset!,
                                  height: theme.footerHeight,
                                  colorFilter: theme.tintFooter
                                      ? ColorFilter.mode(
                                          Colors.white.withOpacity(0.8),
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                  shadows: theme.footerShadows,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Reservamos el espacio para el footer flotante
                const SizedBox(height: 140),
              ],
            ),
          ),

          // 6. Matchstick Box (Floating shared area)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Consumer<ScoreProvider>(
                builder: (context, sp, _) => _buildFooter(context, sp),
              ),
            ),
          ),

          // 7. GHOST HAND OVERLAY
          Consumer<ScoreProvider>(
            builder: (context, sp, _) {
              // Only show ghost hand logic if needed
              if (_showGhostHand) {
                return GhostHandOverlay(
                  controller: _handController,
                  moveAnimation: _handMoveAnimation,
                  opacityAnimation: _handOpacityAnimation,
                  scaleAnimation: _handScaleAnimation,
                  useScale: _tutorialStep >= 2,
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 7. TUTORIAL NAVIGATION OVERLAY
          if (_isTutorialActive)
            TutorialOverlay(
              currentStep: _tutorialStep,
              onSkip: _skipTutorial,
              onNext: () {
                if (_tutorialStep < kTutorialSteps.length - 1) {
                  setState(() {
                    _tutorialStep++;
                    _startGhostHandTutorial();
                  });
                } else {
                  _skipTutorial();
                }
              },
            ),

          // 8. WINNER DIALOG HANDLER (Invisible listener)
          Consumer<ScoreProvider>(
            builder: (context, sp, _) {
              if (sp.winner != null) {
                if (_lastWinnerShown != sp.winner) {
                  _lastWinnerShown = sp.winner;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showWinnerDialog(context, sp);
                  });
                }
              } else {
                _lastWinnerShown = null;
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSectionGranular(BuildContext context, bool isNosotros,
      {Key? key}) {
    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, _) => _buildTeamSection(
          context,
          isNosotros ? scoreProvider.nosotrosName : scoreProvider.ellosName,
          isNosotros ? scoreProvider.nosotros : scoreProvider.ellos,
          isNosotros,
          key: key),
    );
  }

  Widget _buildVerticalDivider(TrucoTheme theme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 1,
            color: theme.dividerColor.withOpacity(0.15),
          ),
        ),
        SizedBox(
            height:
                10 + (theme.footerAsset != null ? theme.footerHeight : 0) + 20),
      ],
    );
  }

  Offset _getBoxOffset() {
    final RenderBox? box =
        _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    return Offset(MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height - 100);
  }

  Widget _buildTeamSection(
    BuildContext context,
    String name,
    int score,
    bool isNosotros, {
    Key? key,
  }) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final String teamKey = isNosotros ? "nosotros" : "ellos";
    final bool isTapMode = scoreProvider.scoringMode == ScoringMode.tap;

    if (isTapMode) {
      final bool isBuenas = scoreProvider.isBuenas(teamKey);
      int totalPoints = scoreProvider.getDisplayPoints(teamKey);

      return Expanded(
        key: key,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _isTutorialActive
              ? null
              : (_) {
                  _longPressTimers[teamKey]?.cancel();
                  _longPressTimers[teamKey] =
                      Timer(const Duration(milliseconds: 200), () {
                    final boxOffset = _getBoxOffset();
                    scoreProvider.triggerFlyOut(teamKey, boxOffset);
                    _longPressTimers[teamKey] = null;
                  });
                },
          onTapUp: (_) {
            if (_longPressTimers[teamKey] != null) {
              _longPressTimers[teamKey]!.cancel();
              _longPressTimers[teamKey] = null;
              final boxOffset = _getBoxOffset();
              if (isNosotros) {
                scoreProvider.addPointNosotros(boxOffset);
              } else {
                scoreProvider.addPointEllos(boxOffset);
              }
            }
          },
          onTapCancel: () {
            _longPressTimers[teamKey]?.cancel();
            _longPressTimers[teamKey] = null;
          },
          child: AbsorbPointer(
            absorbing: _isTutorialActive,
            child: _buildTeamColumnContent(
                name, totalPoints, isBuenas, isNosotros, scoreProvider, false),
          ),
        ),
      );
    }

    return Expanded(
      key: key,
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          if (isNosotros) {
            scoreProvider.addPointNosotros(details.offset);
          } else {
            scoreProvider.addPointEllos(details.offset);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final String teamKey = isNosotros ? "nosotros" : "ellos";
          final bool isBuenas = scoreProvider.isBuenas(teamKey);
          int totalPoints = scoreProvider.getDisplayPoints(teamKey);

          // Milestone transition override
          final bool showMilestone = isNosotros
              ? scoreProvider.nosotrosShowMilestone
              : scoreProvider.ellosShowMilestone;

          if ((isNosotros ? scoreProvider.nosotros : scoreProvider.ellos) ==
                  scoreProvider.currentGameMode.milestone &&
              showMilestone) {
            totalPoints = scoreProvider.currentGameMode.milestone;
          }
          if ((isNosotros
                  ? (scoreProvider.nosotros ==
                      scoreProvider.currentGameMode.totalPoints)
                  : (scoreProvider.ellos ==
                      scoreProvider.currentGameMode.totalPoints)) &&
              showMilestone) {
            totalPoints = scoreProvider.currentGameMode.milestone;
          }

          final bool canDrag = (_isTutorialActive ||
                  scoreProvider.scoringMode == ScoringMode.classic)
              ? false
              : (isNosotros ? scoreProvider.nosotros : scoreProvider.ellos) > 0;

          return Draggable<String>(
            data: isNosotros ? "nosotros" : "ellos",
            dragAnchorStrategy: pointerDragAnchorStrategy,
            maxSimultaneousDrags: canDrag ? 1 : 0,
            onDragStarted: () {
              scoreProvider.setDraggingBack(
                  isNosotros ? "nosotros" : "ellos", true);
            },
            onDraggableCanceled: (velocity, offset) {
              scoreProvider.triggerRevert(
                  isNosotros ? "nosotros" : "ellos", offset);
            },
            onDragEnd: (details) {
              scoreProvider.setDraggingBack(
                  isNosotros ? "nosotros" : "ellos", false);
            },
            feedback: Material(
              color: Colors.transparent,
              child: scoreProvider.pointType == PointType.beans
                  ? BeanWidget(
                      size: 40,
                      seed: totalPoints,
                      beanType: scoreProvider.currentBeanPalette.type)
                  : MatchstickWidget(height: 100),
            ),
            childWhenDragging: _buildTeamColumnContent(
                name, totalPoints, isBuenas, isNosotros, scoreProvider, true),
            child: _buildTeamColumnContent(
                name, totalPoints, isBuenas, isNosotros, scoreProvider, false,
                highlight: candidateData.isNotEmpty ||
                    _footerIntDragSide == (isNosotros ? "nosotros" : "ellos")),
          );
        },
      ),
    );
  }

  void _showNameEditDialog(
      BuildContext context, String teamKey, String currentName) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scoreProvider.appTheme.navyLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "CAMBIAR NOMBRE",
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 16,
              color: scoreProvider.appTheme.white.withOpacity(0.9),
              letterSpacing: 0,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            maxLines: 1,
            style: TextStyle(
              color: scoreProvider.appTheme.cream,
              fontFamily: AppFonts.caminito,
              fontSize: 24,
            ),
            decoration: InputDecoration(
              counterText: "", // Hide the counter for a cleaner look
              hintText: "Ej: LOS CRACKS",
              hintStyle: TextStyle(
                  color: scoreProvider.appTheme.white.withOpacity(0.3)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scoreProvider.appTheme.slate),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scoreProvider.appTheme.buenas),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: "CANCELAR",
                    toUpperCase: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: "GUARDAR",
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        scoreProvider.setTeamName(teamKey, controller.text);
                        AnalyticsService.logTeamNamesChanged();
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmationDialog(
      BuildContext context, ScoreProvider scoreProvider) {
    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        title: "¿COMENZAR DE NUEVO?",
        contentText: "Se perderán todos los puntos de la partida actual.",
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: "CANCELAR",
                  toUpperCase: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: "COMENZAR",
                  onPressed: () {
                    AdService.maybeShowInterstitialOnNewGame(
                      nosotros: scoreProvider.nosotros,
                      ellos: scoreProvider.ellos,
                    );
                    scoreProvider.triggerReset();
                    AnalyticsService.logNewGameStarted();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const int _premiumPromptMinMatches = 3;
  static const int _premiumPromptMinDays = 7;

  Future<bool> _maybeShowWorldCupPopup(BuildContext context) async {
    if (!WorldCupEvent.isActive) return false;
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);
    if (premiumProvider.isPremium) return false;
    final alreadyShown = await PersistenceService.getWorldCupPopupShown();
    if (alreadyShown) return false;
    if (!mounted) return false;
    await PersistenceService.setWorldCupPopupShown(true);
    GameDialogs.showWorldCupThemeAvailable(context);
    return true;
  }

  Future<void> _maybeShowPremiumPrompt(BuildContext context) async {
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);
    if (premiumProvider.isPremium) return;

    final matchesCount = await PersistenceService.getMatchesCompletedCount();
    final matchesAtLast =
        await PersistenceService.getMatchesAtLastPremiumPrompt();
    if (matchesCount - matchesAtLast < _premiumPromptMinMatches) return;

    final lastPromptMillis =
        await PersistenceService.getLastPremiumPromptDate();
    final referenceMillis = lastPromptMillis > 0
        ? lastPromptMillis
        : await PersistenceService.getOrSetInstallDate();
    final daysSince =
        (DateTime.now().millisecondsSinceEpoch - referenceMillis) /
            (1000 * 60 * 60 * 24);
    if (daysSince < _premiumPromptMinDays) return;

    if (!mounted) return;
    await PersistenceService.markPremiumPromptShown(matchesCount);
    GameDialogs.showPremiumBenefits(context, source: 'auto_open');
  }

  void _showWinnerDialog(
      BuildContext context, ScoreProvider scoreProvider) async {
    bool shouldShowRating = false;

    // Evaluamos si corresponde mostrar el diálogo de valoración
    if (scoreProvider.winner == "nosotros") {
      final hasRated = await PersistenceService.getHasRatedApp();
      if (!hasRated) {
        final matchesCount =
            await PersistenceService.getMatchesCompletedCount();
        final lastRequestMatch =
            await PersistenceService.getLastRateRequestMatchCount();

        // Primera vez al nro 3, luego cada 10 partidos finalizados
        if (matchesCount >= 3 &&
            (lastRequestMatch == 0 ||
                (matchesCount - lastRequestMatch >= 10))) {
          shouldShowRating = true;
        }
      }
    }

    // Game finished — el resto del contexto (theme, modo, sonido, etc.)
    // viaja automáticamente vía super properties.
    AnalyticsService.logGameFinished(
      teamNosIsCustom: scoreProvider.nosotrosName != "NOSOTROS",
      teamEllosIsCustom: scoreProvider.ellosName != "ELLOS",
    );

    if (shouldShowRating && mounted) {
      // Registramos que preguntamos en este partido
      final matchesCount = await PersistenceService.getMatchesCompletedCount();
      PersistenceService.setLastRateRequestMatchCount(matchesCount);

      GameDialogs.showRatingDialog(
        context,
        scoreProvider,
        onRate: () async {
          await PersistenceService.setHasRatedApp(true);
          final inAppReview = InAppReview.instance;
          try {
            await inAppReview.openStoreListing();
          } catch (e) {
            debugPrint("Error opening store listing: $e");
          }
        },
        onLater: () {},
        onFeedback: () async {
          await PersistenceService.setHasRatedApp(true);
          SupportService.sendFeedbackEmail(
              subject: 'Puro Truco - ¿Cómo podemos mejorar?');
        },
      );

      // Mostramos ganador SIN anuncio para no saturar al usuario
      GameDialogs.showWinner(context, scoreProvider, silenceAd: true);
    } else {
      // Flujo original
      GameDialogs.showWinner(context, scoreProvider);
    }
  }

  Widget _buildTeamColumnContent(String name, int totalPoints, bool isBuenas,
      bool isNosotros, ScoreProvider scoreProvider, bool isDraggingBack,
      {bool highlight = false}) {
    final String teamKey = isNosotros ? "nosotros" : "ellos";

    return Container(
      color: highlight
          ? Colors.white.withOpacity(scoreProvider.appTheme.highlightOpacity)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with theme margin
          Padding(
            padding: EdgeInsets.only(
              right:
                  isNosotros ? scoreProvider.appTheme.nosotrosMarginRight : 0.0,
              left: !isNosotros ? scoreProvider.appTheme.ellosMarginLeft : 0.0,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showNameEditDialog(context, teamKey, name),
                  child: Container(
                    height:
                        30, // Fixed height to prevent shifting when text scales
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    width: double.infinity,
                    color: Colors.transparent,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontSize: 20,
                          color: scoreProvider.appTheme.slate,
                          letterSpacing: 0,
                          fontWeight: FontWeight.bold,
                          shadows: scoreProvider.appTheme.teamNameShadow,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  totalPoints.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: AppFonts.caminito,
                    fontSize: 32,
                    color: scoreProvider.appTheme.teamScoreColor,
                    shadows: scoreProvider.appTheme.teamNameShadow,
                  ),
                ),
                Text(
                  scoreProvider.getLabel(teamKey),
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 16,
                    color: isBuenas
                        ? scoreProvider.appTheme.buenas
                        : scoreProvider.appTheme.malas,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          // 2. Scoring Area
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              double availableHeight = constraints.maxHeight;
              double availableWidth = constraints.maxWidth;
              final int numGroups =
                  (scoreProvider.currentGameMode.milestone / 5).ceil();

              // We calculate slotSize based on the width MINUS the margin,
              // to keep the sticks exactly the same size and position as before.
              final double effectiveWidth = availableWidth -
                  (isNosotros
                      ? scoreProvider.appTheme.nosotrosMarginRight
                      : scoreProvider.appTheme.ellosMarginLeft);

              double slotSize = (availableHeight / numGroups)
                  .clamp(60.0, effectiveWidth < 60.0 ? 60.0 : effectiveWidth);

              // Pica Pica Markers
              List<Widget> picaMarkers = [];
              if (scoreProvider.picaPicaEnabled &&
                  scoreProvider.currentGameMode.totalPoints >= 30) {
                final int milestone = scoreProvider.currentGameMode.milestone;
                final double groupHeight = availableHeight / numGroups;

                bool anyoneReachedStart =
                    scoreProvider.nosotros >= scoreProvider.picaPicaStart ||
                        scoreProvider.ellos >= scoreProvider.picaPicaStart;
                bool anyoneReachedEnd =
                    scoreProvider.nosotros >= scoreProvider.picaPicaEnd ||
                        scoreProvider.ellos >= scoreProvider.picaPicaEnd;

                // Start Marker
                int picaStart = scoreProvider.picaPicaStart;
                bool startInThisPhase =
                    isBuenas ? picaStart >= milestone : picaStart <= milestone;
                if (startInThisPhase && !anyoneReachedStart) {
                  int localStart = isBuenas ? picaStart - milestone : picaStart;
                  double top = (localStart / 5) * groupHeight;

                  picaMarkers.add(Positioned(
                    top: (localStart == milestone) ? null : top,
                    bottom: (localStart == milestone) ? -8 : null,
                    left: 0,
                    right: 0,
                    child: PicaPicaLine(
                      label: "INICIO PICA PICA",
                      color: scoreProvider.appTheme.cream,
                      backgroundColor: scoreProvider.appTheme.navy,
                    ),
                  ));
                }

                // End Marker
                int picaEnd = scoreProvider.picaPicaEnd;
                bool endInThisPhase =
                    isBuenas ? picaEnd >= milestone : picaEnd <= milestone;
                if (endInThisPhase && !anyoneReachedEnd) {
                  int localEnd = isBuenas ? picaEnd - milestone : picaEnd;
                  double top = (localEnd / 5) * groupHeight;
                  final bool isSmallScreen = availableHeight < 500;

                  picaMarkers.add(Positioned(
                    top: (localEnd == milestone) ? null : top,
                    bottom: (localEnd == milestone) ? -8 : null,
                    left: 0,
                    right: 0,
                    child: PicaPicaLine(
                      label: "FIN PICA PICA",
                      color: scoreProvider.appTheme.cream,
                      backgroundColor: scoreProvider.appTheme.navy,
                      fontSize: isSmallScreen ? 10 : 12,
                      padding: isSmallScreen
                          ? const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2)
                          : const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                    ),
                  ));
                }
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Full width for Pica Pica
                  ...picaMarkers,

                  // Constrained width for Sticks (keeps them in place)
                  Padding(
                    padding: EdgeInsets.only(
                      right: isNosotros
                          ? scoreProvider.appTheme.nosotrosMarginRight
                          : 0.0,
                      left: !isNosotros
                          ? scoreProvider.appTheme.ellosMarginLeft
                          : 0.0,
                    ),
                    child: Column(
                      children: List.generate(numGroups, (groupIndex) {
                        int pointsInThisGroup =
                            (totalPoints - (groupIndex * 5)).clamp(0, 5);

                        if (pointsInThisGroup == 0 &&
                            totalPoints < (groupIndex * 5)) {
                          return const Expanded(child: SizedBox.shrink());
                        }

                        final int absoluteGroupIndex = isBuenas
                            ? groupIndex +
                                (scoreProvider.currentGameMode.milestone ~/ 5)
                            : groupIndex;

                        final bool isLastActiveGroup =
                            (totalPoints / 5).ceil() - 1 == groupIndex;

                        return Expanded(
                          child: Center(
                            child: pointsInThisGroup > 0
                                ? ScoreGroup(
                                    key: ValueKey(
                                        "group_${isNosotros ? "n" : "e"}_$absoluteGroupIndex"),
                                    points: pointsInThisGroup,
                                    size: slotSize * 0.9,
                                    team: teamKey,
                                    isDragging: isDraggingBack,
                                    groupIndex: absoluteGroupIndex,
                                    animateLast: !isDraggingBack &&
                                        isLastActiveGroup &&
                                        scoreProvider.lastPointTeam == teamKey,
                                    dropOffset: scoreProvider.lastDropOffset,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),
          ),

          SizedBox(
              height: 10 +
                  (scoreProvider.appTheme.footerAsset != null
                      ? scoreProvider.appTheme.footerHeight
                      : 0) +
                  20),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        content: SettingsDialogContent(
          onThemeLockedTap: (themeName) =>
              _showUnlockDialog(context, 'theme_$themeName', 'tema'),
          onPaletteLockedTap: (index) =>
              _showUnlockDialog(context, 'palette_$index', 'fósforo'),
          onBeanPaletteLockedTap: (index) =>
              _showUnlockDialog(context, 'bean_palette_$index', 'poroto'),
          onPremiumTap: () => _showUnlockDialog(context, 'premium', 'premium'),
          onRepeatTutorial: () {
            setState(() {
              _tutorialStep = 0;
            });
            _startGhostHandTutorial();
          },
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, String id, String type) {
    AnalyticsService.logLockedContentTapped(
      contentType: type,
      contentId: id,
    );
    GameDialogs.showUnlock(context, id, type);
  }

  Widget _buildFooter(BuildContext context, ScoreProvider scoreProvider) {
    return DragTarget<String>(
      onAccept: (team) {
        if (team == "nosotros") scoreProvider.removePointNosotros();
        if (team == "ellos") scoreProvider.removePointEllos();
      },
      builder: (context, candidateData, rejectedData) {
        final bool isClassicMode =
            scoreProvider.scoringMode == ScoringMode.classic ||
                (_isTutorialActive && _tutorialStep == 4);
        final bool isDragMode = scoreProvider.scoringMode == ScoringMode.drag &&
            !(_isTutorialActive && _tutorialStep == 4);
        final bool highlight = candidateData.isNotEmpty;

        final theme = scoreProvider.appTheme;
        final double topPadding =
            (theme.footerAsset != null ? theme.footerHeight : 0) + 20;

        return Container(
          width: double.infinity,
          color: highlight
              ? Colors.white.withOpacity(theme.highlightOpacity)
              : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drop zone above the box (extends the team's int drop area
              // through the footer ornament zone, but NOT over the box itself).
              DragTarget<int>(
                onMove: (details) {
                  final double screenWidth =
                      MediaQuery.of(context).size.width;
                  final String side = details.offset.dx + 20 < screenWidth / 2
                      ? "nosotros"
                      : "ellos";
                  if (_footerIntDragSide != side) {
                    setState(() => _footerIntDragSide = side);
                  }
                },
                onLeave: (_) {
                  if (_footerIntDragSide != null) {
                    setState(() => _footerIntDragSide = null);
                  }
                },
                onAcceptWithDetails: (details) {
                  final double screenWidth =
                      MediaQuery.of(context).size.width;
                  if (details.offset.dx + 20 < screenWidth / 2) {
                    scoreProvider.addPointNosotros(details.offset);
                  } else {
                    scoreProvider.addPointEllos(details.offset);
                  }
                  if (_footerIntDragSide != null) {
                    setState(() => _footerIntDragSide = null);
                  }
                },
                builder: (ctx, _, __) =>
                    SizedBox(height: topPadding, width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nosotros Buttons
              if (isClassicMode) ...[
                AbsorbPointer(
                  absorbing: _isTutorialActive,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScoreCircleButton(
                        key: _nosPlusKey,
                        onPressed: () => scoreProvider.addPointNosotros(),
                      ),
                      const SizedBox(height: 16),
                      ScoreCircleButton(
                        key: _nosMinusKey,
                        isMinus: true,
                        isEnabled: scoreProvider.nosotros > 0,
                        onPressed: () => scoreProvider.removePointNosotros(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],

              // Center Box
              if (scoreProvider.totalRemainingMatchsticks > 0)
                isDragMode
                    ? Draggable<int>(
                        key: const ValueKey("box_draggable"),
                        data: 1,
                        maxSimultaneousDrags: _isTutorialActive ? 0 : 1,
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.rotate(
                            angle: 0.1,
                            child: Transform.translate(
                              offset: const Offset(-5, -50),
                              child: scoreProvider.pointType == PointType.beans
                                  ? BeanWidget(
                                      size: 48,
                                      seed: 1,
                                      beanType:
                                          scoreProvider.currentBeanPalette.type)
                                  : MatchstickWidget(height: 100),
                            ),
                          ),
                        ),
                        childWhenDragging: MatchstickBox(
                            count: scoreProvider.totalRemainingMatchsticks - 1),
                        child: MatchstickBox(
                          key: _boxKey,
                          count: scoreProvider.totalRemainingMatchsticks,
                        ),
                      )
                    : MatchstickBox(
                        key: _boxKey,
                        count: scoreProvider.totalRemainingMatchsticks,
                      )
              else
                MatchstickBox(key: _boxKey, count: 0),

              // Ellos Buttons
              if (isClassicMode) ...[
                const SizedBox(width: 24),
                AbsorbPointer(
                  absorbing: _isTutorialActive,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScoreCircleButton(
                        key: _ellPlusKey,
                        onPressed: () => scoreProvider.addPointEllos(),
                      ),
                      const SizedBox(height: 16),
                      ScoreCircleButton(
                        key: _ellMinusKey,
                        isMinus: true,
                        isEnabled: scoreProvider.ellos > 0,
                        onPressed: () => scoreProvider.removePointEllos(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecoveryDialog(
      BuildContext context, ScoreProvider provider, Map<String, dynamic> data) {
    GameDialogs.showRecovery(context, provider, data);
  }

  void _startGhostHandTutorial() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? boxRender =
          _boxKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? targetRender =
          _nosotrosKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? restartRender =
          _restartKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? settingsRender =
          _settingsKey.currentContext?.findRenderObject() as RenderBox?;

      if (boxRender == null || targetRender == null) return;

      final boxPos = boxRender.localToGlobal(Offset.zero);
      final targetPos = targetRender.localToGlobal(Offset.zero);

      final boxCenter = Offset(boxPos.dx + boxRender.size.width / 2 - 20,
          boxPos.dy + boxRender.size.height / 2);

      final tableCenter = Offset(targetPos.dx + targetRender.size.width / 2,
          targetPos.dy + targetRender.size.height / 2 + 50);

      Offset start = tableCenter;
      Offset end = tableCenter;

      _handController.stop();

      if (_tutorialStep == 0) {
        // Box to Table
        start = boxCenter;
        end = tableCenter;
        _handController.duration = const Duration(seconds: 2);
        _handScaleAnimation = const AlwaysStoppedAnimation(1.0);
      } else if (_tutorialStep == 1) {
        // Table to Box
        start = tableCenter;
        end = boxCenter;
        _handController.duration = const Duration(seconds: 2);
        _handScaleAnimation = const AlwaysStoppedAnimation(1.0);
      } else if (_tutorialStep == 2) {
        // Tap (Quick pulse)
        start = tableCenter;
        end = tableCenter;
        _handController.duration = const Duration(milliseconds: 1000);
        _handScaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
        ]).animate(_handController);
      } else if (_tutorialStep == 3) {
        // Long Press (Slow hold)
        start = tableCenter;
        end = tableCenter;
        _handController.duration = const Duration(milliseconds: 2000);
        _handScaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
          TweenSequenceItem(tween: ConstantTween(0.8), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 20),
        ]).animate(_handController);
        _handController.repeat(reverse: false);
      } else if (_tutorialStep == 4) {
        // Classic Buttons (Tap sequence)
        final nPlus =
            _nosPlusKey.currentContext?.findRenderObject() as RenderBox?;
        final nMinus =
            _nosMinusKey.currentContext?.findRenderObject() as RenderBox?;
        final ePlus =
            _ellPlusKey.currentContext?.findRenderObject() as RenderBox?;
        final eMinus =
            _ellMinusKey.currentContext?.findRenderObject() as RenderBox?;

        if (nPlus != null &&
            nMinus != null &&
            ePlus != null &&
            eMinus != null) {
          final pos1 = nPlus.localToGlobal(nPlus.size.center(Offset.zero));
          final pos2 = nMinus.localToGlobal(nMinus.size.center(Offset.zero));
          final pos3 = ePlus.localToGlobal(ePlus.size.center(Offset.zero));
          final pos4 = eMinus.localToGlobal(eMinus.size.center(Offset.zero));

          _handController.duration = const Duration(milliseconds: 3200);
          _handMoveAnimation = TweenSequence<Offset>([
            TweenSequenceItem(tween: ConstantTween(pos1), weight: 25),
            TweenSequenceItem(tween: ConstantTween(pos2), weight: 25),
            TweenSequenceItem(tween: ConstantTween(pos3), weight: 25),
            TweenSequenceItem(tween: ConstantTween(pos4), weight: 25),
          ]).animate(_handController);

          _handScaleAnimation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 12.5),
            TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 12.5),
          ]).animate(_handController);

          setState(() {
            _showGhostHand = true;
            _isTutorialActive = true;
          });
          _handController.repeat(reverse: false);
          return;
        }
      } else if (_tutorialStep == 5) {
        // Team names (Alternating pulse)
        final RenderBox? ellosRender =
            _ellosKey.currentContext?.findRenderObject() as RenderBox?;
        final nosPos = targetPos.translate(60, 20);
        final ellPos = (ellosRender != null)
            ? ellosRender.localToGlobal(Offset.zero).translate(60, 20)
            : nosPos;

        _handController.duration = const Duration(milliseconds: 2400);
        _handMoveAnimation = TweenSequence<Offset>([
          TweenSequenceItem(tween: ConstantTween(nosPos), weight: 50),
          TweenSequenceItem(tween: ConstantTween(ellPos), weight: 50),
        ]).animate(_handController);

        _handScaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 25),
        ]).animate(_handController);

        setState(() {
          _showGhostHand = true;
          _isTutorialActive = true;
        });
        _handController.repeat(reverse: false);
        return;
      } else if (_tutorialStep == 6 && _limitScoreKey.currentContext != null) {
        // Limit Score
        final RenderBox? limitRender =
            _limitScoreKey.currentContext?.findRenderObject() as RenderBox?;
        if (limitRender != null) {
          final pos = limitRender.localToGlobal(Offset.zero);
          start = pos.translate(
              limitRender.size.width / 2, limitRender.size.height / 2);
          end = start;
          _handController.duration = const Duration(milliseconds: 1200);
          _handScaleAnimation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
          ]).animate(_handController);
        }
      } else if (_tutorialStep == 7 && restartRender != null) {
        // Reset Button
        final pos = restartRender.localToGlobal(Offset.zero);
        start = pos.translate(
            restartRender.size.width / 2, restartRender.size.height / 2);
        end = start;
        _handController.duration = const Duration(milliseconds: 1200);
        _handScaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
        ]).animate(_handController);
      } else if (_tutorialStep == 8 && settingsRender != null) {
        // Settings Button
        final pos = settingsRender.localToGlobal(Offset.zero);
        start = pos.translate(
            settingsRender.size.width / 2, settingsRender.size.height / 2);
        end = start;
        _handController.duration = const Duration(milliseconds: 1200);
        _handScaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
        ]).animate(_handController);
      } else {
        start = tableCenter;
        end = tableCenter;
        _handController.duration = const Duration(seconds: 1);
        _handScaleAnimation = const AlwaysStoppedAnimation(1.0);
      }

      setState(() {
        _handMoveAnimation = Tween<Offset>(
          begin: start,
          end: end,
        ).animate(CurvedAnimation(
          parent: _handController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic),
        ));
        _showGhostHand = true;
        _isTutorialActive = true;
      });

      _handController.repeat(reverse: false);
    });
  }

  void _skipTutorial() async {
    AnalyticsService.logTutorialSkip(_tutorialStep);
    setState(() {
      _isTutorialActive = false;
      _showGhostHand = false;
    });
    _handController.stop();
    await PersistenceService.setTutorialDone(true);
  }
}

class ScoreCircleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isMinus;
  final bool isEnabled;

  const ScoreCircleButton({
    super.key,
    required this.onPressed,
    this.isMinus = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ScoreProvider>(context).appTheme;
    final primaryColor = theme.classicButtonColor;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.3,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMinus ? Colors.transparent : primaryColor,
            border:
                isMinus ? Border.all(color: primaryColor, width: 2.5) : null,
            boxShadow: !isMinus && isEnabled
                ? [
                    BoxShadow(
                      color: theme.classicButtonShadowColor,
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SvgPicture.asset(
              isMinus ? 'assets/images/subtract.svg' : 'assets/images/add.svg',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _PicaPicaToast extends StatefulWidget {
  final String message;
  final Color background;
  final Color border;
  final Color textColor;

  const _PicaPicaToast({
    required this.message,
    required this.background,
    required this.border,
    required this.textColor,
  });

  @override
  State<_PicaPicaToast> createState() => _PicaPicaToastState();
}

class _PicaPicaToastState extends State<_PicaPicaToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 65),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.5))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              color: widget.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
