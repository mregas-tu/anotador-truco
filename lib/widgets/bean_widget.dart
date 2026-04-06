import 'package:flutter/material.dart';
import 'dart:math' as math;

class BeanPainter extends CustomPainter {
  final int seed;

  BeanPainter({this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final w = size.width;
    final h = size.height;

    final rect = Rect.fromLTWH(0, 0, w, h);

    // 1. Soft Drop Shadow
    canvas.drawOval(
      rect.shift(const Offset(1.0, 2.0)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 2. Glossy Creamy Body
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF), // Bright specular highlight
          Color(0xFFF9F6EA), // Cream white
          Color(0xFFE0D8C3), // Soft beige ambient edge
        ],
        stops: [0.1, 0.6, 1.0],
        center: Alignment(-0.3, -0.3),
        radius: 1.0,
      ).createShader(rect);

    canvas.drawOval(rect, bodyPaint);

    // 3. Crisp Top-Left Reflection (Glossiness)
    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.35, h * 0.2));

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // 4. Very faint speckles to make it organic, not plastic
    final specklePaint = Paint()..color = const Color(0xFFC7BCA3).withOpacity(0.15);
    for (int i = 0; i < 6; i++) {
      final sx = random.nextDouble() * w;
      final sy = random.nextDouble() * h;
      if (math.pow(sx - w / 2, 2) / math.pow(w / 2, 2) +
              math.pow(sy - h / 2, 2) / math.pow(h / 2, 2) <=
          0.8) {
        canvas.drawCircle(Offset(sx, sy), 0.5, specklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BeanPainter oldDelegate) => oldDelegate.seed != seed;
}

class BeanWidget extends StatelessWidget {
  final double size;
  final int seed;
  const BeanWidget({super.key, this.size = 24, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    final r = math.Random(seed);
    // Beans are somewhat elongated. Subtle variance per bean.
    final widthFactor = 1.25 + (r.nextDouble() * 0.1);

    return SizedBox(
      width: size * widthFactor,
      height: size,
      child: CustomPaint(
        painter: BeanPainter(seed: seed),
      ),
    );
  }
}
