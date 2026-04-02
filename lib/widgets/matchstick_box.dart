import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'matchstick_widget.dart';
import '../providers/score_provider.dart';
import '../theme/app_theme.dart';

class MatchstickBox extends StatelessWidget {
  final int count;

  const MatchstickBox({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, child) {
        final theme = scoreProvider.appTheme;
        
        switch (theme.matchstickBoxType) {
          case MatchstickBoxType.soccer:
            return _MatchstickBoxSoccer(count: count, theme: theme);
          case MatchstickBoxType.classic:
            return _MatchstickBoxClassic(count: count, theme: theme);
          case MatchstickBoxType.wood:
            return _MatchstickBoxWood(count: count, theme: theme);
        }
      },
    );
  }
}

class _MatchstickBoxClassic extends StatelessWidget {
  final int count;
  final TrucoTheme theme;

  const _MatchstickBoxClassic({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 120,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.navyLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.navy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.white.withOpacity(0.24), width: 0.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.navy,
              theme.navyLight,
              theme.navyAccent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: _MatchstickContainer(count: count, showHexNet: false),
      ),
    );
  }
}

class _MatchstickBoxSoccer extends StatelessWidget {
  final int count;
  final TrucoTheme theme;

  const _MatchstickBoxSoccer({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateX(-0.1), // Fixed tilt for soccer
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Background (Grass + Net)
          _MatchstickContainer(count: count, showHexNet: true),

          // The Frame (Overlaying the net)
          IgnorePointer(
            child: Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchstickContainer extends StatelessWidget {
  final int count;
  final bool showHexNet;

  const _MatchstickContainer({required this.count, required this.showHexNet});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ScoreProvider>(context, listen: false).appTheme;
    final isWood = theme.matchstickBoxType == MatchstickBoxType.wood;
    
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: (showHexNet || isWood) ? Colors.transparent : theme.navy,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showHexNet)
              Positioned.fill(
                child: CustomPaint(
                  painter: _HexNetPainter(color: Colors.white.withOpacity(0.15)),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: showHexNet 
                    ? null 
                    : RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                ),
              ),
            ),
            ...List.generate(math.max(0, count), (index) {
              final random = math.Random(index * 1337);
              final isWood = theme.matchstickBoxType == MatchstickBoxType.wood;
              
              // If wood, make them horizontal with small deviation from 0 degrees
              final angle = isWood 
                  ? (random.nextDouble() - 0.5) * 0.4
                  : (random.nextDouble() - 0.5) * 1.5;

              final offsetX = (random.nextDouble() - 0.5) * (isWood ? 20 : 90);
              final offsetY = (random.nextDouble() - 0.5) * 75; // Más dispersión vertical

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.rotate(
                  angle: angle,
                  child: MatchstickWidget(
                    height: isWood ? 100 : 70, // Fósforos más largos
                    width: isWood ? 6 : 10,
                    horizontal: isWood,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HexNetPainter extends CustomPainter {
  final Color color;
  _HexNetPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double radius = 8.0;
    final double hexWidth = math.sqrt(3) * radius;
    final double hexHeight = 2 * radius;

    for (double y = -radius; y < size.height + radius; y += hexHeight * 0.75) {
      bool isOdd = (y / (hexHeight * 0.75)).round() % 2 != 0;
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth) {
        final cx = isOdd ? x + hexWidth / 2 : x;
        final cy = y;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          double angle = (math.pi / 180) * (60 * i - 30);
          double xPos = cx + radius * math.cos(angle);
          double yPos = cy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(xPos, yPos);
          } else {
            path.lineTo(xPos, yPos);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MatchstickBoxWood extends StatelessWidget {
  final int count;
  final TrucoTheme theme;

  const _MatchstickBoxWood({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 140,
      child: Stack(
        children: [
          // La caja SVG completa al fondo
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/matchbox_wood.svg',
              fit: BoxFit.contain,
            ),
          ),

          // Fósforos AL FRENTE con márgenes corregidos (155 para limpiar la tapa)
          Positioned(
            left: 155, // Zona segura para no pisar el cartón
            right: 12, // Llegan hasta la madera de la derecha
            top: 15,   // Repartidos en todo el alto
            bottom: 15,
            child: ClipRect(
              child: _MatchstickContainer(count: count, showHexNet: false),
            ),
          ),
        ],
      ),
    );
  }
}
