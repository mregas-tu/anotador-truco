import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../providers/score_provider.dart';

class BeanPainter extends CustomPainter {
  final int seed;
  final BeanType beanType;

  BeanPainter({this.seed = 0, required this.beanType});

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

    // 3. Define Colors Based on BeanType
    List<Color> gradientColors;
    Color eyeBase;
    Color eyeInner;

    switch (beanType) {
      case BeanType.alubia:
        gradientColors = [const Color(0xFFFFFFFF), const Color(0xFFF7F4E9), const Color(0xFFD3C8B3)];
        eyeBase = const Color(0xFFC2B69F);
        eyeInner = const Color(0xFF7A6D55);
        break;
      case BeanType.negro:
        gradientColors = [const Color(0xFF6E6E6E), const Color(0xFF2E2E2E), const Color(0xFF0D0D0D)];
        eyeBase = const Color(0xFFF0F0F0);
        eyeInner = const Color(0xFFD3D3D3);
        break;
      case BeanType.fideo:
        gradientColors = [const Color(0xFFB52B2B), const Color(0xFF8B0000), const Color(0xFF4A0000)];
        eyeBase = const Color(0xFFE8E8E8);
        eyeInner = const Color(0xFFC0C0C0);
        break;
      case BeanType.pinto:
        gradientColors = [const Color(0xFFE3CBA8), const Color(0xFFD2B48C), const Color(0xFFA67B5B)];
        eyeBase = const Color(0xFFA67B5B);
        eyeInner = const Color(0xFF5C4033);
        break;
      case BeanType.manteca:
        gradientColors = [const Color(0xFFF5F5DC), const Color(0xFFEBEBD3), const Color(0xFFD4C8A0)];
        eyeBase = const Color(0xFFD4C8A0);
        eyeInner = const Color(0xFFAFA37E);
        break;
      case BeanType.bandera:
        gradientColors = [const Color(0xFF8B3A62), const Color(0xFF5A1A40), const Color(0xFF330A24)];
        eyeBase = const Color(0xFFE8E8E8);
        eyeInner = const Color(0xFFC0C0C0);
        break;
      case BeanType.cisne:
        gradientColors = [const Color(0xFFFFFFFF), const Color(0xFFF7F4E9), const Color(0xFFD3C8B3)];
        eyeBase = const Color(0xFF0D0D0D); // Eye is inside the black patch
        eyeInner = const Color(0xFF000000);
        break;
      case BeanType.borlotto:
        gradientColors = [const Color(0xFFE6D2B5), const Color(0xFFCBA37E), const Color(0xFFA3674B)];
        eyeBase = const Color(0xFFA3674B);
        eyeInner = const Color(0xFF7F2B2B);
        break;
      case BeanType.magnum:
        gradientColors = [const Color(0xFF767B48), const Color(0xFF4B5121), const Color(0xFF282C0E)];
        eyeBase = const Color(0xFF8C935A);
        eyeInner = const Color(0xFF373E12);
        break;
      case BeanType.frutilla:
        gradientColors = [const Color(0xFFC44D4D), const Color(0xFF9E2A2B), const Color(0xFF6A1111)];
        eyeBase = const Color(0xFFE8E8E8);
        eyeInner = const Color(0xFFC0C0C0);
        break;
    }

    // Main Body Volume
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: gradientColors,
        stops: const [0.2, 0.7, 1.0],
        center: const Alignment(0.0, -0.3),
        radius: 1.1,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, bodyPaint);

    // Everything drawn from here on is clipped EXACTLY to the bean's shape
    canvas.save();
    canvas.clipPath(path);

    // 3.5 Optional Textures
    if (beanType == BeanType.pinto || beanType == BeanType.borlotto || beanType == BeanType.frutilla) {
      final int numSpeckles = (beanType == BeanType.borlotto) 
          ? 10 + random.nextInt(10) // fewer, larger for borlotto
          : 15 + random.nextInt(15);
          
      Color speckleColor;
      if (beanType == BeanType.pinto) speckleColor = const Color(0xFF7B3F00).withValues(alpha: 0.85);
      else if (beanType == BeanType.borlotto) speckleColor = const Color(0xFF6B1D1D).withValues(alpha: 0.85);
      else speckleColor = const Color(0xFFF5F5DC).withValues(alpha: 0.85); // Cream specks for frutilla
      
      final specklePaint = Paint()..color = speckleColor;
      
      for (int i = 0; i < numSpeckles; i++) {
        final sx = w * random.nextDouble();
        final sy = h * random.nextDouble();
        final sw = w * (beanType == BeanType.borlotto ? 0.08 + random.nextDouble() * 0.2 : 0.05 + random.nextDouble() * 0.15); 
        final sh = h * (beanType == BeanType.borlotto ? 0.05 + random.nextDouble() * 0.15 : 0.03 + random.nextDouble() * 0.08); 
        
        canvas.save();
        canvas.translate(sx, sy);
        canvas.rotate(random.nextDouble() * math.pi);
        
        final specklePath = Path();
        specklePath.addOval(Rect.fromCenter(center: Offset.zero, width: sw, height: sh));
        canvas.drawPath(specklePath, specklePaint);
        
        canvas.restore();
      }
    } else if (beanType == BeanType.bandera) {
      // Large white/cream blotches
      final int numBlotches = 2 + random.nextInt(3);
      final blotchPaint = Paint()
        ..color = const Color(0xFFF7F4E9).withValues(alpha: 0.95);
      
      for (int i = 0; i < numBlotches; i++) {
        final sx = w * (0.2 + random.nextDouble() * 0.6);
        final sy = h * (0.2 + random.nextDouble() * 0.6);
        final sw = w * (0.3 + random.nextDouble() * 0.3);
        final sh = h * (0.3 + random.nextDouble() * 0.3);
        
        canvas.save();
        canvas.translate(sx, sy);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: sw, height: sh), blotchPaint);
        canvas.restore();
      }
    } else if (beanType == BeanType.cisne) {
      // Large black patch around the eye
      final blotchPaint = Paint()..color = const Color(0xFF1E1E1E);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.45, h * 0.35), width: w * 0.6, height: h * 0.45),
        blotchPaint,
      );
    }

    // 4. Subtle Eye (Hilum)
    final eyeCenter = Offset(w * 0.5, h * 0.34);
    canvas.drawOval(
      Rect.fromCenter(center: eyeCenter, width: w * 0.22, height: h * 0.08),
      Paint()
        ..color = eyeBase
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: eyeCenter, width: w * 0.12, height: h * 0.03),
      Paint()..color = eyeInner,
    );

    // 5. Crisp Glass-like Reflection (Guaranteed not to float)
    final reflectionPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0x22FFFFFF), Colors.transparent],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.15), width: w * 0.85, height: h * 0.4),
      reflectionPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BeanPainter oldDelegate) => 
      oldDelegate.seed != seed || oldDelegate.beanType != beanType;
}

class BeanWidget extends StatelessWidget {
  final double size;
  final int seed;
  final BeanType beanType;

  const BeanWidget({
    super.key, 
    this.size = 24, 
    this.seed = 0, 
    this.beanType = BeanType.alubia,
  });

  @override
  Widget build(BuildContext context) {
    final r = math.Random(seed);
    // Beans are somewhat elongated.
    final widthFactor = 1.45 + (r.nextDouble() * 0.15);

    return SizedBox(
      width: size * widthFactor,
      height: size,
      child: CustomPaint(
        painter: BeanPainter(seed: seed, beanType: beanType),
      ),
    );
  }
}
