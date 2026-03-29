import 'package:flutter/material.dart';

class MatchstickPainter extends CustomPainter {
  final bool horizontal;
  final bool diagonal;
  final bool flipped;

  MatchstickPainter({
    this.horizontal = false,
    this.diagonal = false,
    this.flipped = false,
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
    // Increased thickness
    final rect = Rect.fromLTWH(size.width / 2 - 3.5, 0, 7, size.height);
    
    // Wood body with gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);

    // Elongated and larger head
    // Flipped: if true, head is at bottom, else at top
    final double headY = flipped ? size.height - 12 : -4;
    final headRect = Rect.fromLTWH(size.width / 2 - 4.5, headY, 9, 15);
    
    // Specular highlight in the head
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F), const Color(0xFF8B0000)],
        stops: const [0.0, 0.4, 1.0],
        center: flipped ? const Alignment(-0.4, 0.4) : const Alignment(-0.4, -0.4),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(1.5)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), bodyPaint);
    
    // Draw subtle grain lines on the stick (wider)
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 2 - 1, 8), Offset(size.width / 2 - 1, size.height - 8), grainPaint);
    
    canvas.drawOval(headRect.shift(const Offset(1.5, 1.5)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
  }

  void _drawHorizontal(Canvas canvas, Size size) {
    // Increased thickness
    final rect = Rect.fromLTWH(0, size.height / 2 - 3.5, size.width, 7);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
      ).createShader(rect);

    // Elongated and larger head
    // Flipped: if true, head is at left, else at right
    final double headX = flipped ? -4 : size.width - 12;
    final headRect = Rect.fromLTWH(headX, size.height / 2 - 5, 16, 9);
    
    // Specular highlight in the head
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F), const Color(0xFF8B0000)],
        stops: const [0.0, 0.4, 1.0],
        center: flipped ? const Alignment(0.4, -0.4) : const Alignment(-0.4, -0.4),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(1.5)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), bodyPaint);
    
    // Grain (wider)
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
    final diagonalLength = 1.35 * side; // Slightly longer coverage

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.785); // 45 degrees
    
    // Increased thickness from 4 to 7
    final rect = Rect.fromLTWH(-diagonalLength / 2, -3.5, diagonalLength, 7);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
      ).createShader(rect);

    // Elongated and larger head
    // Flipped: if true, head is at top-left, else at bottom-right
    final double headX = flipped ? -diagonalLength / 2 - 4 : diagonalLength / 2 - 12;
    final headRect = Rect.fromLTWH(headX, -4.5, 15, 9);
    
    // Specular highlight in the head
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF5252), const Color(0xFFD32F2F), const Color(0xFF8B0000)],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: CustomPaint(
        painter: MatchstickPainter(
          horizontal: horizontal,
          diagonal: diagonal,
          flipped: flipped,
        ),
      ),
    );
  }
}
