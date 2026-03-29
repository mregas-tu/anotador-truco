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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3E2723), // Dark wood
              Color(0xFF5D4037), // Lighter wood
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    _buildTeamSection(
                      context,
                      "NOSOTROS",
                      scoreProvider.nosotros,
                      true,
                    ),
                    const VerticalDivider(color: Colors.white24, thickness: 1),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        "TRUCO PRO",
        style: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 4,
        ),
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
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  isNosotros ? "NOSOTROS" : "ELLOS",
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    color: isNosotros
                        ? Colors.orangeAccent
                        : Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    scoreProvider.getLabel(score).toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            (scoreProvider.getDisplayPoints(score) / 5).ceil(),
                            (index) {
                          int pointsInThisGroup =
                              (scoreProvider.getDisplayPoints(score) -
                                      (index * 5))
                                  .clamp(
                            1,
                            5,
                          );
                          bool isLastGroup = index ==
                              (scoreProvider.getDisplayPoints(score) / 5)
                                      .ceil() -
                                  1;

                          return ScoreGroup(
                            key: ValueKey("group_${isNosotros ? "n" : "e"}_$index"),
                            points: pointsInThisGroup,
                            animateLast: isLastGroup &&
                                scoreProvider.lastPointTeam ==
                                    (isNosotros ? "nosotros" : "ellos"),
                            dropOffset: scoreProvider.lastDropOffset,
                          );
                        }),
                      ),
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
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text(
            "ARRASTRÁ UN FÓSFORO PARA AGREGAR",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => scoreProvider.triggerReset(),
                icon: const Icon(Icons.refresh, color: Colors.white60),
                tooltip: "Reiniciar",
              ),
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
                childWhenDragging:
                    MatchstickBox(count: scoreProvider.totalRemainingMatchsticks - 1),
                child: MatchstickBox(
                    count: scoreProvider.totalRemainingMatchsticks),
              ),
              IconButton(
                onPressed: () {
                  // Toggle max score 15/30 logic could go here
                },
                icon: const Icon(Icons.settings, color: Colors.white60),
                tooltip: "Ajustes",
              ),
            ],
          ),
        ],
      ),
    );
  }

}
