import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'services/ad_service.dart';
import 'providers/premium_provider.dart';
import 'providers/score_provider.dart';
import 'widgets/score_group_widget.dart';
import 'widgets/matchstick_widget.dart';
import 'widgets/matchstick_box.dart';
import 'theme/app_theme.dart';
import 'services/persistence_service.dart';
import 'widgets/truco_dialog.dart';
import 'widgets/truco_buttons.dart';

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

  final List<Map<String, String>> _tutorialSteps = [
    {
      "title": "Modo Arrastrar",
      "desc":
          "En modo arrastre, para agregar un fósforo tenes que arrastrarlo desde la caja hacia la mesa"
    },
    {
      "title": "Modo Arrastrar",
      "desc":
          "En modo arrastre, para sacar el último fósforo tenes que arrastrarlo desde la mesa hacia la caja"
    },
    {
      "title": "Modo Toque",
      "desc":
          "En modo toque, para agregar un fósforo tenes que hacer un toque sobre la mesa"
    },
    {
      "title": "Modo Toque",
      "desc":
          "En modo toque, para sacar un fósforo tenes que sostener el dedo sobre la mesa"
    },
    {
      "title": "Cambiar nombres",
      "desc": "Haciendo un toque acá podés cambiar el nombre de cada equipo."
    },
    {
      "title": "Puntuación total",
      "desc": "Acá podés ver los puntos totales de la partida."
    },
    {
      "title": "Comenzar de nuevo",
      "desc": "Tocá acá para resetear los puntos y empezar de cero."
    },
    {
      "title": "Menú de opciones",
      "desc":
          "Acá podés elegir nuevos temas, cambiar el modo de juego, decidir si preferís usar el control por arrastre o toque, ¡y más!"
    },
  ];

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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (scoreProvider.appTheme.headerAsset != null)
                          SvgPicture.asset(
                            scoreProvider.appTheme.headerAsset!,
                            height: 45,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.8),
                              BlendMode.srcIn,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                key: _restartKey,
                                icon: SvgPicture.asset(
                                  'assets/images/restart.svg',
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.7),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onPressed: () => _showResetConfirmationDialog(
                                    context, scoreProvider),
                              ),
                              IconButton(
                                key: _settingsKey,
                                icon: SvgPicture.asset(
                                  'assets/images/settings.svg',
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.7),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onPressed: () =>
                                    _showSettingsDialog(context, scoreProvider),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          Padding(
                            padding: EdgeInsets.only(
                              top: scoreProvider.appTheme.centerSectionOffset,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Solid background (hides the line)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scoreProvider
                                        .appTheme.centerCircleColor,
                                    border: scoreProvider
                                            .appTheme.hideCenterCircleBorder
                                        ? null
                                        : Border.all(
                                            color: scoreProvider
                                                .appTheme.accentColor
                                                .withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                    boxShadow: !scoreProvider
                                            .appTheme.hideCenterCircleBorder
                                        ? [
                                            BoxShadow(
                                              color: scoreProvider
                                                  .appTheme.accentColor
                                                  .withOpacity(0.35),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),

                                // 2. The ornament (Sun/AFA)
                                if (scoreProvider
                                        .appTheme.centerOrnamentAsset !=
                                    null)
                                  Transform.scale(
                                    scale: scoreProvider
                                        .appTheme.centerOrnamentScale,
                                    child: SvgPicture.asset(
                                      scoreProvider
                                          .appTheme.centerOrnamentAsset!,
                                      width: 56,
                                      height: 56,
                                    ),
                                  ),

                                // 3. The Number
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: scoreProvider
                                        .appTheme.scoreVerticalOffset,
                                  ),
                                  child: Text(
                                    key: _limitScoreKey,
                                    "${scoreProvider.currentGameMode.totalPoints}",
                                    style: TextStyle(
                                      fontFamily: AppFonts.caminito,
                                      fontSize:
                                          scoreProvider.appTheme.scoreFontSize,
                                      color: scoreProvider.appTheme.scoreColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                AnimatedBuilder(
                  animation: _handController,
                  builder: (context, child) {
                    final scale =
                        (_tutorialStep >= 2) ? _handScaleAnimation.value : 1.0;
                    return Positioned(
                      left: _handMoveAnimation.value.dx,
                      top: _handMoveAnimation.value.dy,
                      child: Opacity(
                        opacity: _handOpacityAnimation.value,
                        child: Transform.scale(
                          scale: scale,
                          child: Transform.rotate(
                            angle: -0.2,
                            child: SvgPicture.asset(
                              'assets/images/hand.svg',
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // 7. TUTORIAL NAVIGATION OVERLAY
              if (_isTutorialActive)
                Positioned(
                  top: (_tutorialStep < 4)
                      ? (MediaQuery.of(context).size.height < 700 ? 80 : 150)
                      : null,
                  bottom: (_tutorialStep >= 4)
                      ? (MediaQuery.of(context).size.height < 700 ? 80 : 150)
                      : null,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scoreProvider.appTheme.navy,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scoreProvider.appTheme.slate,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tutorialSteps[_tutorialStep]["title"]!,
                              style: TextStyle(
                                color: scoreProvider.appTheme.white,
                                fontFamily: AppFonts.oswald,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "${_tutorialStep + 1}/${_tutorialSteps.length}",
                              style: TextStyle(
                                color: scoreProvider.appTheme.white
                                    .withOpacity(0.5),
                                fontFamily: AppFonts.oswald,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _tutorialSteps[_tutorialStep]["desc"]!,
                              key: ValueKey<int>(_tutorialStep),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scoreProvider.appTheme.white
                                    .withOpacity(0.9),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: "OMITIR",
                                height: 40,
                                toUpperCase: true,
                                onPressed: () {
                                  setState(() {
                                    _isTutorialActive = false;
                                    _handController.stop();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: PrimaryButton(
                                text: _tutorialStep == _tutorialSteps.length - 1
                                    ? "FINALIZAR"
                                    : "SIGUIENTE",
                                height: 40,
                                onPressed: () {
                                  if (_tutorialStep <
                                      _tutorialSteps.length - 1) {
                                    setState(() {
                                      _tutorialStep++;
                                      _startGhostHandTutorial();
                                    });
                                  } else {
                                    setState(() {
                                      _isTutorialActive = false;
                                      _handController.stop();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                child: MatchstickWidget(height: 100),
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
              letterSpacing: 2,
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
    final String winnerKey = scoreProvider.winner!;
    final String winnerName = winnerKey == "nosotros"
        ? scoreProvider.nosotrosName
        : scoreProvider.ellosName;

    // Show Interstitial on victory if NOT premium
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Provider.of<PremiumProvider>(context, listen: false).isPremium) {
        AdService.showInterstitial();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrucoDialog(
        title: "¡Partida finalizada!",
        toUpperCaseTitle: false,
        titleFontSize: 20,
        titleColor: scoreProvider.appTheme.cream,
        marginHorizontal: 50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "GANADOR",
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 20,
                color: scoreProvider.appTheme.cream,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                winnerName.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 38,
                  color: scoreProvider.appTheme.slate,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${scoreProvider.nosotros.toString().padLeft(2, '0')} - ${scoreProvider.ellos.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontFamily: AppFonts.caminito,
                  fontSize: 52,
                  color: scoreProvider.appTheme.cream,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              PrimaryButton(
                text: "VOLVER A JUGAR",
                width: double.infinity,
                onPressed: () {
                  scoreProvider.triggerReset();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: "Deshacer",
                      toUpperCase: false,
                      type: SecondaryButtonType.secondary,
                      iconAsset: 'assets/images/undo_icon.svg',
                      onPressed: () {
                        if (winnerKey == "nosotros") {
                          scoreProvider.removePointNosotros();
                        } else {
                          scoreProvider.removePointEllos();
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SecondaryButton(
                      text: "Compartir",
                      toUpperCase: false,
                      iconAsset: 'assets/images/share_icon.svg',
                      onPressed: () {
                        final message =
                            "¡Gané al Truco! $winnerName venció ${scoreProvider.nosotros} a ${scoreProvider.ellos}. #AnotadorDeTruco";
                        Share.share(message);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumnContent(String name, int totalPoints, bool isBuenas,
      bool isNosotros, ScoreProvider scoreProvider, bool isDraggingBack,
      {bool highlight = false}) {
    final String teamKey = isNosotros ? "nosotros" : "ellos";

    return Container(
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
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
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
              letterSpacing: 1.2,
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
    );
  }

  void _showSettingsDialog(BuildContext context, ScoreProvider scoreProvider) {
    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        content: _SettingsDialogContent(
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
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        title: "¡LLEVÁ TU ANOTADOR A OTRO NIVEL! 🚀",
        contentText: id == 'premium'
            ? "Convertite en premium para usar todos los temas, diseños de fósforos y eliminar la publicidad para siempre."
            : "Este diseño es exclusivo de la versión Premium. Podés desbloquearlo temporalmente viendo un video.",
        actions: [
          Column(
            children: [
              PrimaryButton(
                text: "SER PREMIUM",
                width: double.infinity,
                onPressed: () {
                  premiumProvider.buyPremium();
                  Navigator.pop(context);
                },
              ),
              if (id != 'premium') ...[
                const SizedBox(height: 16),
                SecondaryButton(
                  text: "VER VIDEO (24HS GRATIS)",
                  width: double.infinity,
                  toUpperCase: true,
                  onPressed: () {
                    AdService.showRewardedAd(
                      onUserEarnedReward: () {
                        premiumProvider.unlockTemporarily(id);
                      },
                      onAdNotReady: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "El video todavía no está listo. Probá de nuevo en unos segundos."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "QUIZÁS MÁS TARDE",
                  style: TextStyle(
                      color: scoreProvider.appTheme.white.withOpacity(0.5),
                      fontFamily: AppFonts.oswald),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                          child: MatchstickWidget(height: 100),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrucoDialog(
        title: "Tenés una partida en curso",
        contentText: "¿Querés continuarla o empezar una nueva?",
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: "Nueva partida",
                  toUpperCase: true,
                  onPressed: () {
                    Navigator.pop(context);
                    provider.triggerReset();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: "Continuar partida",
                  onPressed: () {
                    Navigator.pop(context);
                    provider.restoreGame(data);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _nextTutorialStep() {
    if (_tutorialStep < _tutorialSteps.length - 1) {
      setState(() {
        _tutorialStep++;
      });
      _startGhostHandTutorial();
    } else {
      _skipTutorial();
    }
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

class _SettingsDialogContent extends StatefulWidget {
  final Function(String) onThemeLockedTap;
  final Function(int) onPaletteLockedTap;
  final VoidCallback onPremiumTap;
  final VoidCallback onRepeatTutorial;

  const _SettingsDialogContent({
    required this.onThemeLockedTap,
    required this.onPaletteLockedTap,
    required this.onPremiumTap,
    required this.onRepeatTutorial,
  });

  @override
  State<_SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<_SettingsDialogContent> {
  int currentPane = 0; // 0: Main, 1: Customization, 2: Game Mode
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final bool isSmallScreen = MediaQuery.of(context).size.height < 700;

    // Title based on pane
    String title = "AJUSTES";
    if (currentPane == 1) title = "DISEÑO (FÓSFOROS)";
    if (currentPane == 2) title = "MODO DE JUEGO";

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
                  onPressed: () => setState(() => currentPane = 0),
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
                letterSpacing: 2,
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
        const SizedBox(height: 24),

        if (currentPane == 0) ...[
          // --- PANE 0: MAIN SETTINGS ---
          _buildMenuActionItem(
            label: "SONIDO",
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
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuActionItem(
            label: "MODO DE CONTROL",
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: scoreProvider.appTheme.slate.withOpacity(0.1),
              ),
              onPressed: () {
                scoreProvider.setScoringMode(
                    scoreProvider.scoringMode == ScoringMode.drag
                        ? ScoringMode.tap
                        : ScoringMode.drag);
              },
              child: Text(
                scoreProvider.scoringMode == ScoringMode.drag
                    ? "ARRASTRAR"
                    : "TOQUE",
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 14,
                  color: scoreProvider.appTheme.cream,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "MODO DE JUEGO",
            onTap: () => setState(() => currentPane = 2),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "DISEÑO (FÓSFOROS)",
            onTap: () => setState(() => currentPane = 1),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),

          if (!premiumProvider.isPremium) ...[
            _buildMenuNavigationItem(
              label: "HACERME PREMIUM 🚀",
              onTap: () {
                Navigator.pop(context); // Close settings
                premiumProvider.buyPremium();
              },
              scoreProvider: scoreProvider,
              isSmallScreen: isSmallScreen,
            ),
            Divider(color: scoreProvider.appTheme.slate, height: 1),
          ],

          _buildMenuNavigationItem(
            label: "RESTAURAR COMPRAS 🔄",
            onTap: () async {
              await premiumProvider.restorePurchases();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Buscando compras anteriores...")));
              }
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "REPETIR TUTORIAL",
            onTap: () {
              Navigator.pop(context);
              widget.onRepeatTutorial();
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),

          const SizedBox(height: 24),

          // Share Button
          SecondaryButton(
            text: "Compartir app",
            width: double.infinity,
            iconAsset: 'assets/images/share_icon.svg',
            onPressed: () {
              Share.share(
                  "¡Mirá este anotador de Truco premium! Bajalo acá: [LINK]");
            },
          ),
        ] else if (currentPane == 1) ...[
          // --- PANE 1: DESIGN (THEMES & PALETTES) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text("TEMA DE LA APP",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 1.5)),
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
                            // Fondo según el tema
                            if (theme.name == "NAVY PROFUNDO")
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: SvgPicture.asset(
                                        'assets/images/footer.svg',
                                        fit: BoxFit.contain),
                                  ),
                                ),
                              )
                            else if (theme.name == "ARGENTINA")
                              Positioned.fill(
                                child: Column(
                                  children: [
                                    Expanded(
                                        child: Container(
                                            color: const Color(0xFF74ACDF))),
                                    Expanded(
                                      child: Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: SvgPicture.asset(
                                              'assets/images/sun.svg',
                                              height: 16,
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Container(
                                            color: const Color(0xFF74ACDF))),
                                  ],
                                ),
                              )
                            else if (theme.backgroundAsset != null)
                              Positioned.fill(
                                child: Image.asset(theme.backgroundAsset!,
                                    fit: BoxFit.cover),
                              ),

                            // Lock, check icon OR Countdown
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
                                    letterSpacing: 1.5,
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text("DISEÑO DE FÓSFOROS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 1.5)),
              ),
              Wrap(
                spacing: isSmallScreen ? 12 : 16,
                runSpacing: isSmallScreen ? 12 : 16,
                children: availablePalettes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final palette = entry.value;
                  final isSelected =
                      scoreProvider.currentPalette.name == palette.name;
                  final isLocked = !premiumProvider.isPaletteUnlocked(index);
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: isSmallScreen ? 44 : 48,
                          height: isSmallScreen ? 44 : 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                palette.headColors[0],
                                palette.headColors.last
                              ],
                            ),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white10,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: palette.headColors.first
                                            .withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2)
                                  ]
                                : null,
                          ),
                        ),
                        if (isLocked)
                          const Icon(Icons.lock, color: Colors.white, size: 18),
                        if (timeLeft != null)
                          Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.black45),
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
                  );
                }).toList(),
              ),
            ],
          ),
        ] else if (currentPane == 2) ...[
          // --- PANE 2: GAME MODE ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
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
                          color: scoreProvider.appTheme.white.withOpacity(0.2),
                          size: 20),
                  onTap: () {
                    scoreProvider.setGameMode(mode);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuActionItem({
    required String label,
    required Widget trailing,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          fontSize: 16,
          color: scoreProvider.appTheme.cream,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildMenuNavigationItem({
    required String label,
    required VoidCallback onTap,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          fontSize: 16,
          color: scoreProvider.appTheme.cream,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: scoreProvider.appTheme.cream),
      onTap: onTap,
    );
  }
}
