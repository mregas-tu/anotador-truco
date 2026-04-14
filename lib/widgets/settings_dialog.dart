import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';

class SettingsDialogContent extends StatefulWidget {
  final Function(String) onThemeLockedTap;
  final Function(int) onPaletteLockedTap;
  final VoidCallback onPremiumTap;
  final VoidCallback onRepeatTutorial;

  const SettingsDialogContent({
    super.key,
    required this.onThemeLockedTap,
    required this.onPaletteLockedTap,
    required this.onPremiumTap,
    required this.onRepeatTutorial,
  });

  @override
  State<SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<SettingsDialogContent> {
  int currentPane = 0; // 0: Main, 1: Customization, 2: Game Mode
  Timer? _timer;
  final ScrollController _gameModeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameModeScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedMode(ScoreProvider scoreProvider) {
    if (!mounted) return;
    final index = availableModes
        .indexWhere((m) => m.label == scoreProvider.currentGameMode.label);
    if (index != -1) {
      // ListTile height with internal padding is approx 48-52
      const double itemHeight = 48.0;
      final double offset = index * (itemHeight + 1.0);

      _gameModeScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _sendFeedbackEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'martoregas@gmail.com', // EMAIL DEL USUARIO
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Puro Truco - Dudas y sugerencias',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo abrir el correo: martoregas@gmail.com')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final bool isSmallScreen = MediaQuery.of(context).size.height < 700;

    String title = "AJUSTES";
    if (currentPane == 1) title = "DISEÑO";
    if (currentPane == 2) title = "MODO DE JUEGO";
    if (currentPane == 3) title = "AYUDA Y SOPORTE";
    if (currentPane == 4) title = "ACERCA DE";
    if (currentPane == 5) title = "VALORES Y SEÑAS";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Back icon, Title, Close icon)
        Stack(
          alignment: Alignment.center,
          children: [
            if (currentPane != 0)
              Positioned(
                left: 0,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (currentPane == 4 || currentPane == 5) {
                        currentPane = 3;
                      } else {
                        currentPane = 0;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_back,
                      color: scoreProvider.appTheme.cream),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 20,
                color: scoreProvider.appTheme.cream,
                letterSpacing: 0,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: scoreProvider.appTheme.cream),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (currentPane == 0) ...[
          // --- PANE 0: MAIN SETTINGS ---
          _buildMenuActionItem(
            label: "SONIDO",
            iconAsset: 'assets/images/menu_icons/sound_icon.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: Switch(
              value: !scoreProvider.isMuted,
              onChanged: (val) {
                scoreProvider.setMuted(!val);
              },
              activeColor: Colors.white,
              activeTrackColor: scoreProvider.appTheme.accentColor,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuActionItem(
            label: "VIBRACIÓN",
            iconAsset: 'assets/images/menu_icons/vibration.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: Switch(
              value: scoreProvider.vibrationEnabled,
              onChanged: (val) {
                scoreProvider.setVibrationEnabled(val);
              },
              activeColor: Colors.white,
              activeTrackColor: scoreProvider.appTheme.accentColor,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuActionItem(
            label: "MODO DE CONTROL",
            iconAsset: 'assets/images/menu_icons/control_mode_icon.svg',
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor:
                    scoreProvider.appTheme.slate.withValues(alpha: 0.1),
              ),
              onPressed: () {
                final nextMode = scoreProvider.scoringMode == ScoringMode.drag
                    ? ScoringMode.tap
                    : scoreProvider.scoringMode == ScoringMode.tap
                        ? ScoringMode.classic
                        : ScoringMode.drag;
                scoreProvider.setScoringMode(nextMode);
              },
              child: Text(
                scoreProvider.scoringMode == ScoringMode.drag
                    ? "ARRASTRAR"
                    : scoreProvider.scoringMode == ScoringMode.tap
                        ? "TOQUE"
                        : "CLÁSICO",
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 14,
                  color: scoreProvider.appTheme.cream,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "MODO DE JUEGO",
            iconAsset: 'assets/images/menu_icons/game_mode_icon.svg',
            onTap: () {
              setState(() => currentPane = 2);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedMode(scoreProvider);
              });
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "DISEÑO",
            iconAsset: 'assets/images/menu_icons/design_icon.svg',
            onTap: () => setState(() => currentPane = 1),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "AYUDA Y SOPORTE",
            iconAsset: 'assets/images/menu_icons/support_icon.svg',
            onTap: () => setState(() => currentPane = 3),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          if (!premiumProvider.isPremium) ...[
            _buildMenuNavigationItem(
              label: "HACERME PREMIUM",
              iconAsset: 'assets/images/menu_icons/premium_icon.svg',
              onTap: () {
                Navigator.pop(context);
                premiumProvider.buyPremium();
              },
              scoreProvider: scoreProvider,
              isSmallScreen: isSmallScreen,
            ),
            Divider(color: scoreProvider.appTheme.slate, height: 1),
          ],
          _buildMenuNavigationItem(
            label: "RESTAURAR COMPRAS",
            iconAsset: 'assets/images/menu_icons/restauring_icon.svg',
            onTap: () async {
              await premiumProvider.restorePurchases();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Buscando compras anteriores...")));
              }
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),

          const SizedBox(height: 24),

          SecondaryButton(
            text: "Compartir app",
            width: double.infinity,
            iconAsset: 'assets/images/share_icon.svg',
            onPressed: () {
              Share.share(
                  "¡Mirá este anotador de Truco premium! Bajalo acá: [LINK]");
            },
          ),
        ] else if (currentPane == 1) ...[
          // --- PANE 1: DESIGN (THEMES & PALETTES) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text("TEMA DE LA APP",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: TrucoTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = TrucoTheme.allThemes[index];
                  final isSelected = scoreProvider.appTheme.name == theme.name;
                  final isLocked = !premiumProvider.isThemeUnlocked(theme.name);

                  return GestureDetector(
                    onTap: () {
                      if (isLocked) {
                        widget.onThemeLockedTap(theme.name);
                      } else {
                        scoreProvider.setAppTheme(theme);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.navy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white10,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          children: [
                            if (theme.name == "NAVY PROFUNDO")
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: SvgPicture.asset(
                                        'assets/images/footer.svg',
                                        fit: BoxFit.contain),
                                  ),
                                ),
                              )
                            else if (theme.name == "ARGENTINA")
                              Positioned.fill(
                                child: Column(
                                  children: [
                                    Expanded(
                                        child: Container(
                                            color: const Color(0xFF74ACDF))),
                                    Expanded(
                                      child: Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: SvgPicture.asset(
                                              'assets/images/sun.svg',
                                              height: 16,
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Container(
                                            color: const Color(0xFF74ACDF))),
                                  ],
                                ),
                              )
                            else if (theme.backgroundAsset != null)
                              Positioned.fill(
                                child: Image.asset(theme.backgroundAsset!,
                                    fit: BoxFit.cover),
                              ),
                            if (isLocked)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                    child: Icon(Icons.lock,
                                        color: Colors.white70, size: 24)),
                              )
                            else if (premiumProvider
                                    .getRemainingTime('theme_${theme.name}') !=
                                null)
                              Container(
                                color: Colors.black45,
                                alignment: Alignment.center,
                                child: Text(
                                  premiumProvider
                                      .getRemainingTime('theme_${theme.name}')!,
                                  style: const TextStyle(
                                    fontFamily: AppFonts.oswald,
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                  ),
                                ),
                              )
                            else if (isSelected)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.check,
                                      size: 12, color: theme.navy),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text("TIPO DE FICHAS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          scoreProvider.setPointType(PointType.matches),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: scoreProvider.pointType == PointType.matches
                              ? scoreProvider.appTheme.cream
                                  .withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scoreProvider.pointType == PointType.matches
                                ? scoreProvider.appTheme.cream
                                : Colors.white10,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "FÓSFOROS",
                          style: TextStyle(
                            fontFamily: AppFonts.oswald,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => scoreProvider.setPointType(PointType.beans),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: scoreProvider.pointType == PointType.beans
                              ? scoreProvider.appTheme.cream
                                  .withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scoreProvider.pointType == PointType.beans
                                ? scoreProvider.appTheme.cream
                                : Colors.white10,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "POROTOS",
                          style: TextStyle(
                            fontFamily: AppFonts.oswald,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                    scoreProvider.pointType == PointType.matches
                        ? "DISEÑO DE FÓSFOROS"
                        : "DISEÑO DE POROTOS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
              if (scoreProvider.pointType == PointType.matches)
                Wrap(
                  spacing: isSmallScreen ? 12 : 16,
                  runSpacing: isSmallScreen ? 12 : 16,
                  children: availablePalettes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final palette = entry.value;
                    final isSelected =
                        scoreProvider.currentPalette.name == palette.name;
                    final isLocked = !premiumProvider.isPaletteUnlocked(index);
                    final timeLeft =
                        premiumProvider.getRemainingTime('palette_$index');

                    return GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          widget.onPaletteLockedTap(index);
                        } else {
                          scoreProvider.setPalette(palette);
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: isSmallScreen ? 44 : 48,
                            height: isSmallScreen ? 44 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  palette.headColors[0],
                                  palette.headColors.last
                                ],
                              ),
                              border: Border.all(
                                color:
                                    isSelected ? Colors.white : Colors.white10,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: palette.headColors.first
                                              .withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2)
                                    ]
                                  : null,
                            ),
                          ),
                          if (isLocked)
                            const Icon(Icons.lock,
                                color: Colors.white, size: 18),
                          if (timeLeft != null)
                            Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black45),
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                timeLeft,
                                style: const TextStyle(
                                  fontFamily: AppFonts.oswald,
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Wrap(
                  spacing: isSmallScreen ? 12 : 16,
                  runSpacing: isSmallScreen ? 12 : 16,
                  children: availableBeanPalettes.asMap().entries.map((entry) {
                    final palette = entry.value;
                    final isSelected =
                        scoreProvider.currentBeanPalette.name == palette.name;

                    Color getBeanPreviewColor(BeanType type) {
                      switch (type) {
                        case BeanType.alubia:
                          return const Color(0xFFF9F6F0);
                        case BeanType.negro:
                          return const Color(0xFF2E2E2E);
                        case BeanType.fideo:
                          return const Color(0xFF8B0000);
                        case BeanType.pinto:
                          return const Color(0xFFD2B48C);
                        case BeanType.manteca:
                          return const Color(0xFFEBEBD3);
                        case BeanType.bandera:
                          return const Color(0xFF5A1A40);
                        case BeanType.cisne:
                          return const Color(0xFFF9F6F0);
                        case BeanType.borlotto:
                          return const Color(0xFFCBA37E);
                        case BeanType.magnum:
                          return const Color(0xFF4B5121);
                        case BeanType.frutilla:
                          return const Color(0xFF9E2A2B);
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        scoreProvider.setBeanPalette(palette);
                      },
                      child: Container(
                        width: isSmallScreen ? 44 : 48,
                        height: isSmallScreen ? 44 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: getBeanPreviewColor(palette.type),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white10,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: getBeanPreviewColor(palette.type)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2)
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ] else if (currentPane == 2) ...[
          // --- PANE 2: GAME MODE ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              controller: _gameModeScrollController,
              shrinkWrap: true,
              itemCount: availableModes.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final mode = availableModes[index];
                final isSelected =
                    scoreProvider.currentGameMode.label == mode.label;

                return ListTile(
                  dense: isSmallScreen,
                  visualDensity: isSmallScreen
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    mode.label,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 16,
                      color: isSelected
                          ? scoreProvider.appTheme.cream
                          : Colors.white70,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.radio_button_checked,
                          color: scoreProvider.appTheme.cream, size: 20)
                      : Icon(Icons.radio_button_off,
                          color: scoreProvider.appTheme.white
                              .withValues(alpha: 0.2),
                          size: 20),
                  onTap: () {
                    scoreProvider.setGameMode(mode);
                  },
                );
              },
            ),
          ),

          // Pica Pica Settings - Exclusive to 30 or 40 point modes
          if (scoreProvider.currentGameMode.totalPoints >= 30) ...[
            const SizedBox(height: 20),
            Divider(
                color: scoreProvider.appTheme.slate.withValues(alpha: 0.2),
                height: 1),
            const SizedBox(height: 12),

            // Checkbox Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => scoreProvider
                    .setPicaPicaEnabled(!scoreProvider.picaPicaEnabled),
                child: Row(
                  children: [
                    // Customized Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scoreProvider.picaPicaEnabled
                              ? scoreProvider.appTheme.cream
                              : scoreProvider.appTheme.slate
                                  .withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: scoreProvider.picaPicaEnabled
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scoreProvider.appTheme.cream,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scoreProvider.appTheme.cream
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "PICA PICA",
                      style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.picaPicaEnabled
                            ? scoreProvider.appTheme.cream
                            : scoreProvider.appTheme.slate
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Range Slider with labels
            Opacity(
              opacity: scoreProvider.picaPicaEnabled ? 1.0 : 0.3,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PUNTOS: ${scoreProvider.picaPicaStart}",
                          style: TextStyle(
                            fontFamily: AppFonts.caminito,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                          ),
                        ),
                        Text(
                          "HASTA: ${scoreProvider.picaPicaEnd}",
                          style: TextStyle(
                            fontFamily: AppFonts.caminito,
                            fontSize: 14,
                            color: scoreProvider.appTheme.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scoreProvider.appTheme.cream,
                      inactiveTrackColor:
                          scoreProvider.appTheme.slate.withValues(alpha: 0.1),
                      thumbColor: scoreProvider.appTheme.cream,
                      overlayColor:
                          scoreProvider.appTheme.cream.withValues(alpha: 0.1),
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 8),
                      activeTickMarkColor: scoreProvider.appTheme.cream,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        scoreProvider.picaPicaStart.toDouble(),
                        scoreProvider.picaPicaEnd.toDouble(),
                      ),
                      min: 0,
                      max: scoreProvider.currentGameMode.totalPoints.toDouble(),
                      divisions: scoreProvider.currentGameMode.totalPoints ~/ 5,
                      onChanged: scoreProvider.picaPicaEnabled
                          ? (RangeValues values) {
                              int start = values.start.round();
                              int end = values.end.round();

                              // Enforce 5 point minimum difference
                              if (end - start < 5) {
                                if (start != scoreProvider.picaPicaStart) {
                                  // Start was moved up
                                  start = end - 5;
                                } else {
                                  // End was moved down
                                  end = start + 5;
                                }
                              }

                              if (start < 0) start = 0;
                              if (end >
                                  scoreProvider.currentGameMode.totalPoints) {
                                end = scoreProvider.currentGameMode.totalPoints;
                                if (end - start < 5) start = end - 5;
                              }

                              scoreProvider.setPicaPicaRange(start, end);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (currentPane == 3) ...[
          _buildMenuNavigationItem(
            label: "VALORES Y SEÑAS",
            onTap: () => setState(() => currentPane = 5),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          // --- PANE 3: HELP & SUPPORT ---
          _buildMenuNavigationItem(
            label: "REPETIR TUTORIAL",
            onTap: () {
              Navigator.pop(context);
              widget.onRepeatTutorial();
            },
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "ESCRIBINOS",
            onTap: _sendFeedbackEmail,
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "ACERCA DE",
            onTap: () => setState(() => currentPane = 4),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
        ] else if (currentPane == 4) ...[
          // --- PANE 4: ABOUT ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/about.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Versión 1.1.4",
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 14,
                    color: scoreProvider.appTheme.slate,
                  ),
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Falta envido y truco. La forma más práctica de anotar los puntos en cada asado.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 16,
                    color: scoreProvider.appTheme.cream,
                  ),
                ),
                const SizedBox(height: 20), // Standarized to 20
                Text(
                  "Desarrollado con ❤️ en Argentina",
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scoreProvider.appTheme.slate,
                  ),
                ),
              ],
            ),
          ),
        ] else if (currentPane == 5) ...[
          // --- PANE 5: CARD VALUES & SIGNS ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trucoCardHierarchy.length,
              itemBuilder: (context, index) {
                final item = trucoCardHierarchy[index];
                final cardGroup = item['assets'] as List<String>;
                final signAsset = item['sign'] as String?;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 32, right: 32, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          // Cards (Left)
                          SizedBox(
                            height: 66,
                            width: 100,
                            child: Stack(
                              children: cardGroup.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final asset = entry.value;
                                return Positioned(
                                  left: idx * 16.0,
                                  child: _buildSmallCard(asset),
                                );
                              }).toList(),
                            ),
                          ),
                          const Spacer(),
                          if (signAsset != null) ...[
                            // Sign (Right)
                            Column(
                              children: [
                                Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      signAsset,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Text(
                                  item['signName'] ?? "",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.oswald,
                                    fontSize: 10,
                                    color: scoreProvider.appTheme.slate,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            const SizedBox(width: 75), // Mantener alineación
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuActionItem({
    required String label,
    String? iconAsset,
    required Widget trailing,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                scoreProvider.appTheme.cream,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 16,
              color: scoreProvider.appTheme.cream,
            ),
          ),
        ],
      ),
      trailing: trailing,
    );
  }

  Widget _buildMenuNavigationItem({
    required String label,
    String? iconAsset,
    required VoidCallback onTap,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                scoreProvider.appTheme.cream,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 16,
              color: scoreProvider.appTheme.cream,
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: scoreProvider.appTheme.cream),
      onTap: onTap,
    );
  }

  Widget _buildSmallCard(String asset) {
    return Container(
      width: 44,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          asset,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white12,
            child: const Icon(Icons.error, color: Colors.white24, size: 16),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> trucoCardHierarchy = [
  {
    'assets': ['assets/images/cards/espada_1.png'],
    'sign': 'assets/images/signs/1_espada_sign.png',
    'signName': 'Levantar cejas'
  },
  {
    'assets': ['assets/images/cards/basto_1.png'],
    'sign': 'assets/images/signs/1_basto_sign.png',
    'signName': 'Guiñar un ojo'
  },
  {
    'assets': ['assets/images/cards/espada_7.png'],
    'sign': 'assets/images/signs/7_espada_sign.png',
    'signName': 'Boca a la derecha'
  },
  {
    'assets': ['assets/images/cards/oro_7.png'],
    'sign': 'assets/images/signs/7_oro_sign.png',
    'signName': 'Boca a la izquierda'
  },
  {
    'assets': [
      'assets/images/cards/oro_3.png',
      'assets/images/cards/copa_3.png',
      'assets/images/cards/espada_3.png',
      'assets/images/cards/basto_3.png'
    ],
    'sign': 'assets/images/signs/3_sign.png',
    'signName': 'Morder el labio'
  },
  {
    'assets': [
      'assets/images/cards/oro_2.png',
      'assets/images/cards/copa_2.png',
      'assets/images/cards/espada_2.png',
      'assets/images/cards/basto_2.png'
    ],
    'sign': 'assets/images/signs/2_sign.png',
    'signName': 'Hacer pico / beso'
  },
  {
    'assets': ['assets/images/cards/oro_1.png', 'assets/images/cards/copa_1.png'],
    'sign': 'assets/images/signs/1_sign.png',
    'signName': 'Abrir la boca'
  },
  {
    'assets': [
      'assets/images/cards/oro_12.png',
      'assets/images/cards/copa_12.png',
      'assets/images/cards/espada_12.png',
      'assets/images/cards/basto_12.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_11.png',
      'assets/images/cards/copa_11.png',
      'assets/images/cards/espada_11.png',
      'assets/images/cards/basto_11.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_10.png',
      'assets/images/cards/copa_10.png',
      'assets/images/cards/espada_10.png',
      'assets/images/cards/basto_10.png'
    ],
    'sign': null
  },
  {
    'assets': ['assets/images/cards/copa_7.png', 'assets/images/cards/basto_7.png'],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_6.png',
      'assets/images/cards/copa_6.png',
      'assets/images/cards/espada_6.png',
      'assets/images/cards/basto_6.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_5.png',
      'assets/images/cards/copa_5.png',
      'assets/images/cards/espada_5.png',
      'assets/images/cards/basto_5.png'
    ],
    'sign': null
  },
  {
    'assets': [
      'assets/images/cards/oro_4.png',
      'assets/images/cards/copa_4.png',
      'assets/images/cards/espada_4.png',
      'assets/images/cards/basto_4.png'
    ],
    'sign': null
  },
];
