import 'package:flutter/material.dart';

class MatchstickPainter extends CustomPainter {
  final bool horizontal;
  final bool diagonal;

  MatchstickPainter({this.horizontal = false, this.diagonal = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBody = Paint()
      ..color = const Color(0xFFD2B48C) // Wood/Matchstick body color
      ..style = PaintingStyle.fill;

    final paintHead = Paint()
      ..color = const Color(0xFFB22222) // Firebrick red for the head
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    if (diagonal) {
      _drawDiagonal(canvas, size, paintBody, paintHead, shadowPaint);
    } else if (horizontal) {
      _drawHorizontal(canvas, size, paintBody, paintHead, shadowPaint);
    } else {
      _drawVertical(canvas, size, paintBody, paintHead, shadowPaint);
    }
  }

  void _drawVertical(Canvas canvas, Size size, Paint body, Paint head, Paint shadow) {
    final rect = Rect.fromLTWH(size.width / 2 - 2, 0, 4, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(2)), shadow);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), body);

    final headRect = Rect.fromLTWH(size.width / 2 - 3, 0, 6, 8);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadow);
    canvas.drawOval(headRect, head);
  }

  void _drawHorizontal(Canvas canvas, Size size, Paint body, Paint head, Paint shadow) {
    final rect = Rect.fromLTWH(0, size.height / 2 - 2, size.width, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(2)), shadow);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), body);

    final headRect = Rect.fromLTWH(size.width - 8, size.height / 2 - 3, 8, 6);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadow);
    canvas.drawOval(headRect, head);
  }

  void _drawDiagonal(Canvas canvas, Size size, Paint body, Paint head, Paint shadow) {
    // For diagonals, we assume the painter is in a square Box of 'side x side'
    final side = size.width > size.height ? size.width : size.height;
    final diagonalLength = 1.3 * side; 

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.785); // 45 degrees
    
    final rect = Rect.fromLTWH(-diagonalLength / 2, -2, diagonalLength, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(2)), shadow);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), body);

    final headRect = Rect.fromLTWH(diagonalLength / 2 - 8, -3, 8, 6);
    canvas.drawOval(headRect.shift(const Offset(1, 1)), shadow);
    canvas.drawOval(headRect, head);
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
