import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/score_provider.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';

const List<Map<String, String>> kTutorialSteps = [
  {
    "title": "MODO ARRASTRE",
    "desc":
        "Arrastrá un punto desde la caja hacia la mesa para sumar puntos en el jugador."
  },
  {
    "title": "MODE ARRASTRE",
    "desc":
        "Para sacar el último punto, arrastralo desde la mesa hacia la caja."
  },
  {
    "title": "MODO TOQUE",
    "desc": "Hacé un toque sobre la mesa para sumar puntos."
  },
  {
    "title": "MODO TOQUE",
    "desc": "Para sacar el último punto mantené el dedo sobre la mesa."
  },
  {
    "title": "MODO CLÁSICO",
    "desc": "Para agregar y sacar puntos utilizá los botones + y -."
  },
  {
    "title": "CAMBIAR NOMBRES",
    "desc": "Tocá “Nosotros” o “Ellos” para editar el nombre del equipo."
  },
  {
    "title": "PUNTUACIÓN TOTAL",
    "desc":
        "En el centro ves los puntos totales de la partida. Tocá ahí para revisar los puntos anotados."
  },
  {
    "title": "REINICIAR PARTIDA",
    "desc":
        "Usá la flecha ubicada arriba a la izquierda para reiniciar los puntos de la partida."
  },
  {
    "title": "MENÚ DE AJUSTES",
    "desc":
        "Usá el engranaje ubicado arriba a la derecha para personalizar temas, modo de juego, típo de control y más."
  },
];

class TutorialOverlay extends StatelessWidget {
  final int currentStep;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool isFinalStep;
  final bool isStandalone;
  final String? titleOverride;
  final String? descriptionOverride;

  const TutorialOverlay({
    super.key,
    required this.currentStep,
    required this.onSkip,
    required this.onNext,
    this.isFinalStep = false,
    this.isStandalone = false,
    this.titleOverride,
    this.descriptionOverride,
  });

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final isTop = currentStep <= 4;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final offset = isSmallScreen ? 80.0 : 150.0;
    final title = titleOverride ?? kTutorialSteps[currentStep]["title"]!;
    final description =
        descriptionOverride ?? kTutorialSteps[currentStep]["desc"]!;

    return Positioned(
      top: isTop ? offset : null,
      bottom: !isTop ? offset : null,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scoreProvider.appTheme.navy,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: scoreProvider.appTheme.slate,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scoreProvider.appTheme.white,
                    fontFamily: AppFonts.oswald,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                if (!isStandalone)
                  Text(
                    "${currentStep + 1}/${kTutorialSteps.length}",
                    style: TextStyle(
                      color:
                          scoreProvider.appTheme.white.withValues(alpha: 0.5),
                      fontFamily: AppFonts.oswald,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  description,
                  key: ValueKey<int>(currentStep),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scoreProvider.appTheme.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isStandalone) ...[
                  Expanded(
                    child: SecondaryButton(
                      text: "OMITIR",
                      height: 40,
                      toUpperCase: true,
                      onPressed: onSkip,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: PrimaryButton(
                    text:
                        isFinalStep || currentStep == kTutorialSteps.length - 1
                            ? "FINALIZAR"
                            : "SIGUIENTE",
                    height: 40,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
