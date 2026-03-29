import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/score_provider.dart';
import 'widgets/score_group_widget.dart';
import 'widgets/matchstick_widget.dart';
import 'widgets/matchstick_box.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Realistic Wood Image Background (Local Asset)
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 2. Cinematic Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamSection(
                        context,
                        "NOSOTROS",
                        scoreProvider.nosotros,
                        true,
                      ),
                      _buildDivider(),
                      _buildTeamSection(
                        context,
                        "ELLOS",
                        scoreProvider.ellos,
                        false,
                      ),
                    ],
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 2,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.orangeAccent.withOpacity(0.3),
            Colors.orangeAccent.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
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
          return Container(
            color: candidateData.isNotEmpty
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  isNosotros ? "NOSOTROS" : "ELLOS",
                  style: GoogleFonts.oswald(
                    fontSize: 26,
                    color: isNosotros
                        ? Colors.orangeAccent.shade100
                        : Colors.lightBlueAccent.shade100,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                // Slate / Chalkboard Score Label with Frame
                Container(
                  padding: const EdgeInsets.all(4), // Frame thickness
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E), // Frame color
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238), // Slate base
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: [
                        // Chalkboard Texture
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ChalkboardPainter(),
                          ),
                        ),
                        Text(
                          scoreProvider.getLabel(score).toUpperCase(),
                          style: GoogleFonts.coveredByYourGrace(
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double availableHeight = constraints.maxHeight;
                        double availableWidth = constraints.maxWidth;
                        double slotSize = (availableHeight / 3).clamp(60.0, availableWidth);

                        return Consumer<ScoreProvider>(
                          builder: (context, scoreProvider, child) {
                            final int points = isNosotros ? scoreProvider.nosotros : scoreProvider.ellos;
                            int totalPoints = scoreProvider.getDisplayPoints(points);

                            // Milestone transition override (to show sticks during animation)
                            final bool showMilestone = isNosotros 
                                ? scoreProvider.nosotrosShowMilestone 
                                : scoreProvider.ellosShowMilestone;

                            if ((points == 15 || points == 30) && showMilestone) {
                               totalPoints = 15;
                            }

                            return Column(
                              children: List.generate(3, (groupIndex) {
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
                                          team: isNosotros ? "nosotros" : "ellos",
                                          groupIndex: isNosotros ? groupIndex : groupIndex + 3,
                                          animateLast: isLastActiveGroup &&
                                              scoreProvider.lastPointTeam ==
                                                  (isNosotros ? "nosotros" : "ellos"),
                                          dropOffset: scoreProvider.lastDropOffset,
                                        )
                                      : const SizedBox.shrink(),
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "ARRASTRÁ UN FÓSFORO PARA AGREGAR",
            style: GoogleFonts.oswald(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => scoreProvider.triggerReset(),
                icon: const Icon(Icons.refresh, color: Colors.white54),
                tooltip: "Reiniciar",
              ),
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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings, color: Colors.white54),
                tooltip: "Ajustes",
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class ChalkboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    final paint = Paint()..color = Colors.white.withOpacity(0.05);

    // Draw chalk dust / streaks
    for (int i = 0; i < 15; i++) {
      final path = Path();
      double x = random.nextDouble() * size.width;
      path.moveTo(x, 0);
      path.quadraticBezierTo(
        x + (random.nextDouble() - 0.5) * 20, 
        size.height / 2, 
        x + (random.nextDouble() - 0.5) * 10, 
        size.height
      );
      
      canvas.drawPath(
        path, 
        Paint()
          ..color = Colors.white.withOpacity(0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + random.nextDouble() * 5.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      );
    }

    // Tiny chalk specks
    for (int i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
