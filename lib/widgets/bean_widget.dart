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

    // 1. Mathematically perfect Kidney Path
    final path = Path();
    path.moveTo(w * 0.05, h * 0.5);
    // Left lobe -> Top Dent
    path.cubicTo(w * 0.05, h * 0.1, w * 0.3, h * 0.3, w * 0.5, h * 0.35);
    // Top Dent -> Right lobe
    path.cubicTo(w * 0.7, h * 0.3, w * 0.95, h * 0.1, w * 0.95, h * 0.5);
    // Right lobe -> Bottom 
    path.cubicTo(w * 0.95, h * 0.9, w * 0.7, h * 0.95, w * 0.5, h * 0.95);
    // Bottom -> Left lobe
    path.cubicTo(w * 0.3, h * 0.95, w * 0.05, h * 0.9, w * 0.05, h * 0.5);
    path.close();

    // 2. Drop Shadow
    canvas.drawPath(
      path.shift(const Offset(1.0, 2.5)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 3. Main Body Volume (Rich Cream)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF), // Core light
          Color(0xFFF7F4E9), // Cream base
          Color(0xFFD3C8B3), // Dark edge
        ],
        stops: [0.2, 0.7, 1.0],
        center: Alignment(0.0, -0.3),
        radius: 1.1,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, bodyPaint);

    // Everything drawn from here on is clipped EXACTLY to the bean's shape
    canvas.save();
    canvas.clipPath(path);

    // 4. Subtle Eye (Hilum) - nestled safely in the center dent
    final eyeCenter = Offset(w * 0.5, h * 0.34);
    canvas.drawOval(
      Rect.fromCenter(center: eyeCenter, width: w * 0.22, height: h * 0.08),
      Paint()
        ..color = const Color(0xFFC2B69F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: eyeCenter, width: w * 0.12, height: h * 0.03),
      Paint()..color = const Color(0xFF7A6D55),
    );

    // 5. Crisp Glass-like Reflection (Guaranteed not to float)
    // We draw a bright semi-transparent ellipse at the top, which gets clipped to the lobes.
    final reflectionPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0x22FFFFFF), Colors.transparent],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5));

    // A wide oval that covers the top lobes
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.15), width: w * 0.85, height: h * 0.4),
      reflectionPaint,
    );

    // 6. Micro Textures (Organic feel)
    final specklePaint = Paint()..color = const Color(0xFFBCAE94).withOpacity(0.18);
    for (int i = 0; i < 7; i++) {
      final sx = random.nextDouble() * w;
      final sy = random.nextDouble() * h;
      canvas.drawCircle(Offset(sx, sy), 0.6, specklePaint);
    }

    canvas.restore();
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
    // Beans are somewhat elongated. Slightly increased the base width to 1.45 to match real navy beans.
    final widthFactor = 1.45 + (r.nextDouble() * 0.15);

    return SizedBox(
      width: size * widthFactor,
      height: size,
      child: CustomPaint(
        painter: BeanPainter(seed: seed),
      ),
    );
  }
}
