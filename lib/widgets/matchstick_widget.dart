import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/score_provider.dart';
import '../theme/app_theme.dart';

class MatchstickPainter extends CustomPainter {
  final bool horizontal;
  final bool diagonal;
  final bool flipped;
  final List<Color> headColors;
  final Color woodLight;
  final Color woodMedium;
  final Color woodDark;

  MatchstickPainter({
    this.horizontal = false,
    this.diagonal = false,
    this.flipped = false,
    required this.headColors,
    required this.woodLight,
    required this.woodMedium,
    required this.woodDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (diagonal) {
      _drawDiagonal(canvas, size);
    } else if (horizontal) {
      _drawHorizontal(canvas, size);
    } else {
      _drawVertical(canvas, size);
    }
  }

  void _drawVertical(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(size.width / 2 - 3.5, 0, 7, size.height);
    
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [woodLight, woodMedium, woodDark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    final double headY = flipped ? size.height - 12 : -4;
    final headRect = Rect.fromLTWH(size.width / 2 - 4.5, headY, 9, 15);
    
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: headColors,
        stops: const [0.0, 0.4, 1.0],
        center: flipped ? const Alignment(-0.4, 0.4) : const Alignment(-0.4, -0.4),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(1.5)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), bodyPaint);
    
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 2 - 1, 8), Offset(size.width / 2 - 1, size.height - 8), grainPaint);
    
    canvas.drawOval(headRect.shift(const Offset(1.5, 1.5)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
  }

  void _drawHorizontal(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, size.height / 2 - 3.5, size.width, 7);

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodLight, woodMedium, woodDark],
      ).createShader(rect);

    final double headX = flipped ? -4 : size.width - 12;
    final headRect = Rect.fromLTWH(headX, size.height / 2 - 5, 16, 9);
    
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: headColors,
        stops: const [0.0, 0.4, 1.0],
        center: flipped ? const Alignment(0.4, -0.4) : const Alignment(-0.4, -0.4),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(1.5)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), bodyPaint);
    
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(8, size.height / 2 - 1), Offset(size.width - 12, size.height / 2 - 1), grainPaint);

    canvas.drawOval(headRect.shift(const Offset(1.5, 1.5)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
  }

  void _drawDiagonal(Canvas canvas, Size size) {
    final side = size.width > size.height ? size.width : size.height;
    final diagonalLength = 1.35 * side;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.785); // 45 degrees
    
    final rect = Rect.fromLTWH(-diagonalLength / 2, -3.5, diagonalLength, 7);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodLight, woodMedium, woodDark],
      ).createShader(rect);

    final double headX = flipped ? -diagonalLength / 2 - 4 : diagonalLength / 2 - 12;
    final headRect = Rect.fromLTWH(headX, -4.5, 15, 9);
    
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: headColors,
        stops: const [0.0, 0.4, 1.0],
        center: flipped ? const Alignment(0.4, -0.4) : const Alignment(-0.4, -0.4),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(1.5)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), bodyPaint);
    
    canvas.drawOval(headRect.shift(const Offset(1.5, 1.5)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MatchstickPainter oldDelegate) {
    return !listEquals(oldDelegate.headColors, headColors) ||
        oldDelegate.woodLight != woodLight ||
        oldDelegate.woodMedium != woodMedium ||
        oldDelegate.woodDark != woodDark ||
        oldDelegate.horizontal != horizontal ||
        oldDelegate.diagonal != diagonal ||
        oldDelegate.flipped != flipped;
  }
}

class MatchstickWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool horizontal;
  final bool diagonal;
  final bool flipped;

  const MatchstickWidget({
    super.key,
    this.width = 10,
    this.height = 60,
    this.horizontal = false,
    this.diagonal = false,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    double boxWidth = width;
    double boxHeight = height;

    if (diagonal) {
      boxWidth = height;
      boxHeight = height;
    } else if (horizontal) {
      boxWidth = height;
      boxHeight = width;
    }

    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, child) {
        return SizedBox(
          width: boxWidth,
          height: boxHeight,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: MatchstickPainter(
                horizontal: horizontal,
                diagonal: diagonal,
                flipped: flipped,
                headColors: scoreProvider.currentPalette.headColors,
                woodLight: TrucoTheme.woodLight,
                woodMedium: TrucoTheme.woodMedium,
                woodDark: TrucoTheme.woodDark,
              ),
            ),
          ),
        );
      },
    );
  }
}
