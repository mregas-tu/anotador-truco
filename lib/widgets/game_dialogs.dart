import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import 'truco_buttons.dart';
import 'truco_dialog.dart';
import 'fernet_glass_widget.dart';
import '../services/persistence_service.dart';
import 'dart:async';
import '../services/result_share_service.dart';

abstract class GameDialogs {
  static void showWinner(
    BuildContext context,
    ScoreProvider scoreProvider, {
    bool silenceAd = false,
  }) {
    final String winnerKey = scoreProvider.winner!;
    final String winnerName = winnerKey == "nosotros"
        ? scoreProvider.nosotrosName
        : scoreProvider.ellosName;

    final isPremium =
        Provider.of<PremiumProvider>(context, listen: false).isPremium;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!silenceAd) {
        AdService.showInterstitial(
          isPremium: isPremium,
          source: 'game_finished',
        );
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: TrucoDialog(
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
                    color: _winnerNameColor(scoreProvider.appTheme),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _FinalScore(
                      points: scoreProvider.getDisplayPoints('nosotros'),
                      stage: scoreProvider.getLabel('nosotros'),
                      color: scoreProvider.appTheme.cream,
                      stageColor: scoreProvider.isBuenas('nosotros')
                          ? scoreProvider.appTheme.buenas
                          : scoreProvider.appTheme.malas,
                    ),
                  ),
                  Text(
                    '–',
                    style: TextStyle(
                      fontFamily: AppFonts.caminito,
                      fontSize: 38,
                      color: scoreProvider.appTheme.cream,
                    ),
                  ),
                  Expanded(
                    child: _FinalScore(
                      points: scoreProvider.getDisplayPoints('ellos'),
                      stage: scoreProvider.getLabel('ellos'),
                      color: scoreProvider.appTheme.cream,
                      stageColor: scoreProvider.isBuenas('ellos')
                          ? scoreProvider.appTheme.buenas
                          : scoreProvider.appTheme.malas,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                PrimaryButton(
                  text: "VOLVER A JUGAR",
                  width: double.infinity,
                  fontSize: 16,
                  onPressed: () {
                    scoreProvider.triggerReset();
                    AnalyticsService.logNewGameStarted();
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
                          AnalyticsService.logUndoFromSummary();
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
                          await ResultShareService.shareCurrent(
                            winnerName: winnerName,
                            nosotrosName: scoreProvider.nosotrosName,
                            ellosName: scoreProvider.ellosName,
                            nosotrosScore: scoreProvider.nosotros,
                            ellosScore: scoreProvider.ellos,
                            targetScore:
                                scoreProvider.currentGameMode.totalPoints,
                            hasBuenas: scoreProvider.currentGameMode.hasBuenas,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
      builder: (context) => PopScope(
        canPop: false,
        child: TrucoDialog(
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
                      AnalyticsService.logNewGameStarted();
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
                      AnalyticsService.logGameRestored();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  AnalyticsService.logPremiumPromptAccepted(
                      'unlock_dialog_$type');
                  premiumProvider.buyPremium(source: 'unlock_dialog_$type');
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
                            if (index >= 0 &&
                                index < availablePalettes.length) {
                              scoreProvider
                                  .setPalette(availablePalettes[index]);
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
                      color:
                          scoreProvider.appTheme.white.withValues(alpha: 0.5),
                      fontFamily: AppFonts.oswald),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showPremiumBenefits(BuildContext context,
      {required String source}) {
    final premiumProvider =
        Provider.of<PremiumProvider>(context, listen: false);
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);

    AnalyticsService.logPremiumPromptShown(source);
    bool accepted = false;

    Widget benefit(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle,
                  color: scoreProvider.appTheme.cream, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.3,
                    fontFamily: AppFonts.oswald,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

    showDialog(
      context: context,
      builder: (context) => TrucoDialog(
        title: "¡SUMATE A PREMIUM!",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cuesta menos que un café con medialuna ☕🥐… y te dura para siempre.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
                fontFamily: AppFonts.oswald,
              ),
            ),
            const SizedBox(height: 16),
            benefit("Eliminás toda la publicidad para siempre"),
            benefit("Desbloqueás todos los temas de la app"),
            benefit("Desbloqueás todos los diseños de fósforos"),
            benefit("Desbloqueás todos los diseños de porotos"),
            benefit("Ayudás a un desarrollador independiente ❤️"),
          ],
        ),
        actions: [
          Column(
            children: [
              PrimaryButton(
                text: "QUIERO SER PREMIUM",
                width: double.infinity,
                onPressed: () async {
                  accepted = true;
                  AnalyticsService.logPremiumPromptAccepted(source);
                  Navigator.pop(context);
                  await premiumProvider.buyPremium(source: source);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "AHORA NO",
                  style: TextStyle(
                    color: scoreProvider.appTheme.white.withValues(alpha: 0.5),
                    fontFamily: AppFonts.oswald,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await premiumProvider.restorePurchases();
                },
                child: Text(
                  "Restaurar compras",
                  style: TextStyle(
                    color: scoreProvider.appTheme.white.withValues(alpha: 0.35),
                    fontFamily: AppFonts.oswald,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        scoreProvider.appTheme.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((_) {
      if (!accepted) {
        AnalyticsService.logPremiumPromptDismissed(source);
      }
    });
  }

  static void showRatingDialog(
    BuildContext context,
    ScoreProvider scoreProvider, {
    required VoidCallback onRate,
    required VoidCallback onLater,
    required VoidCallback onFeedback,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: TrucoDialog(
          showBanner: false,
          title: "¡GRACIAS POR JUGAR!",
          contentText:
              "¿Te está gustando Puro Truco?\nTu opinión nos ayuda mucho a seguir mejorando.",
          actions: [
            Column(
              children: [
                PrimaryButton(
                  text: "ME ENCANTA",
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onRate();
                    AnalyticsService.logRateAppAction('rate_now');
                  },
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: "Ahora no",
                  width: double.infinity,
                  toUpperCase: false,
                  onPressed: () {
                    Navigator.pop(context);
                    onLater();
                    AnalyticsService.logRateAppAction('later');
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onFeedback();
                    AnalyticsService.logRateAppAction('never_or_feedback');
                  },
                  child: Text(
                    "Podría mejorar...",
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showVaso(BuildContext context) {
    final premium = Provider.of<PremiumProvider>(context, listen: false);
    AnalyticsService.logVasoDialogOpened(isPremium: premium.isPremium);
    showDialog(
      context: context,
      builder: (ctx) => const _VasoDialog(),
    );
  }

  /// Devuelve el widget del brindis para embeber en otro dialog/pane.
  static Widget buildVasoBody(BuildContext context) => const _VasoDialog();
}

class _VasoDialog extends StatefulWidget {
  const _VasoDialog();

  @override
  State<_VasoDialog> createState() => _VasoDialogState();
}

class _VasoDialogState extends State<_VasoDialog> {
  static const int _adsPerBar = 5;
  static const Duration _cooldown = Duration(seconds: 30);
  static const Duration _fillAnim = Duration(milliseconds: 2500);
  static const Duration _premiumDuration = Duration(hours: 24);

  int _adsInBar = 0;
  int _vasosFilled = 0;
  int _lastAdAt = 0;
  Duration _remaining = Duration.zero;
  Timer? _ticker;
  Timer? _uiTicker; // actualiza el countdown de 24hs cada segundo

  // Animación del vaso: cada iteración recrea el widget para que arranque
  // limpio en 0 antes de animar a 1.
  int _vasoIteration = 0;
  double _vasoProgress = 0.0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    AdService.loadRewardedAd();
    _loadState();
    // Ticker permanente para actualizar el countdown de DISEÑOS DESBLOQUEADOS
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadState() async {
    final int adsInBar = await PersistenceService.getVasoAdsWatched();
    final int filled = await PersistenceService.getVasoBrindados();
    final int last = await PersistenceService.getVasoLastAdAt();
    if (!mounted) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final bool stillInCooldown = _cooldown.inMilliseconds - (now - last) > 0;
    setState(() {
      _adsInBar = adsInBar.clamp(0, _adsPerBar - 1);
      _vasosFilled = filled;
      _lastAdAt = last;
      if (stillInCooldown) _vasoProgress = 1.0;
    });
    _refreshCooldown();
  }

  void _refreshCooldown() {
    _ticker?.cancel();
    void tick() {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int remainingMs = _cooldown.inMilliseconds - (now - _lastAdAt);
      if (!mounted) return;
      if (remainingMs <= 0) {
        setState(() {
          _remaining = Duration.zero;
          // Vaciamos el vaso cuando se habilita un nuevo video.
          _vasoProgress = 0.0;
        });
        _ticker?.cancel();
      } else {
        setState(() => _remaining = Duration(milliseconds: remainingMs));
      }
    }

    tick();
    if (_remaining > Duration.zero) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<void> _onRewardEarned() async {
    if (!mounted || _animating) return;

    // === Datos: corren apenas vuelve del video, NO dependen de la animación ===
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int newBar = _adsInBar + 1;
    final bool barCompleted = newBar >= _adsPerBar;
    final int newAdsInBar = barCompleted ? 0 : newBar;
    final int newVasosFilled = _vasosFilled + 1;

    final premiumNow = Provider.of<PremiumProvider>(context, listen: false);

    // Analytics
    AnalyticsService.logVasoFilled(
      isPremium: premiumNow.isPremium,
      vasosFilledTotal: newVasosFilled,
      adsInBar: newAdsInBar,
    );

    // Persistencia
    await PersistenceService.setVasoAdsWatched(newAdsInBar);
    await PersistenceService.setVasoBrindados(newVasosFilled);
    await PersistenceService.setVasoLastAdAt(now);

    // Premium temporal si llenó la barra
    if (barCompleted && !premiumNow.isPremium) {
      await premiumNow.extendGlobalTempUnlock(_premiumDuration);
      AnalyticsService.logVasoTempPremiumUnlocked(
        vasosFilledTotal: newVasosFilled,
      );
    }

    if (!mounted) return;

    // Estado de UI
    setState(() {
      _adsInBar = newAdsInBar;
      _vasosFilled = newVasosFilled;
      _lastAdAt = now;
    });
    _refreshCooldown();

    // === Animación: solo cosmética, no dispara ningún evento ===
    if (!mounted) return;
    setState(() {
      _animating = true;
      _vasoIteration++;
      _vasoProgress = 0.0;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _vasoProgress = 1.0);

    await Future.delayed(_fillAnim);
    if (!mounted) return;
    setState(() => _animating = false);
  }

  String _formatRemaining(Duration d) {
    return '${d.inSeconds}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _uiTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final bool isPremium = premiumProvider.isPremium;
    final bool hasGlobalTemp = premiumProvider.hasGlobalTempUnlock;
    final String? tempRemaining =
        premiumProvider.getGlobalTempUnlockRemaining();
    final bool inCooldown = _remaining > Duration.zero;

    final String description = isPremium
        ? "¿Te gusta la app? Llená vasos viendo publicidades y ayudame a mantenerla ❤️"
        : hasGlobalTemp
            ? "Diseños desbloqueados ✨ Llená más vasos si te gusta la app y querés ayudar a mantenerla ❤️"
            : "Mirá videos para llenar el vaso. Cada 5 vasos desbloqueás todos los temas y diseños por 24hs.";

    final Color iconColor = scoreProvider.appTheme.cream;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
            fontFamily: AppFonts.oswald,
          ),
        ),
        const SizedBox(height: 14),
        FernetGlassWidget(
          key: ValueKey(_vasoIteration),
          progress: _vasoProgress,
          width: 150,
          height: 210,
          fillDuration: _fillAnim,
        ),
        const SizedBox(height: 14),
        if (!isPremium && !hasGlobalTemp) ...[
          _BarSegments(
            current: _adsInBar,
            total: _adsPerBar,
            color: scoreProvider.appTheme.cream,
          ),
          const SizedBox(height: 6),
          Text(
            "$_adsInBar / $_adsPerBar",
            style: TextStyle(
              color: scoreProvider.appTheme.cream,
              fontSize: 18,
              fontFamily: AppFonts.caminito,
            ),
          ),
        ],
        if (hasGlobalTemp) ...[
          const SizedBox(height: 8),
          Text(
            "DISEÑOS DESBLOQUEADOS • ${tempRemaining ?? ''}",
            style: TextStyle(
              color: scoreProvider.appTheme.cream,
              fontFamily: AppFonts.oswald,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 18),
        // Botón o cooldown (full-width)
        if (inCooldown && !hasGlobalTemp)
          Text(
            "Próximo video en ${_formatRemaining(_remaining)}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scoreProvider.appTheme.cream,
              fontFamily: AppFonts.oswald,
              fontSize: 15,
              letterSpacing: 1,
            ),
          )
        else if (!_animating && (!hasGlobalTemp || isPremium))
          PrimaryButton(
            text: "VER UN VIDEO",
            width: double.infinity,
            onPressed: () {
              final premiumNow =
                  Provider.of<PremiumProvider>(context, listen: false);
              AnalyticsService.logVasoVideoButtonTapped(
                isPremium: premiumNow.isPremium,
                vasosFilledBefore: _vasosFilled,
              );
              AdService.showRewardedAd(
                onUserEarnedReward: _onRewardEarned,
                onAdNotReady: () {
                  if (!mounted) return;
                  AnalyticsService.logVasoAdNotReady(
                    isPremium: premiumNow.isPremium,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("No hay videos disponibles, probá en un rato."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        if (!_animating && hasGlobalTemp && !isPremium)
          Text(
            "Contenido desbloqueado ✨",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scoreProvider.appTheme.cream.withValues(alpha: 0.7),
              fontFamily: AppFonts.oswald,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        const SizedBox(height: 14),
        // Contador lifetime centrado debajo del botón
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 20,
              child: CustomPaint(
                painter: _StaticVasoIconPainter(
                  outline: scoreProvider.appTheme.cream,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Vasos brindados: $_vasosFilled",
              style: TextStyle(
                color: scoreProvider.appTheme.cream,
                fontFamily: AppFonts.oswald,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BarSegments extends StatelessWidget {
  final int current;
  final int total;
  final Color color;

  const _BarSegments({
    required this.current,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool filled = i < current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 28,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StaticVasoIconPainter extends CustomPainter {
  final Color outline;

  _StaticVasoIconPainter({required this.outline});

  static const Color _liquid = Color(0xFF2A0A04);
  static const Color _foam = Color(0xFFD4B894);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Forma del vaso (tapered tumbler)
    final Path glass = Path()
      ..moveTo(w * 0.10, h * 0.05)
      ..lineTo(w * 0.20, h * 0.92)
      ..quadraticBezierTo(w * 0.50, h * 1.02, w * 0.80, h * 0.92)
      ..lineTo(w * 0.90, h * 0.05)
      ..close();

    canvas.save();
    canvas.clipPath(glass);

    // Líquido (parte de abajo, ~65% de altura)
    final double liquidTop = h * 0.30;
    final Path liquid = Path()
      ..moveTo(0, liquidTop)
      ..lineTo(w, liquidTop)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(liquid, Paint()..color = _liquid);

    // Espuma (top ~25%)
    final Path foam = Path()
      ..moveTo(0, h * 0.05)
      ..lineTo(w, h * 0.05)
      ..lineTo(w, liquidTop)
      ..lineTo(0, liquidTop)
      ..close();
    canvas.drawPath(foam, Paint()..color = _foam);

    canvas.restore();

    // Contorno
    canvas.drawPath(
      glass,
      Paint()
        ..color = outline
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _StaticVasoIconPainter old) =>
      old.outline != outline;
}

Color _winnerNameColor(TrucoTheme theme) {
  final candidates = [theme.teamNameColor, theme.accentColor, theme.cream];
  return candidates.firstWhere(
    (color) => _contrastRatio(color, theme.navy) >= 4.5,
    orElse: () => theme.cream,
  );
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance < secondLuminance ? firstLuminance : secondLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _FinalScore extends StatelessWidget {
  final int points;
  final String stage;
  final Color color;
  final Color stageColor;

  const _FinalScore({
    required this.points,
    required this.stage,
    required this.color,
    required this.stageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$points',
            style: TextStyle(
              fontFamily: AppFonts.caminito,
              fontSize: 52,
              height: 0.95,
              color: color,
            ),
          ),
        ),
        Text(
          stage,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: stageColor,
          ),
        ),
      ],
    );
  }
}

