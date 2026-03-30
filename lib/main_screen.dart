import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: const Color(0xFF161931),
      body: Stack(
        children: [
          // 1. Header Ornament
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/header.svg',
              height: 45,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.8),
                BlendMode.srcIn,
              ),
            ),
          ),
          
          // 2. Settings Icon
          Positioned(
            top: 45,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
              onPressed: () {},
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Row(
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
                      
                      // Footer Ornament (Integrated into Stack for larger DragTarget area)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SvgPicture.asset(
                            'assets/images/footer.svg',
                            height: 45,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.8),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                _buildFooter(context),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 60),
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
          final bool isBuenas = scoreProvider.isBuenas(score);
          
          return Container(
            color: candidateData.isNotEmpty
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 20,
                    color: Color(0xFF718C9C),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Stylized Score Number
                Text(
                  scoreProvider.getDisplayPoints(score).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'CaminitoBase',
                    fontSize: 32,
                    color: Color(0xFFEFEBE2),
                  ),
                ),
                
                // Status Label (Buenas/Malas)
                Text(
                  scoreProvider.getLabel(score),
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 16,
                    color: isBuenas ? const Color(0xFF888D71) : const Color(0xFFF47580),
                    letterSpacing: 1.2,
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

                            // Milestone transition override
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
                const SizedBox(height: 30), // Padding for the footer ornament
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

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
        
        const SizedBox(height: 30),
        
        // REINICIAR Button
        InkWell(
          onTap: () => scoreProvider.triggerReset(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.refresh, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                "REINICIAR",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontFamily: 'Oswald',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
