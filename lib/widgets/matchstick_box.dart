import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'matchstick_widget.dart';

class MatchstickBox extends StatelessWidget {
  final int count;

  const MatchstickBox({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037), // Darker wood/cardboard
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade800, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (index) {
          // Use a seeded random so the sticks don't jump every rebuild
          final random = math.Random(index * 1337);
          final angle = (random.nextDouble() - 0.5) * 1.5; // Random rotation
          final offsetX = (random.nextDouble() - 0.5) * 80;
          final offsetY = (random.nextDouble() - 0.5) * 40;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: angle,
              child: const MatchstickWidget(height: 70),
            ),
          );
        }),
      ),
    );
  }
}
