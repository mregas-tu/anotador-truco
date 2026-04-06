import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    // Buscamos el tema actual automáticamente vía Provider
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final borderColor = scoreProvider.appTheme.slate;
    const double borderWidth = 1.0;

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
              child: Container(
                width: effectiveWidth,
                margin: const EdgeInsets.symmetric(vertical: 60),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scoreProvider.appTheme.navy,
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

          // Banner fijo al pie de la pantalla
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: TrucoBannerAd(),
          ),
        ],
      ),
    );
  }
}
