import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'matchstick_widget.dart';
import 'bean_widget.dart';
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
            if (scoreProvider.pointType == PointType.beans) {
              return _MatchstickBoxPlate(count: count, theme: theme);
            }
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

class _MatchstickContainerWood extends StatelessWidget {
  final int count;

  const _MatchstickContainerWood({required this.count});

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(math.max(0, count), (index) {
          final random = math.Random(index * 1337);
          final angle = (random.nextDouble() - 0.5) * 0.4;
          // Fósforos largos (180px) con cola oculta a la izquierda
          final offsetX = -5 + (random.nextDouble() - 0.5) * 15;
          final offsetY = (random.nextDouble() - 0.5) * 75;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: angle,
                child: scoreProvider.pointType == PointType.beans
                  ? const BeanWidget(size: 20)
                  : const MatchstickWidget(
                      height: 180,
                      width: 6,
                      horizontal: true,
                    ),
            ),
          );
        }),
      ],
    );
  }
}

class _MatchstickContainer extends StatelessWidget {
  final int count;
  final bool showHexNet;

  const _MatchstickContainer({required this.count, required this.showHexNet});

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final theme = scoreProvider.appTheme;
    
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: showHexNet ? Colors.transparent : theme.navy,
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
            if (!showHexNet)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
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
              final random = math.Random(index * 42); 
              final angle = (random.nextDouble() - 0.5) * 1.5;
              final offsetX = (random.nextDouble() - 0.5) * 90;
              final offsetY = (random.nextDouble() - 0.5) * 45;

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.rotate(
                  angle: angle,
                  child: scoreProvider.pointType == PointType.beans
                      ? BeanWidget(size: showHexNet ? 16 : 22)
                      : const MatchstickWidget(
                          height: 70,
                          width: 10,
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

          // Fósforos AL FRENTE con máscara y margen derecho ajustado
          Positioned(
            left: 155, 
            right: 8, // Margen mínimo para que no se corten las cabezas
            top: 15,
            bottom: 15,
            child: ClipRect(
              child: _MatchstickContainerWood(count: count),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchstickBoxPlate extends StatelessWidget {
  final int count;
  final TrucoTheme theme;

  const _MatchstickBoxPlate({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 160, // Increased height to give safe vertical padding for rotations
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The Plate SVG explicitly sized to leave top/bottom margins
          SizedBox(
            width: 260,
            height: 120,
            child: SvgPicture.asset(
              'assets/images/plate.svg',
              fit: BoxFit.contain,
            ),
          ),
          
          // Beans clustered in the center of the plate
          SizedBox(
            width: 260,
            height: 120,
            child: _MatchstickContainerPlate(count: count),
          ),
        ],
      ),
    );
  }
}

class _MatchstickContainerPlate extends StatelessWidget {
  final int count;

  const _MatchstickContainerPlate({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ...List.generate(math.max(0, count), (index) {
          final random = math.Random(index * 1337); 
          final angle = (random.nextDouble() - 0.5) * 4.0;
          
          // Allow a wider horizontal distribution to fill the plate
          final offsetX = (random.nextDouble() - 0.5) * 180; 
          
          // Allow a wider vertical distribution, taking advantage of the new SVG margins
          final offsetY = (random.nextDouble() - 0.5) * 45;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: angle,
              child: const BeanWidget(size: 24), // Size increased slightly again
            ),
          );
        }),
      ],
    );
  }
}
