import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';
import 'truco_dialog.dart';

abstract class GameDialogs {
  static void showWinner(
    BuildContext context,
    ScoreProvider scoreProvider,
  ) {
    final String winnerKey = scoreProvider.winner!;
    final String winnerName = winnerKey == "nosotros"
        ? scoreProvider.nosotrosName
        : scoreProvider.ellosName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Provider.of<PremiumProvider>(context, listen: false).isPremium) {
        AdService.showInterstitial();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrucoDialog(
        title: "¡Partida finalizada!",
        toUpperCaseTitle: false,
        titleFontSize: 20,
        titleColor: scoreProvider.appTheme.cream,
        marginHorizontal: 50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "GANADOR",
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 20,
                color: scoreProvider.appTheme.cream,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                winnerName.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 38,
                  color: scoreProvider.appTheme.slate,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${scoreProvider.nosotros.toString().padLeft(2, '0')} - ${scoreProvider.ellos.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontFamily: AppFonts.caminito,
                  fontSize: 52,
                  color: scoreProvider.appTheme.cream,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              PrimaryButton(
                text: "VOLVER A JUGAR",
                width: double.infinity,
                onPressed: () {
                  scoreProvider.triggerReset();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: "Deshacer",
                      toUpperCase: false,
                      type: SecondaryButtonType.secondary,
                      iconAsset: 'assets/images/undo_icon.svg',
                      onPressed: () {
                        if (winnerKey == "nosotros") {
                          scoreProvider.removePointNosotros();
                        } else {
                          scoreProvider.removePointEllos();
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SecondaryButton(
                      text: "Compartir",
                      toUpperCase: false,
                      iconAsset: 'assets/images/share_icon.svg',
                      onPressed: () {
                        final message =
                            "¡Gané al Truco! $winnerName venció ${scoreProvider.nosotros} a ${scoreProvider.ellos}. #AnotadorDeTruco";
                        Share.share(message);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showRecovery(
    BuildContext context,
    ScoreProvider provider,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrucoDialog(
        title: "Tenés una partida en curso",
        contentText: "¿Querés continuarla o empezar una nueva?",
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: "Nueva partida",
                  toUpperCase: true,
                  onPressed: () {
                    Navigator.pop(context);
                    provider.triggerReset();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: "Continuar partida",
                  onPressed: () {
                    Navigator.pop(context);
                    provider.restoreGame(data);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showUnlock(
    BuildContext context,
    String id,
    String type,
  ) {
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        title: "¡LLEVÁ TU ANOTADOR A OTRO NIVEL! 🚀",
        contentText: id == 'premium'
            ? "Convertite en premium para usar todos los temas, diseños de fósforos y eliminar la publicidad para siempre."
            : "Este diseño es exclusivo de la versión Premium. Podés desbloquearlo temporalmente viendo un video.",
        actions: [
          Column(
            children: [
              PrimaryButton(
                text: "SER PREMIUM",
                width: double.infinity,
                onPressed: () {
                  premiumProvider.buyPremium();
                  Navigator.pop(context);
                },
              ),
              if (id != 'premium') ...[
                const SizedBox(height: 16),
                SecondaryButton(
                  text: "VER VIDEO (24HS GRATIS)",
                  width: double.infinity,
                  toUpperCase: true,
                  onPressed: () {
                    AdService.showRewardedAd(
                      onUserEarnedReward: () {
                        premiumProvider.unlockTemporarily(id);
                      },
                      onAdNotReady: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "El video todavía no está listo. Probá de nuevo en unos segundos."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "QUIZÁS MÁS TARDE",
                  style: TextStyle(
                      color: scoreProvider.appTheme.white.withValues(alpha: 0.5),
                      fontFamily: AppFonts.oswald),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
