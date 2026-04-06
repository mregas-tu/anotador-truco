import 'package:flutter/material.dart';
import 'dart:math' as math;

class BeanPainter extends CustomPainter {
  final Color baseColor;
  final int seed;

  BeanPainter({required this.baseColor, this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final w = size.width;
    final h = size.height;

    final darkColor = Color.lerp(baseColor, Colors.black, 0.12)!;
    final highlightColor = Colors.white.withOpacity(0.25);

    // 1. Simple smooth rect for the bean
    final rect = Rect.fromLTWH(0, 0, w, h);

    // 2. Soft Drop Shadow
    canvas.drawOval(
      rect.shift(const Offset(1.2, 2.0)),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 3. Body: Round Oval with asymmetric gradient to simulate bean volume
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [baseColor, darkColor],
        stops: const [0.6, 1.0],
        center: const Alignment(-0.25, -0.25),
        radius: 1.1,
      ).createShader(rect);

    canvas.drawOval(rect, bodyPaint);

    // 4. Subtle Texture (Speckles)
    final specklePaint = Paint()..color = darkColor.withOpacity(0.1);
    for (int i = 0; i < 12; i++) {
        final sx = random.nextDouble() * w;
        final sy = random.nextDouble() * h;
        // Keep speckles within oval
        if (math.pow(sx - w/2, 2) / math.pow(w/2, 2) + math.pow(sy - h/2, 2) / math.pow(h/2, 2) <= 0.7) {
          canvas.drawCircle(Offset(sx, sy), 0.4, specklePaint);
        }
    }

    // 5. Hilum (Belly button) - Very subtle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.4, h * 0.52), width: w * 0.05, height: h * 0.12),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    // 6. Soft Upper Highlight
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.4, h * 0.25),
      Paint()..color = highlightColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
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
    // Soft Off-white / Ivory
    const beanColor = Color(0xFFF9F7F2); 
    
    final r = math.Random(seed);
    // Natural aspect ratio (beans are longer)
    final widthFactor = 1.25 + (r.nextDouble() * 0.15); 
    
    return SizedBox(
      width: size * widthFactor, 
      height: size,
      child: CustomPaint(
        painter: BeanPainter(baseColor: beanColor, seed: seed),
      ),
    );
  }
}
