import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'matchstick_widget.dart';
import '../providers/score_provider.dart';

class MatchstickBox extends StatelessWidget {
  final int count;

  const MatchstickBox({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, child) {
        final theme = scoreProvider.appTheme;
        return Container(
          width: 200,
          height: 120,
          padding: const EdgeInsets.all(4), // Space for the rim
          decoration: BoxDecoration(
            color: theme.navyLight, // Dark Navy rim
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(4, 4),
                blurRadius: 15,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.navy, // Deep interior matching background
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.white.withOpacity(0.24), width: 0.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.navy, // Deep base
                  theme.navyLight,
                  theme.navyAccent, // Subtle accent depth
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle inner shadow overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(math.max(0, count), (index) {
                    // Use a seeded random so the sticks don't jump every rebuild
                    final random = math.Random(index * 1337);
                    final angle = (random.nextDouble() - 0.5) * 1.5; // Random rotation
                    final offsetX = (random.nextDouble() - 0.5) * 90;
                    final offsetY = (random.nextDouble() - 0.5) * 45;

                    return Transform.translate(
                      offset: Offset(offsetX, offsetY),
                      child: Transform.rotate(
                        angle: angle,
                        child: MatchstickWidget(height: 70),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
