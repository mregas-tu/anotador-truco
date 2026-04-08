import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PicaPicaLine extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final double fontSize;
  final EdgeInsets padding;

  const PicaPicaLine({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dashed Line
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: DashedLinePainter(color: color),
        ),
        // Label
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor, // Background sólido
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 5;

    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
