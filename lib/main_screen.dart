import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/ad_service.dart';
import 'providers/score_provider.dart';
import 'widgets/score_group_widget.dart';
import 'widgets/matchstick_widget.dart';
import 'widgets/matchstick_box.dart';
import 'theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey _boxKey = GlobalKey();
  final Map<String, Timer?> _longPressTimers = {};
  Offset _lastPointerDownPos = Offset.zero;
  String? _lastWinnerShown; // Track to show dialog only once

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
                                icon: SvgPicture.asset(
                                  'assets/images/restart.svg',
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.7),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onPressed: () => scoreProvider.triggerReset(),
                              ),
                              IconButton(
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
                              ),
                              _buildVerticalDivider(scoreProvider),
                              _buildTeamSection(
                                context,
                                scoreProvider.ellosName,
                                scoreProvider.ellos,
                                false,
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
                                    color: scoreProvider.appTheme.centerCircleColor,
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
                                if (scoreProvider.appTheme.centerOrnamentAsset !=
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
                                    "${scoreProvider.currentGameMode.totalPoints}",
                                    style: TextStyle(
                                      fontFamily: AppFonts.caminito,
                                      fontSize:
                                          scoreProvider.appTheme.scoreFontSize,
                                      color:
                                          scoreProvider.appTheme.scoreColor,
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
                        colorFilter: scoreProvider.appTheme.footerAsset!
                                .contains('dibu')
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
    final RenderBox? box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    return Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 100);
  }

  Widget _buildTeamSection(
    BuildContext context,
    String name,
    int score,
    bool isNosotros,
  ) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final String teamKey = isNosotros ? "nosotros" : "ellos";
    final bool isTapMode = scoreProvider.scoringMode == ScoringMode.tap;

    if (isTapMode) {
      final bool isBuenas = scoreProvider.isBuenas(teamKey);
      int totalPoints = scoreProvider.getDisplayPoints(teamKey);

      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _longPressTimers[teamKey]?.cancel();
            _longPressTimers[teamKey] = Timer(const Duration(milliseconds: 200), () {
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
          child: _buildTeamColumnContent(name, totalPoints, isBuenas, isNosotros, scoreProvider, false),
        ),
      );
    }

    return Expanded(
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

          if ((isNosotros ? scoreProvider.nosotros : scoreProvider.ellos) == scoreProvider.currentGameMode.milestone && showMilestone) {
             totalPoints = scoreProvider.currentGameMode.milestone;
          }
          if ((isNosotros ? (scoreProvider.nosotros == scoreProvider.currentGameMode.totalPoints) : (scoreProvider.ellos == scoreProvider.currentGameMode.totalPoints)) && showMilestone) {
             totalPoints = scoreProvider.currentGameMode.milestone;
          }
          
          return Listener(
            onPointerDown: (event) => _lastPointerDownPos = event.position,
            child: Draggable<String>(
              data: isNosotros ? "nosotros" : "ellos",
              dragAnchorStrategy: pointerDragAnchorStrategy,
              maxSimultaneousDrags: (isNosotros ? scoreProvider.nosotros : scoreProvider.ellos) > 0 ? 1 : 0,
              onDragStarted: () => scoreProvider.setDraggingBack(isNosotros ? "nosotros" : "ellos", true),
              onDraggableCanceled: (velocity, offset) {
                scoreProvider.triggerRevert(isNosotros ? "nosotros" : "ellos", offset);
              },
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  scoreProvider.setDraggingBack(isNosotros ? "nosotros" : "ellos", false);
                }
              },
              feedback: TweenAnimationBuilder<Offset>(
                key: ValueKey("fb_${isNosotros ? "n" : "e"}_$totalPoints"),
                tween: Tween(
                  begin: ((isNosotros ? scoreProvider.lastStickPosNosotros : scoreProvider.lastStickPosEllos) ?? _lastPointerDownPos) - _lastPointerDownPos,
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
              childWhenDragging: _buildTeamColumnContent(name, totalPoints, isBuenas, isNosotros, scoreProvider, true),
              child: _buildTeamColumnContent(name, totalPoints, isBuenas, isNosotros, scoreProvider, false, 
                highlight: candidateData.isNotEmpty),
            ),
          );
        },
      ),
    );
  }

  void _showNameEditDialog(BuildContext context, String teamKey, String currentName) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scoreProvider.appTheme.navyLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            style: TextStyle(
              color: scoreProvider.appTheme.cream,
              fontFamily: AppFonts.caminito,
              fontSize: 24,
            ),
            decoration: InputDecoration(
              hintText: "Ej: LOS CRACKS",
              hintStyle: TextStyle(color: scoreProvider.appTheme.white.withOpacity(0.3)),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCELAR",
                style: TextStyle(
                  color: scoreProvider.appTheme.white.withOpacity(0.5),
                  fontFamily: AppFonts.oswald,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  scoreProvider.setTeamName(teamKey, controller.text);
                }
                Navigator.pop(context);
              },
              child: Text(
                "GUARDAR",
                style: TextStyle(
                  color: scoreProvider.appTheme.buenas,
                  fontFamily: AppFonts.oswald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWinnerDialog(BuildContext context, ScoreProvider scoreProvider) {
    final String winnerKey = scoreProvider.winner!;
    final String winnerName = winnerKey == "nosotros" ? scoreProvider.nosotrosName : scoreProvider.ellosName;

    // Show Interstitial on victory as requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.showInterstitial();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scoreProvider.appTheme.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: scoreProvider.appTheme.slate, width: 1),
          ),
          title: Center(
            child: Text(
              "¡Partida finalizada!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 20,
                color: scoreProvider.appTheme.cream,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "GANADOR",
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 16,
                  color: scoreProvider.appTheme.white,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                winnerName.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 38,
                  color: scoreProvider.appTheme.slate,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${scoreProvider.nosotros.toString().padLeft(2, '0')}  —  ${scoreProvider.ellos.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontFamily: AppFonts.caminito,
                  fontSize: 52,
                  color: scoreProvider.appTheme.cream,
                ),
              ),
              const SizedBox(height: 32),
              
              // Main Action
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    scoreProvider.triggerReset();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scoreProvider.appTheme.slate,
                    foregroundColor: scoreProvider.appTheme.cream,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "VOLVER A JUGAR",
                    style: TextStyle(
                      fontFamily: AppFonts.oswald, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, // SemiBold
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Secondary Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (winnerKey == "nosotros") {
                          scoreProvider.removePointNosotros();
                        } else {
                          scoreProvider.removePointEllos();
                        }
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: scoreProvider.appTheme.malas, width: 1.5),
                        foregroundColor: scoreProvider.appTheme.malas,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.undo_outlined, size: 18),
                      label: const Text(
                        "Deshacer",
                        style: TextStyle(fontFamily: 'Oswald', fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final message = "¡Gané al Truco! $winnerName venció ${scoreProvider.nosotros} a ${scoreProvider.ellos}. #AnatadorDeTruco";
                        Share.share(message);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: scoreProvider.appTheme.cream, width: 1.5),
                        foregroundColor: scoreProvider.appTheme.cream,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text(
                        "Compartir",
                        style: TextStyle(fontFamily: AppFonts.oswald, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamColumnContent(String name, int totalPoints, bool isBuenas, bool isNosotros, ScoreProvider scoreProvider, bool isDraggingBack, {bool highlight = false}) {
    final String teamKey = isNosotros ? "nosotros" : "ellos";
    
    return Container(
      color: highlight ? Colors.white.withOpacity(0.05) : Colors.transparent,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showNameEditDialog(context, teamKey, name),
            child: Container(
              padding: EdgeInsets.zero,
              color: Colors.transparent, // Expand hit area
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 20,
                  color: scoreProvider.appTheme.slate,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
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
              color: isBuenas ? scoreProvider.appTheme.buenas : scoreProvider.appTheme.malas,
              letterSpacing: 1.2,
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double availableHeight = constraints.maxHeight;
                  double availableWidth = constraints.maxWidth;
                  final int numGroups = (scoreProvider.currentGameMode.milestone / 5).ceil();
                  double slotSize = (availableHeight / numGroups).clamp(60.0, availableWidth);

                  return Column(
                    children: List.generate(numGroups, (groupIndex) {
                      int pointsInThisGroup = (totalPoints - (groupIndex * 5)).clamp(0, 5);
                      
                      if (pointsInThisGroup == 0 && totalPoints < (groupIndex * 5)) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      final int absoluteGroupIndex = isBuenas 
                        ? groupIndex + (scoreProvider.currentGameMode.milestone ~/ 5) 
                        : groupIndex;

                      final bool isLastActiveGroup = (totalPoints / 5).ceil() - 1 == groupIndex;

                      return Expanded(
                        child: Center(
                          child: pointsInThisGroup > 0 
                            ? ScoreGroup(
                                key: ValueKey("group_${isNosotros ? "n" : "e"}_$absoluteGroupIndex"),
                                points: pointsInThisGroup,
                                size: slotSize * 0.9,
                                team: teamKey,
                                isDragging: isDraggingBack,
                                groupIndex: absoluteGroupIndex,
                                animateLast: !isDraggingBack && isLastActiveGroup &&
                                    scoreProvider.lastPointTeam == teamKey,
                                dropOffset: scoreProvider.lastDropOffset,
                              )
                            : const SizedBox.shrink(),
                        ),
                      );
                    }),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, ScoreProvider scoreProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              const Center(child: _SettingsDialogContent()),
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _BannerAdWidget(),
              ),
            ],
          ),
        );
      },
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
}

class _SettingsDialogContent extends StatefulWidget {
  const _SettingsDialogContent();

  @override
  State<_SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<_SettingsDialogContent> {
  int currentPane = 0; // 0: Main, 1: Customization, 2: Game Mode

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);

    String title = "AJUSTES";
    if (currentPane == 1) title = "DISEÑO (FÓSFOROS)";
    if (currentPane == 2) title = "MODO DE JUEGO";

    return Dialog(
      backgroundColor: scoreProvider.appTheme.navy,
      insetPadding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: scoreProvider.appTheme.slate, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                      icon: Icon(Icons.arrow_back, color: scoreProvider.appTheme.cream),
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
                trailing: Switch(
                  value: !scoreProvider.isMuted,
                  onChanged: (val) {
                    scoreProvider.setMuted(!val);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: scoreProvider.appTheme.slate,
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
              Divider(color: scoreProvider.appTheme.slate, height: 1),
              _buildMenuActionItem(
                label: "MODO DE CONTROL",
                scoreProvider: scoreProvider,
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: scoreProvider.appTheme.slate.withOpacity(0.1),
                  ),
                  onPressed: () {
                    scoreProvider.setScoringMode(
                      scoreProvider.scoringMode == ScoringMode.drag 
                        ? ScoringMode.tap 
                        : ScoringMode.drag
                    );
                  },
                  child: Text(
                    scoreProvider.scoringMode == ScoringMode.drag ? "ARRASTRAR" : "TOQUE",
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
              ),
              Divider(color: scoreProvider.appTheme.slate, height: 1),
              _buildMenuNavigationItem(
                label: "DISEÑO (FÓSFOROS)",
                onTap: () => setState(() => currentPane = 1),
                scoreProvider: scoreProvider,
              ),
              Divider(color: scoreProvider.appTheme.slate, height: 1),
              
              const SizedBox(height: 24),
              
              // Share Button
              OutlinedButton.icon(
                onPressed: () {
                  Share.share("¡Mirá este anotador de Truco premium! Bajalo acá: [LINK]");
                },
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  "Compartir app",
                  style: TextStyle(fontFamily: 'Oswald', fontSize: 16, letterSpacing: 0.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scoreProvider.appTheme.cream,
                  side: BorderSide(color: scoreProvider.appTheme.cream),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (currentPane == 1) ...[
              // --- PANE 1: DESIGN (THEMES & PALETTES) ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "TEMA DE LA APP", 
                          style: TextStyle(
                            fontFamily: AppFonts.oswald, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: scoreProvider.appTheme.slate, 
                            letterSpacing: 1.5
                          )
                        ),
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
                          return GestureDetector(
                            onTap: () {
                              scoreProvider.setAppTheme(theme);
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
                                             child: SvgPicture.asset('assets/images/footer.svg', fit: BoxFit.contain),
                                           ),
                                         ),
                                       )
                                    else if (theme.name == "ARGENTINA")
                                       Positioned.fill(
                                         child: Column(
                                           children: [
                                             Expanded(child: Container(color: const Color(0xFF74ACDF))),
                                             Expanded(
                                               child: Container(
                                                 color: Colors.white,
                                                 child: Center(
                                                   child: SvgPicture.asset('assets/images/sun.svg', height: 16, fit: BoxFit.contain),
                                                  ),
                                               ),
                                             ),
                                             Expanded(child: Container(color: const Color(0xFF74ACDF))),
                                           ],
                                         ),
                                       )
                                    else if (theme.backgroundAsset != null)
                                       Positioned.fill(
                                         child: Image.asset(theme.backgroundAsset!, fit: BoxFit.cover),
                                       ),
                                    
                                    // Check icon only
                                    if (isSelected)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: Icon(Icons.check, size: 12, color: theme.navy),
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
                        child: Text(
                          "DISEÑO DE FÓSFOROS", 
                          style: TextStyle(
                            fontFamily: AppFonts.oswald, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: scoreProvider.appTheme.slate, 
                            letterSpacing: 1.5
                          )
                        ),
                      ),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: availablePalettes.map((palette) {
                          final isSelected = scoreProvider.currentPalette.name == palette.name;
                          return GestureDetector(
                            onTap: () {
                              scoreProvider.setPalette(palette);
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [palette.headColors[0], palette.headColors.last],
                                ),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white10,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: palette.headColors.first.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                                ] : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (currentPane == 2) ...[
              // --- PANE 2: GAME MODE ---
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableModes.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final mode = availableModes[index];
                    final isSelected = scoreProvider.currentGameMode.label == mode.label;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        mode.label,
                        style: TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontSize: 16,
                          color: isSelected ? scoreProvider.appTheme.cream : Colors.white70,
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(Icons.radio_button_checked, color: scoreProvider.appTheme.cream, size: 20)
                        : Icon(Icons.radio_button_off, color: scoreProvider.appTheme.white.withOpacity(0.2), size: 20),
                      onTap: () {
                        scoreProvider.setGameMode(mode);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuNavigationItem({
    required String label,
    required VoidCallback onTap,
    required ScoreProvider scoreProvider,
  }) {
    return ListTile(
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

  Widget _buildMenuActionItem({
    required String label,
    required Widget trailing,
    required ScoreProvider scoreProvider,
  }) {
    return ListTile(
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
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBannerLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble() + 8,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
