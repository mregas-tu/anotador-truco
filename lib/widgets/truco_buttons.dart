import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../providers/score_provider.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final String? iconAsset;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 40.0,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ScoreProvider>(context).appTheme;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryBackgroundButton,
          foregroundColor: theme.primaryTextButton,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null) ...[
              SvgPicture.asset(
                iconAsset!,
                height: 18,
                colorFilter: ColorFilter.mode(theme.primaryTextButton, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SecondaryButtonType { primary, secondary }

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final SecondaryButtonType type;
  final String? iconAsset;
  final bool toUpperCase;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 40.0,
    this.type = SecondaryButtonType.primary,
    this.iconAsset,
    this.toUpperCase = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ScoreProvider>(context).appTheme;
    
    // Determine colors based on type
    final Color borderColor = type == SecondaryButtonType.secondary 
        ? theme.malas 
        : theme.secondaryButtonBorder;
        
    final Color textColor = type == SecondaryButtonType.secondary 
        ? theme.malas 
        : theme.secondaryButtonText;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null) ...[
              SvgPicture.asset(
                iconAsset!,
                height: 18,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              toUpperCase ? text.toUpperCase() : text,
              style: const TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
