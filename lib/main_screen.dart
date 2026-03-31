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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
          backgroundColor: const Color(0xFF161931),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 1. Header (Buttons & Ornament Aligned)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/header.svg',
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
                            onPressed: () => _showSettingsDialog(context, scoreProvider),
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
                          _buildVerticalDivider(),
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
                        padding: const EdgeInsets.only(top: 10), // Small margin from the ornament
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF161931), // Match background color for cleanup
                            border: Border.all(
                              color: const Color(0xFFEFEBE2).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "${scoreProvider.currentGameMode.totalPoints}",
                              style: TextStyle(
                                fontFamily: 'CaminitoBase',
                                fontSize: 26,
                                color: const Color(0xFFEFEBE2).withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 4. Footer Ornament
                SvgPicture.asset(
                  'assets/images/footer.svg',
                  height: 45,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8),
                    BlendMode.srcIn,
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Matchstick Box
                _buildFooter(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: const Color(0xFFEFEBE2).withOpacity(0.15),
      margin: EdgeInsets.zero,
    );
  }


  Widget _buildTeamSection(
    BuildContext context,
    String name,
    int score,
    bool isNosotros,
  ) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

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

          if ((isNosotros ? scoreProvider.nosotros : scoreProvider.ellos) == 15 && showMilestone) {
             totalPoints = 15;
          }
          if ((isNosotros ? (scoreProvider.nosotros == 30) : (scoreProvider.ellos == 30)) && showMilestone) {
             totalPoints = 15;
          }
          
          return Listener(
            onPointerDown: (event) => _lastPointerDownPos = event.position,
            child: Draggable<String>(
              data: isNosotros ? "nosotros" : "ellos",
              dragAnchorStrategy: pointerDragAnchorStrategy,
              maxSimultaneousDrags: totalPoints > 0 ? 1 : 0,
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
                child: const MatchstickWidget(height: 100),
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
          backgroundColor: const Color(0xFF1C203E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "CAMBIAR NOMBRE",
            style: TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 2,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: Color(0xFFEFEBE2),
              fontFamily: 'CaminitoBase',
              fontSize: 24,
            ),
            decoration: InputDecoration(
              hintText: "Ej: LOS CRACKS",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF718C9C)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF888D71)),
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
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Oswald',
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
              child: const Text(
                "GUARDAR",
                style: TextStyle(
                  color: Color(0xFF888D71),
                  fontFamily: 'Oswald',
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
          backgroundColor: const Color(0xFF1C203E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF718C9C), width: 1),
          ),
          title: Center(
            child: Text(
              "$winnerName GANÓ!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontSize: 32,
                color: Color(0xFFEFEBE2),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${scoreProvider.nosotros} - ${scoreProvider.ellos}",
                style: const TextStyle(
                  fontFamily: 'CaminitoBase',
                  fontSize: 48,
                  color: Color(0xFF888D71),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "¡Partida finalizada!",
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowButtonSpacing: 10,
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      scoreProvider.triggerReset();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF888D71),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "VOLVER A JUGAR",
                      style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (winnerKey == "nosotros") {
                            scoreProvider.removePointNosotros();
                          } else {
                            scoreProvider.removePointEllos();
                          }
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF47580)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          "DESHACER",
                          style: TextStyle(fontFamily: 'Oswald', color: Color(0xFFF47580)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final message = "¡Gané al Truco! $winnerName venció ${scoreProvider.nosotros} a ${scoreProvider.ellos}. #AnatadorDeTruco";
                          Share.share(message);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF718C9C)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          "COMPARTIR",
                          style: TextStyle(fontFamily: 'Oswald', color: Color(0xFF718C9C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 20,
                  color: Color(0xFF718C9C),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Stylized Score Number
          Text(
            totalPoints.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'CaminitoBase',
              fontSize: 32,
              color: Color(0xFFEFEBE2),
            ),
          ),
          
          // Status Label (Buenas/Malas)
          Text(
            scoreProvider.getLabel(teamKey),
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: 16,
              color: isBuenas ? const Color(0xFF888D71) : const Color(0xFFF47580),
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

                      bool isLastActiveGroup = (totalPoints / 5).ceil() - 1 == groupIndex;

                      return Expanded(
                        child: Center(
                          child: pointsInThisGroup > 0 
                            ? ScoreGroup(
                                key: ValueKey("group_${isNosotros ? "n" : "e"}_$groupIndex"),
                                points: pointsInThisGroup,
                                size: slotSize * 0.9,
                                team: teamKey,
                                isDragging: isDraggingBack,
                                groupIndex: isNosotros ? groupIndex : groupIndex + 3,
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

  Widget _buildFooter(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);

    return DragTarget<String>(
      onAccept: (team) {
        if (team == "nosotros") scoreProvider.removePointNosotros();
        if (team == "ellos") scoreProvider.removePointEllos();
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            if (scoreProvider.totalRemainingMatchsticks > 0)
              Draggable<int>(
                data: 1,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: Transform.rotate(
                  angle: 0.1,
                  child: Transform.translate(
                    offset: const Offset(-5, -50),
                    child: const MatchstickWidget(height: 100),
                  ),
                ),
                childWhenDragging: MatchstickBox(
                    count: scoreProvider.totalRemainingMatchsticks - 1),
                child: MatchstickBox(
                  count: scoreProvider.totalRemainingMatchsticks,
                ),
              )
            else
              MatchstickBox(count: 0),
          ],
        );
      },
    );
  }
}

class _SettingsDialogContent extends StatelessWidget {
  const _SettingsDialogContent();

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);

    bool showingCustomization = false;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: const Color(0xFF161931),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  showingCustomization ? "PERSONALIZAR" : "AJUSTES",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 24,
                    color: Color(0xFFEFEBE2),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                if (!showingCustomization) ...[
                  // --- MAIN SETTINGS ---
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      scoreProvider.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: const Color(0xFF718C9C),
                    ),
                    title: const Text(
                      "SONIDOS",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFFEFEBE2), fontSize: 18),
                    ),
                    trailing: Switch(
                      value: !scoreProvider.isMuted,
                      onChanged: (val) {
                        scoreProvider.setMuted(!val);
                        setDialogState(() {});
                      },
                      activeColor: const Color(0xFF888D71),
                    ),
                  ),
                  
                  const Divider(color: Colors.white12),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "MODO DE JUEGO",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFF718C9C), fontSize: 14, letterSpacing: 1.5),
                    ),
                  ),
                  
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      itemCount: availableModes.length,
                      itemBuilder: (context, index) {
                        final mode = availableModes[index];
                        final isSelected = scoreProvider.currentGameMode.label == mode.label;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            mode.label,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 14,
                              color: isSelected ? const Color(0xFFEFEBE2) : const Color(0xFF718C9C),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF888D71), size: 18) : null,
                          onTap: () {
                            scoreProvider.setGameMode(mode);
                            setDialogState(() {});
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  
                  const Divider(color: Colors.white12),

                  // Customization Trigger
                  ListTile(
                    onTap: () {
                      setDialogState(() {
                        showingCustomization = true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.palette_outlined, color: Color(0xFF718C9C)),
                    title: const Text(
                      "DISEÑO Y TEMAS",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFFEFEBE2), fontSize: 18),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF718C9C)),
                  ),

                  const Divider(color: Colors.white12),
                  
                  TextButton.icon(
                    onPressed: () {
                      Share.share("¡Mirá este anotador de Truco premium! Bajalo acá: [LINK]");
                    },
                    icon: const Icon(Icons.share, color: Color(0xFF718C9C)),
                    label: const Text(
                      "COMPARTIR APP",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFFEFEBE2), letterSpacing: 1),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEBE2).withOpacity(0.1),
                      foregroundColor: const Color(0xFFEFEBE2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("CERRAR"),
                  ),
                ] else ...[
                  // --- CUSTOMIZATION VIEW ---
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "COLOR DE FÓSFOROS",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFF718C9C), fontSize: 14, letterSpacing: 1.5),
                    ),
                  ),

                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: availablePalettes.length,
                      itemBuilder: (context, index) {
                        final palette = availablePalettes[index];
                        final isSelected = scoreProvider.currentPalette.name == palette.name;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: palette.headColors,
                              ),
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                          ),
                          title: Text(
                            palette.name,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              color: isSelected ? const Color(0xFFEFEBE2) : const Color(0xFF718C9C),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF888D71)) : null,
                          onTap: () {
                            scoreProvider.setPalette(palette);
                            setDialogState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        showingCustomization = false;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF718C9C)),
                    label: const Text(
                      "VOLVER",
                      style: TextStyle(fontFamily: 'Oswald', color: Color(0xFFEFEBE2), letterSpacing: 1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
