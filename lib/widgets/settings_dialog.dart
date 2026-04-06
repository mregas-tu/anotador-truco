import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = Provider.of<PremiumProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final bool isSmallScreen = MediaQuery.of(context).size.height < 700;

    String title = "AJUSTES";
    if (currentPane == 1) title = "DISEÑO (FÓSFOROS)";
    if (currentPane == 2) title = "MODO DE JUEGO";


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
                  onPressed: () => setState(() => currentPane = 0),
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
            label: "MODO DE CONTROL",
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
            trailing: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor:
                    scoreProvider.appTheme.slate.withValues(alpha: 0.1),
              ),
              onPressed: () {
                scoreProvider.setScoringMode(
                    scoreProvider.scoringMode == ScoringMode.drag
                        ? ScoringMode.tap
                        : ScoringMode.drag);
              },
              child: Text(
                scoreProvider.scoringMode == ScoringMode.drag
                    ? "ARRASTRAR"
                    : "TOQUE",
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
            onTap: () => setState(() => currentPane = 2),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "DISEÑO (FÓSFOROS)",
            onTap: () => setState(() => currentPane = 1),
            scoreProvider: scoreProvider,
            isSmallScreen: isSmallScreen,
          ),
          Divider(color: scoreProvider.appTheme.slate, height: 1),

          if (!premiumProvider.isPremium) ...[
            _buildMenuNavigationItem(
              label: "HACERME PREMIUM",
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
          Divider(color: scoreProvider.appTheme.slate, height: 1),
          _buildMenuNavigationItem(
            label: "REPETIR TUTORIAL",
            onTap: () {
              Navigator.pop(context);
              widget.onRepeatTutorial();
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
                child: Text("DISEÑO DE FÓSFOROS",
                    style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scoreProvider.appTheme.slate,
                        letterSpacing: 0)),
              ),
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
                              color: isSelected ? Colors.white : Colors.white10,
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
                          const Icon(Icons.lock, color: Colors.white, size: 18),
                        if (timeLeft != null)
                          Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.black45),
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
              ),
            ],
          ),
        ] else if (currentPane == 2) ...[
          // --- PANE 2: GAME MODE ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
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
        ],
      ],
    );
  }

  Widget _buildMenuActionItem({
    required String label,
    required Widget trailing,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          fontSize: 16,
          color: scoreProvider.appTheme.cream,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildMenuNavigationItem({
    required String label,
    required VoidCallback onTap,
    required ScoreProvider scoreProvider,
    required bool isSmallScreen,
  }) {
    return ListTile(
      dense: isSmallScreen,
      visualDensity:
          isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.oswald,
          fontSize: 16,
          color: scoreProvider.appTheme.cream,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: scoreProvider.appTheme.cream),
      onTap: onTap,
    );
  }
}
