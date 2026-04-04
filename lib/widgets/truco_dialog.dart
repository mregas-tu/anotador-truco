import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'truco_banner_ad.dart';

class TrucoDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? contentText;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;
  final Color? borderColor;
  final double borderWidth;

  const TrucoDialog({
    super.key,
    this.title,
    this.content,
    this.contentText,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.spaceEvenly,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Background mask is handled by showDialog
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                margin: const EdgeInsets.symmetric(vertical: 60),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161931),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: borderColor ?? Colors.white.withOpacity(0.15),
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
                        title!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
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

          // El banner FIXED al pie de la pantalla, fuera del cuadro azul
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
