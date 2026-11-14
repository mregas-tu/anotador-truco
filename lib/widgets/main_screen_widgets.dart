import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/score_provider.dart';
import '../theme/app_theme.dart';
import '../theme/live_display_scope.dart';

Widget _centerOrnament(String asset) {
  if (asset.toLowerCase().endsWith('.svg')) {
    return SvgPicture.asset(asset, width: 56, height: 56);
  }
  return Image.asset(asset, width: 56, height: 56);
}

Widget _renderAsset(String asset, double height, ColorFilter? colorFilter) {
  if (asset.toLowerCase().endsWith('.svg')) {
    return SvgPicture.asset(asset, height: height, colorFilter: colorFilter);
  }
  final image = Image.asset(asset, height: height);
  if (colorFilter == null) return image;
  return ColorFiltered(colorFilter: colorFilter, child: image);
}

Widget assetWithShadows({
  required String asset,
  required double height,
  required ColorFilter? colorFilter,
  required List<Shadow>? shadows,
}) {
  final picture = _renderAsset(asset, height, colorFilter);
  if (shadows == null || shadows.isEmpty) return picture;
  return Stack(
    alignment: Alignment.center,
    children: [
      for (final s in shadows)
        Transform.translate(
          offset: s.offset,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: s.blurRadius,
              sigmaY: s.blurRadius,
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(s.color, BlendMode.srcIn),
              child: _renderAsset(asset, height, null),
            ),
          ),
        ),
      picture,
    ],
  );
}

class MainHeader extends StatelessWidget {
  final GlobalKey restartKey;
  final GlobalKey settingsKey;
  final VoidCallback onRestart;
  final VoidCallback onSettings;

  const MainHeader({
    super.key,
    required this.restartKey,
    required this.settingsKey,
    required this.onRestart,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final theme = context.activeTheme(scoreProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (theme.headerAsset != null)
          assetWithShadows(
            asset: theme.headerAsset!,
            height: 45,
            colorFilter: theme.tintHeader
                ? ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.8),
                    BlendMode.srcIn,
                  )
                : null,
            shadows: theme.headerShadows,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: restartKey,
                icon: Stack(
                  children: [
                    if (theme.teamNameShadow != null)
                      Positioned(
                        left: 1,
                        top: 1,
                        child: SvgPicture.asset(
                          'assets/images/restart.svg',
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              Colors.black45, BlendMode.srcIn),
                        ),
                      ),
                    SvgPicture.asset(
                      'assets/images/restart.svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.topIconColor ??
                            Colors.white.withValues(alpha: 0.7),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                onPressed: onRestart,
              ),
              IconButton(
                key: settingsKey,
                icon: Stack(
                  children: [
                    if (theme.teamNameShadow != null)
                      Positioned(
                        left: 1,
                        top: 1,
                        child: SvgPicture.asset(
                          'assets/images/settings.svg',
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              Colors.black45, BlendMode.srcIn),
                        ),
                      ),
                    SvgPicture.asset(
                      'assets/images/settings.svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.topIconColor ??
                            Colors.white.withValues(alpha: 0.7),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GhostHandOverlay extends StatelessWidget {
  final AnimationController controller;
  final Animation<Offset> moveAnimation;
  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;
  final bool useScale;

  const GhostHandOverlay({
    super.key,
    required this.controller,
    required this.moveAnimation,
    required this.opacityAnimation,
    required this.scaleAnimation,
    required this.useScale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = useScale ? scaleAnimation.value : 1.0;
        return Positioned(
          left: moveAnimation.value.dx,
          top: moveAnimation.value.dy,
          child: Opacity(
            opacity: opacityAnimation.value,
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: -0.2,
                child: SvgPicture.asset(
                  'assets/images/hand.svg',
                  height: 100,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CenterScoreCircle extends StatelessWidget {
  final GlobalKey limitScoreKey;
  final VoidCallback? onTap;

  const CenterScoreCircle({
    super.key,
    required this.limitScoreKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final theme = context.activeTheme(scoreProvider);
    final totalPoints = context.activeTotalPoints(scoreProvider);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
      padding: EdgeInsets.only(
        top: theme.centerSectionOffset,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: theme.centerCircleDecoration ??
                BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.centerCircleColor,
                  border: theme.hideCenterCircleBorder
                      ? null
                      : Border.all(
                          color: theme.accentColor
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                  boxShadow: !theme.hideCenterCircleBorder
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
          ),
          if (theme.centerOrnamentAsset != null)
            Transform.scale(
              scale: theme.centerOrnamentScale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (theme.centerOrnamentShadows != null)
                    ...theme.centerOrnamentShadows!
                        .map((s) => Transform.translate(
                              offset: s.offset,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    s.color, BlendMode.srcIn),
                                child: _centerOrnament(
                                  theme.centerOrnamentAsset!,
                                ),
                              ),
                            )),
                  _centerOrnament(theme.centerOrnamentAsset!),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              top: theme.scoreVerticalOffset > 0
                  ? theme.scoreVerticalOffset
                  : 0,
            ),
            child: Transform.translate(
              offset: Offset(
                0,
                theme.scoreVerticalOffset < 0
                    ? theme.scoreVerticalOffset
                    : 0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (theme.belowScoreAsset != null)
                    Transform.translate(
                      offset: Offset(
                          0, theme.belowScoreAssetOffset),
                      child: Image.asset(
                        theme.belowScoreAsset!,
                        height: theme.belowScoreAssetSize,
                      ),
                    ),
                  Text(
                    key: limitScoreKey,
                    "$totalPoints",
                    style: TextStyle(
                      fontFamily: AppFonts.caminito,
                      fontSize: theme.scoreFontSize,
                      color: theme.scoreColor,
                      fontWeight: FontWeight.bold,
                      shadows: theme.teamNameShadow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

