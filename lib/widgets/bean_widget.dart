import 'package:flutter/material.dart';

class BeanPainter extends CustomPainter {
  final Color baseColor;

  BeanPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // 1. Shadow (Soft and slightly offset)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(1.5, 1.5), width: width, height: height * 0.9),
      shadowPaint,
    );

    // 2. Bean Body (Oval)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.08)!,
          Color.lerp(baseColor, Colors.black, 0.15)!,
        ],
        stops: const [0.0, 0.7, 1.0],
        center: const Alignment(-0.2, -0.3),
        radius: 0.8,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawOval(Rect.fromLTWH(0, 0, width, height), bodyPaint);

    // 3. Highlight (Top shine)
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(width * 0.2, height * 0.15, width * 0.4, height * 0.4));
    
    canvas.drawOval(Rect.fromLTWH(width * 0.2, height * 0.15, width * 0.4, height * 0.25), shinePaint);

    // 4. Hilum (The bean's "belly button")
    final hilumPaint = Paint()
      ..color = Color.lerp(baseColor, Colors.black, 0.3)!.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
    // Draw a small subtle curve or dot on the side
    final hilumPath = Path();
    hilumPath.addOval(Rect.fromCenter(
      center: Offset(width * 0.45, height * 0.5),
      width: width * 0.1,
      height: height * 0.18,
    ));
    canvas.drawPath(hilumPath, hilumPaint);
    
    // Add a tiny lighter dot inside hilum for more realism
    final hilumLightPaint = Paint()..color = baseColor.withOpacity(0.3);
    canvas.drawCircle(Offset(width * 0.45, height * 0.5), width * 0.03, hilumLightPaint);
  }

  @override
  bool shouldRepaint(covariant BeanPainter oldDelegate) => oldDelegate.baseColor != baseColor;
}

class BeanWidget extends StatelessWidget {
  final double size;
  const BeanWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    // Ivory / Cream color typical of beans
    const beanColor = Color(0xFFF5F5DC);
    
    return SizedBox(
      width: size * 1.2, // Beans are usually longer than wide
      height: size,
      child: CustomPaint(
        painter: BeanPainter(baseColor: beanColor),
      ),
    );
  }
}
