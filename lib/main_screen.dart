import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'providers/score_provider.dart';
import 'widgets/score_group_widget.dart';
import 'widgets/matchstick_widget.dart';
import 'widgets/bean_widget.dart';
import 'widgets/matchstick_box.dart';
import 'theme/app_theme.dart';
import 'services/persistence_service.dart';
import 'widgets/truco_dialog.dart';
import 'widgets/truco_buttons.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/tutorial_overlay.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/main_screen_widgets.dart';

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

  late AnimationController _handController;
  late Animation<Offset> _handMoveAnimation;
  late Animation<double> _handOpacityAnimation;
  bool _showGhostHand = false;

  final Map<String, Timer?> _longPressTimers = {};
  Offset _lastPointerDownPos = Offset.zero;
  String? _lastWinnerShown;
  int _tutorialStep = 0;
  bool _isTutorialActive = false;



  late Animation<double> _handScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      await scoreProvider.loadSettings();

      final data = await PersistenceService.loadAll();
      final nosotros = data[PersistenceService.keyNosotrosScore] ?? 0;
      final ellos = data[PersistenceService.keyEllosScore] ?? 0;
      final targetScore = scoreProvider.currentGameMode.totalPoints;

      // Solo mostramos recuperar si alguien tiene puntos PERO nadie llegó al límite
      if ((nosotros > 0 || ellos > 0) &&
          (nosotros < targetScore && ellos < targetScore)) {
        if (mounted) {
          _showRecoveryDialog(context, scoreProvider, data);
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
    _handController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, child) {
        // Handle winner dialog
        if (scoreProvider.winner != null) {
          if (_lastWinnerShown != scoreProvider.winner) {
            _lastWinnerShown = scoreProvider.winner;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWinnerDialog(context, scoreProvider);
            });
          }
        } else {
          _lastWinnerShown = null;
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: scoreProvider.appTheme.navy,
          body: Stack(
            children: [
              // 0. Global Background Image
              if (scoreProvider.appTheme.backgroundAsset != null)
                Positioned.fill(
                  child: Image.asset(
                    scoreProvider.appTheme.backgroundAsset!,
                    fit: BoxFit.cover,
                  ),
                ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 1. Header (Buttons & Ornament Aligned)
                    MainHeader(
                      restartKey: _restartKey,
                      settingsKey: _settingsKey,
                      onRestart: () =>
                          _showResetConfirmationDialog(context, scoreProvider),
                      onSettings: _showSettingsDialog,
                    ),

                    const SizedBox(height: 10),

                    // 2. Main Scoring Table
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Scoring Table (Background)
                          Row(
                            children: [
                              _buildTeamSection(
                                context,
                                scoreProvider.nosotrosName,
                                scoreProvider.nosotros,
                                true,
                                key: _nosotrosKey,
                              ),
                              _buildVerticalDivider(scoreProvider),
                              _buildTeamSection(
                                context,
                                scoreProvider.ellosName,
                                scoreProvider.ellos,
                                false,
                                key: _ellosKey,
                              ),
                            ],
                          ),

                          // Floating Score Circle (Top overlap)
                          CenterScoreCircle(
                            limitScoreKey: _limitScoreKey,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Footer Ornament
                    if (scoreProvider.appTheme.footerAsset != null)
                      SvgPicture.asset(
                        scoreProvider.appTheme.footerAsset!,
                        height: scoreProvider.appTheme.footerHeight,
                        colorFilter:
                            scoreProvider.appTheme.footerAsset!.contains('dibu')
                                ? null
                                : ColorFilter.mode(
                                    Colors.white.withOpacity(0.8),
                                    BlendMode.srcIn,
                                  ),
                      ),

                    const SizedBox(height: 20),

                    // 5. Matchstick Box
                    _buildFooter(context, scoreProvider),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 6. GHOST HAND OVERLAY
              if (_showGhostHand)
                GhostHandOverlay(
                  controller: _handController,
                  moveAnimation: _handMoveAnimation,
                  opacityAnimation: _handOpacityAnimation,
                  scaleAnimation: _handScaleAnimation,
                  useScale: _tutorialStep >= 2,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider(ScoreProvider scoreProvider) {
    return Container(
      width: 1,
      height: double.infinity,
      color: scoreProvider.appTheme.dividerColor.withOpacity(0.15),
      margin: EdgeInsets.zero,
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

          return Listener(
            onPointerDown: (event) => _lastPointerDownPos = event.position,
            child: Draggable<String>(
              data: isNosotros ? "nosotros" : "ellos",
              dragAnchorStrategy: pointerDragAnchorStrategy,
              maxSimultaneousDrags: _isTutorialActive
                  ? 0
                  : (isNosotros
                              ? scoreProvider.nosotros
                              : scoreProvider.ellos) >
                          0
                      ? 1
                      : 0,
              onDragStarted: () => scoreProvider.setDraggingBack(
                  isNosotros ? "nosotros" : "ellos", true),
              onDraggableCanceled: (velocity, offset) {
                scoreProvider.triggerRevert(
                    isNosotros ? "nosotros" : "ellos", offset);
              },
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  scoreProvider.setDraggingBack(
                      isNosotros ? "nosotros" : "ellos", false);
                }
              },
              feedback: TweenAnimationBuilder<Offset>(
                key: ValueKey("fb_${isNosotros ? "n" : "e"}_$totalPoints"),
                tween: Tween(
                  begin: ((isNosotros
                              ? scoreProvider.lastStickPosNosotros
                              : scoreProvider.lastStickPosEllos) ??
                          _lastPointerDownPos) -
                      _lastPointerDownPos,
                  end: Offset.zero,
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset,
                    child: child,
                  );
                },
                child: scoreProvider.pointType == PointType.beans
                    ? BeanWidget(size: 48, seed: totalPoints, beanType: scoreProvider.currentBeanPalette.type)
                    : MatchstickWidget(height: 100),
              ),
              childWhenDragging: _buildTeamColumnContent(
                  name, totalPoints, isBuenas, isNosotros, scoreProvider, true),
              child: _buildTeamColumnContent(
                  name, totalPoints, isBuenas, isNosotros, scoreProvider, false,
                  highlight: candidateData.isNotEmpty),
            ),
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
                    scoreProvider.triggerReset();
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

  void _showWinnerDialog(BuildContext context, ScoreProvider scoreProvider) {
    GameDialogs.showWinner(context, scoreProvider);
  }


  Widget _buildTeamColumnContent(String name, int totalPoints, bool isBuenas,
      bool isNosotros, ScoreProvider scoreProvider, bool isDraggingBack,
      {bool highlight = false}) {
    final String teamKey = isNosotros ? "nosotros" : "ellos";

    return Padding(
      padding: EdgeInsets.only(
        right: isNosotros ? scoreProvider.appTheme.nosotrosMarginRight : 0.0,
        left: !isNosotros ? scoreProvider.appTheme.ellosMarginLeft : 0.0,
      ),
      child: Container(
        color: highlight ? Colors.white.withOpacity(0.05) : Colors.transparent,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showNameEditDialog(context, teamKey, name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                width: double.infinity,
                color: Colors.transparent, // Expand hit area
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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

            // Status Label (Buenas/Malas)
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

            Expanded(
              child: Padding(
                padding: EdgeInsets.zero,
                child: LayoutBuilder(builder: (context, constraints) {
                  double availableHeight = constraints.maxHeight;
                  double availableWidth = constraints.maxWidth;
                  final int numGroups =
                      (scoreProvider.currentGameMode.milestone / 5).ceil();
                  double slotSize =
                      (availableHeight / numGroups).clamp(60.0, availableWidth);

                  return Column(
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
                  );
                }),
              ),
            ),
          ],
        ),
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
    GameDialogs.showUnlock(context, id, type);
  }

  Widget _buildFooter(BuildContext context, ScoreProvider scoreProvider) {
    return DragTarget<String>(
      onAccept: (team) {
        if (team == "nosotros") scoreProvider.removePointNosotros();
        if (team == "ellos") scoreProvider.removePointEllos();
      },
      builder: (context, candidateData, rejectedData) {
        final bool isDragMode = scoreProvider.scoringMode == ScoringMode.drag;

        return Column(
          children: [
            if (scoreProvider.totalRemainingMatchsticks > 0)
              isDragMode
                  ? Draggable<int>(
                      key: const ValueKey("box_draggable"),
                      data: 1,
                      maxSimultaneousDrags: _isTutorialActive ? 0 : 1,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: Transform.rotate(
                        angle: 0.1,
                        child: Transform.translate(
                          offset: const Offset(-5, -50),
                          child: scoreProvider.pointType == PointType.beans
                              ? BeanWidget(size: 48, seed: 1, beanType: scoreProvider.currentBeanPalette.type)
                              : MatchstickWidget(height: 100),
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
          ],
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
      return; // Salteo el setState de abajo que pisa el MoveAnimation
    } else if (_tutorialStep == 5 && _limitScoreKey.currentContext != null) {
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
    } else if (_tutorialStep == 6 && restartRender != null) {
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
    } else if (_tutorialStep == 7 && settingsRender != null) {
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
  }

  void _skipTutorial() async {
    setState(() {
      _isTutorialActive = false;
      _showGhostHand = false;
    });
    _handController.stop();
    await PersistenceService.setTutorialDone(true);
  }
}
