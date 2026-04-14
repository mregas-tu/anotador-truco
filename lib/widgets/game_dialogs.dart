import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';
import 'truco_dialog.dart';
import 'victory_share_card.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

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
                      onPressed: () async {
                        final screenshotController = ScreenshotController();

                        // Capturar el widget estilizado en memoria (sin mostrarlo en pantalla)
                        final Uint8List? imageBytes =
                            await screenshotController.captureFromWidget(
                          VictoryShareCard(
                            winnerName: winnerName,
                            scoreNosotros: scoreProvider.nosotros,
                            scoreEllos: scoreProvider.ellos,
                            theme: scoreProvider.appTheme,
                          ),
                          delay: const Duration(milliseconds: 100),
                        );

                        if (imageBytes != null) {
                          // Guardar en un archivo temporal
                          final directory = await getTemporaryDirectory();
                          final String path =
                              '${directory.path}/resultado_truco.png';
                          final File file = File(path);
                          await file.writeAsBytes(imageBytes);

                          // Compartir el archivo generado
                          final message =
                              "#AnotadorDeTruco\n${Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=com.mregas.truco.anotador' : 'https://apps.apple.com/app/idYOUR_APP_ID'}";
                          await Share.shareXFiles(
                            [XFile(path)],
                            text: message,
                          );
                        }
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

                        // Auto-selection logic after unlocking via video
                        if (id.startsWith('theme_')) {
                          final themeName = id.replaceFirst('theme_', '');
                          try {
                            final theme = TrucoTheme.allThemes
                                .firstWhere((t) => t.name == themeName);
                            scoreProvider.setAppTheme(theme);
                          } catch (_) {}
                        } else if (id.startsWith('palette_')) {
                          try {
                            final index =
                                int.parse(id.replaceFirst('palette_', ''));
                            if (index >= 0 && index < availablePalettes.length) {
                              scoreProvider.setPalette(availablePalettes[index]);
                            }
                          } catch (_) {}
                        } else if (id.startsWith('bean_palette_')) {
                          try {
                            final index =
                                int.parse(id.replaceFirst('bean_palette_', ''));
                            if (index >= 0 &&
                                index < availableBeanPalettes.length) {
                              scoreProvider
                                  .setBeanPalette(availableBeanPalettes[index]);
                            }
                          } catch (_) {}
                        }
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
