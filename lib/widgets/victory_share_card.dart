import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VictoryShareCard extends StatelessWidget {
  final String winnerName;
  final int scoreNosotros;
  final int scoreEllos;

  const VictoryShareCard({
    super.key,
    required this.winnerName,
    required this.scoreNosotros,
    required this.scoreEllos,
  });

  @override
  Widget build(BuildContext context) {
    const theme = TrucoTheme.navyTheme;

    return Container(
      width: 400,
      height: 550,
      decoration: BoxDecoration(
        color: theme.navy,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // Watermark - REAL ASSET (Lowered opacity)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/images/markwatter.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "PURO TRUCO",
                      style: TextStyle(
                        fontFamily: AppFonts.caminito,
                        fontSize: 42,
                        color: theme.cream,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "¡Partida finalizada!",
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 20,
                      color: theme.cream.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    "GANADOR",
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 18,
                      color: theme.cream.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      winnerName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: theme.cream,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${scoreNosotros.toString().padLeft(2, '0')} - ${scoreEllos.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontFamily: AppFonts.caminito,
                        fontSize: 72,
                        color: theme.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer Branding
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "ANOTADOR DE TRUCO",
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 10,
                  letterSpacing: 2,
                  color: theme.cream.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
