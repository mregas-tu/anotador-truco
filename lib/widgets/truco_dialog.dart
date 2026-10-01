import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/live_display_scope.dart';
import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import 'truco_banner_ad.dart';

class TrucoDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? contentText;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;
  final bool toUpperCaseTitle;
  final double titleFontSize;
  final Color? titleColor;
  final double? marginHorizontal;
  final double marginVertical;
  final bool showBanner;

  const TrucoDialog({
    super.key,
    this.title,
    this.content,
    this.contentText,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.spaceEvenly,
    this.toUpperCaseTitle = true,
    this.titleFontSize = 20,
    this.titleColor,
    this.marginHorizontal,
    this.marginVertical = 60,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    // El tema activo viene de un LiveDisplayScope ancestro si lo hay (p. ej.
    // el del anfitrión, en un diálogo de espectador); si no, del Provider
    // ambiental, como siempre.
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final theme = context.activeTheme(scoreProvider);
    final borderColor = theme.dialogBorderColor ?? theme.slate;
    const double borderWidth = 1.0;
    final isPremium = Provider.of<PremiumProvider>(context).isPremium;
    // The banner floats over the whole screen, independent of this dialog's
    // own scroll view — without shrinking the space available to it here,
    // a tall dialog's last bit of content can end up hidden behind the
    // banner even after scrolling all the way down. A short dialog just
    // ends up centered in a very slightly shorter box; no visible change.
    final bannerReserve = (showBanner && !isPremium) ? 100.0 : 0.0;

    final double effectiveWidth = marginHorizontal != null
        ? MediaQuery.of(context).size.width - (marginHorizontal! * 2)
        : MediaQuery.of(context).size.width * 0.9;

    return Material(
      color:
          Colors.transparent, // El overlay de showDialog maneja el fondo oscuro
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bannerReserve),
              child: Container(
                width: effectiveWidth,
                margin: EdgeInsets.symmetric(vertical: marginVertical),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.navy,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        toUpperCaseTitle ? title!.toUpperCase() : title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontSize: titleFontSize,
                          color: titleColor ?? Colors.white,
                          letterSpacing: 0,
                          fontWeight: toUpperCaseTitle
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (content != null) content!,
                    if (contentText != null)
                      Text(
                        contentText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    if (actions != null) ...[
                      const SizedBox(height: 32),
                      ...actions!,
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Banner fijo al pie de la pantalla (pegado al borde con SafeArea)
          if (showBanner)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                child: TrucoBannerAd(),
              ),
            ),
        ],
      ),
    );
  }
}
