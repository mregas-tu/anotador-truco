import 'package:flutter/material.dart';

class MatchstickPainter extends CustomPainter {
  final bool horizontal;
  final bool diagonal;

  MatchstickPainter({this.horizontal = false, this.diagonal = false});

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
    final rect = Rect.fromLTWH(size.width / 2 - 2, 0, 4, size.height);
    
    // Wood body with gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);

    final headRect = Rect.fromLTWH(size.width / 2 - 3.5, -2, 7, 10);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        center: Alignment(-0.3, -0.3),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(1.5, 1.5)), const Radius.circular(1)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), bodyPaint);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
  }

  void _drawHorizontal(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, size.height / 2 - 2, size.width, 4);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
      ).createShader(rect);

    final headRect = Rect.fromLTWH(size.width - 8, size.height / 2 - 3.5, 10, 7);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        center: Alignment(-0.3, -0.3),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(1.5, 1.5)), const Radius.circular(1)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), bodyPaint);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadowPaint);
    canvas.drawOval(headRect, headPaint);
  }

  void _drawDiagonal(Canvas canvas, Size size) {
    final side = size.width > size.height ? size.width : size.height;
    final diagonalLength = 1.3 * side; 

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.785); // 45 degrees
    
    final rect = Rect.fromLTWH(-diagonalLength / 2, -2, diagonalLength, 4);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6D2B5), Color(0xFFD2B48C), Color(0xFFB89B74)],
      ).createShader(rect);

    final headRect = Rect.fromLTWH(diagonalLength / 2 - 8, -3.5, 11, 7);
    final headPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        center: Alignment(-0.3, -0.3),
      ).createShader(headRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(1.5, 1.5)), const Radius.circular(1)), shadowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), bodyPaint);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadowPaint);
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

  const MatchstickWidget({
    super.key,
    this.width = 10,
    this.height = 60,
    this.horizontal = false,
    this.diagonal = false,
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
        painter: MatchstickPainter(horizontal: horizontal, diagonal: diagonal),
      ),
    );
  }
}
