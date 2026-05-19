import 'dart:math' as math;
import 'package:flutter/material.dart';

class FernetGlassWidget extends StatefulWidget {
  final double progress;
  final double width;
  final double height;
  final Duration fillDuration;

  const FernetGlassWidget({
    super.key,
    required this.progress,
    this.width = 220,
    this.height = 300,
    this.fillDuration = const Duration(milliseconds: 900),
  });

  @override
  State<FernetGlassWidget> createState() => _FernetGlassWidgetState();
}

class _FernetGlassWidgetState extends State<FernetGlassWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
        duration: widget.fillDuration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, __) => CustomPaint(
              painter: _FernetGlassPainter(
                progress: animatedProgress,
                time: _controller.value * 2 * math.pi,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FernetGlassPainter extends CustomPainter {
  final double progress;
  final double time;

  _FernetGlassPainter({required this.progress, required this.time});

  // Fernet con coca real: tirando a negro con destellos rojizos
  static const Color _liquidDark = Color(0xFF120402);
  static const Color _liquidMid = Color(0xFF2A0A04);
  static const Color _liquidLight = Color(0xFF45120A);
  static const Color _liquidGlow = Color(0xFF6B1E10);
  // Espuma: beige cremoso, no muy clara
  static const Color _foamLight = Color(0xFFE8D4B0);
  static const Color _foamMid = Color(0xFFD4B894);
  static const Color _foamShadow = Color(0xFFA88860);
  static const Color _glassColor = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path glassPath = _glassPath(w, h);

    // Glass back tint (subtle so vacío no quede transparente del todo)
    canvas.drawPath(
      glassPath,
      Paint()..color = _glassColor.withOpacity(0.07),
    );

    // Clip al interior del vaso
    canvas.save();
    canvas.clipPath(glassPath);

    // Cálculos de niveles (también necesarios cuando progress == 0 para que
    // los hielos sepan dónde flotar).
    final double contentTopY = (h * 0.04) + (h * 0.90) * (1 - progress);
    final double maxFoamHeight = h * 0.14;
    final double foamHeight = maxFoamHeight * (progress.clamp(0.0, 1.0));
    final double liquidTopY = contentTopY + foamHeight;
    const int segments = 40;
    const double amp1 = 3.0;
    const double amp2 = 1.5;

    // === HIELOS ===
    // Los hielos están "anclados" a la superficie del líquido: cuando el
    // líquido sube, los hielos suben con él. Cuando el vaso está vacío,
    // quedan apoyados en el fondo (porque el "surface" coincide con el fondo).
    final List<_IceCube> cubes = _generateIceCubes(w, h);
    final List<({_IceCube cube, double y, double x})> placed = [];
    for (final c in cubes) {
      placed.add((
        cube: c,
        y: liquidTopY + c.surfaceYOffset,
        x: w * c.anchorX01,
      ));
    }
    // Dibujar de atrás (mayor Y) hacia adelante (menor Y).
    placed.sort((a, b) => b.y.compareTo(a.y));
    for (final p in placed) {
      _drawIceCube(canvas, Offset(p.x, p.y), p.cube.size, p.cube.rotation);
    }

    if (progress > 0.001) {
      // === LÍQUIDO ===
      // Semi-transparente para que los hielos sumergidos se vean tintados.
      final Path liquidPath = Path()
        ..moveTo(0, liquidTopY)
        ..lineTo(w, liquidTopY)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      final Rect liquidRect = Rect.fromLTRB(0, liquidTopY - 10, w, h);
      canvas.drawPath(
        liquidPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _liquidGlow.withOpacity(0.85),
              _liquidLight.withOpacity(0.88),
              _liquidMid.withOpacity(0.92),
              _liquidDark.withOpacity(0.95),
            ],
            stops: const [0, 0.25, 0.65, 1],
          ).createShader(liquidRect),
      );

      // Burbujas SUBIENDO en el líquido (carbonatación).
      // Importante: usamos múltiplos enteros y módulo limpio sobre el ciclo
      // del AnimationController (que va 0..1) para que el loop sea continuo
      // y no haya "salto" cuando se reinicia.
      final double tNorm = time / (2 * math.pi); // 0..1
      for (int i = 0; i < 14; i++) {
        final double seed = ((i * 53) % 100) / 100;
        final double phase = (tNorm + i * 0.11) % 1.0;
        final double bx = w * (0.12 + seed * 0.76) +
            math.sin(time + i) * 2.2;
        final double by = h - phase * (h - liquidTopY - 4);
        if (by < liquidTopY + 4) continue;
        final double radius = 1.0 + (i % 4) * 0.6;
        canvas.drawCircle(
          Offset(bx, by),
          radius,
          Paint()
            ..color = _foamLight.withOpacity(0.55 * (1 - phase * 0.5)),
        );
      }

      // === ESPUMA (estática, sin animación) ===
      if (foamHeight > 1.5) {
        // Onda fija para los bordes de la espuma (no usa time → no se mueve).
        Path staticWave(double baseY, {double phaseOffset = 0}) {
          final Path p = Path()..moveTo(0, baseY);
          for (int i = 0; i <= segments; i++) {
            final double x = (i / segments) * w;
            final double phase = (i / segments) * 2 * math.pi;
            final double y = baseY +
                math.sin(phase + phaseOffset) * amp1 +
                math.sin(phase * 2 + phaseOffset) * amp2;
            p.lineTo(x, y);
          }
          return p;
        }

        // Cuerpo de la espuma: tope ondulado, base recta a la altura del
        // líquido (así no quedan huecos entre espuma y líquido).
        final Path foamArea = Path()..moveTo(0, contentTopY);
        for (int i = 0; i <= segments; i++) {
          final double x = (i / segments) * w;
          final double phase = (i / segments) * 2 * math.pi;
          final double y = contentTopY +
              math.sin(phase + 0.5) * amp1 +
              math.sin(phase * 2 + 0.5) * amp2;
          foamArea.lineTo(x, y);
        }
        foamArea.lineTo(w, liquidTopY);
        foamArea.lineTo(0, liquidTopY);
        foamArea.close();

        canvas.drawPath(
          foamArea,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _foamLight,
                _foamMid,
                _foamShadow.withOpacity(0.85),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(Rect.fromLTRB(
                0, contentTopY, w, liquidTopY + 4)),
        );

        // Burbujitas de espuma (textura): muchas, distintos tamaños y alphas
        final math.Random rnd = math.Random(7);
        for (int i = 0; i < 60; i++) {
          final double bx = rnd.nextDouble() * w;
          final double byNorm = rnd.nextDouble();
          final double by = contentTopY + byNorm * foamHeight;
          // Las burbujas de la zona inferior (cerca del líquido) tienen un
          // tinte un poco más oscuro
          final double r = 0.8 + rnd.nextDouble() * 1.8;
          final Color c = byNorm < 0.5
              ? _foamLight.withOpacity(0.7 + rnd.nextDouble() * 0.3)
              : _foamMid.withOpacity(0.5 + rnd.nextDouble() * 0.4);
          canvas.drawCircle(Offset(bx, by), r, Paint()..color = c);
          // Pequeño brillo en algunas
          if (rnd.nextDouble() > 0.6) {
            canvas.drawCircle(
              Offset(bx - r * 0.3, by - r * 0.3),
              r * 0.35,
              Paint()..color = Colors.white.withOpacity(0.6),
            );
          }
        }

        // Línea sutil donde la espuma se encuentra con el líquido
        canvas.drawPath(
          staticWave(liquidTopY),
          Paint()
            ..color = _foamShadow.withOpacity(0.5)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );

        // Brillo en el tope de la espuma
        canvas.drawPath(
          staticWave(contentTopY, phaseOffset: 0.5),
          Paint()
            ..color = Colors.white.withOpacity(0.45)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
    }

    canvas.restore();

    // Contorno del vaso
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = _glassColor.withOpacity(0.85)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Brillo lateral izquierdo (reflejo)
    final Path leftShine = Path()
      ..moveTo(w * 0.085, h * 0.07)
      ..lineTo(w * 0.135, h * 0.78);
    canvas.drawPath(
      leftShine,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Brillo lateral derecho más finito
    final Path rightShine = Path()
      ..moveTo(w * 0.92, h * 0.1)
      ..lineTo(w * 0.88, h * 0.6);
    canvas.drawPath(
      rightShine,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  Path _glassPath(double w, double h) {
    final double topInset = w * 0.05;
    final double bottomInset = w * 0.14;
    return Path()
      ..moveTo(topInset, h * 0.02)
      ..lineTo(bottomInset, h * 0.93)
      ..quadraticBezierTo(w / 2, h * 1.0, w - bottomInset, h * 0.93)
      ..lineTo(w - topInset, h * 0.02)
      ..close();
  }

  List<_IceCube> _generateIceCubes(double w, double h) {
    final math.Random rnd = math.Random(13);
    const int count = 5;
    final double baseSize = w * 0.22;
    final List<_IceCube> out = [];
    for (int i = 0; i < count; i++) {
      final double xJitter = (rnd.nextDouble() - 0.5) * 0.04;
      final double yJitter = (rnd.nextDouble() - 0.5) * 4;
      final double size = baseSize * (0.85 + rnd.nextDouble() * 0.3);
      // Todos en una sola fila apoyados en la superficie/fondo.
      final double surfaceYOffset = -baseSize * 0.32 + yJitter;
      out.add(_IceCube(
        anchorX01:
            (0.20 + i * 0.15 + xJitter).clamp(0.16, 0.84),
        surfaceYOffset: surfaceYOffset,
        size: size,
        rotation: (rnd.nextDouble() - 0.5) * 0.5,
      ));
    }
    return out;
  }

  void _drawIceCube(
      Canvas canvas, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final double r = size / 2;
    // Forma irregular (no es un cuadrado perfecto)
    final Path body = Path()
      ..moveTo(-r * 0.95, -r * 0.82)
      ..lineTo(-r * 0.55, -r * 0.98)
      ..lineTo(r * 0.5, -r * 0.92)
      ..lineTo(r * 0.95, -r * 0.45)
      ..lineTo(r * 0.88, r * 0.55)
      ..lineTo(r * 0.4, r * 0.95)
      ..lineTo(-r * 0.6, r * 0.9)
      ..lineTo(-r * 0.92, r * 0.3)
      ..close();

    // Sombra interna (dato base más oscuro para que tenga volumen)
    canvas.drawPath(
      body,
      Paint()..color = const Color(0xFFB8D8E8).withOpacity(0.55),
    );

    // Cara superior brillosa (parte iluminada)
    final Path topFace = Path()
      ..moveTo(-r * 0.85, -r * 0.7)
      ..lineTo(-r * 0.4, -r * 0.85)
      ..lineTo(r * 0.4, -r * 0.78)
      ..lineTo(r * 0.7, -r * 0.45)
      ..lineTo(r * 0.2, -r * 0.2)
      ..lineTo(-r * 0.5, -r * 0.3)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.6),
    );

    // Borde (contorno)
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(0.85)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    // Pequeño brillo
    canvas.drawCircle(
      Offset(-r * 0.35, -r * 0.45),
      r * 0.12,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.95),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FernetGlassPainter old) =>
      old.progress != progress || old.time != time;
}

class _IceCube {
  final double anchorX01;
  final double surfaceYOffset;
  final double size;
  final double rotation;

  const _IceCube({
    required this.anchorX01,
    required this.surfaceYOffset,
    required this.size,
    required this.rotation,
  });
}
