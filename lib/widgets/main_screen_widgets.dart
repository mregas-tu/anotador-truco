import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/score_provider.dart';
import '../theme/app_theme.dart';

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

    return Stack(
      alignment: Alignment.center,
      children: [
        if (scoreProvider.appTheme.headerAsset != null)
          assetWithShadows(
            asset: scoreProvider.appTheme.headerAsset!,
            height: 45,
            colorFilter: scoreProvider.appTheme.tintHeader
                ? ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.8),
                    BlendMode.srcIn,
                  )
                : null,
            shadows: scoreProvider.appTheme.headerShadows,
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
                    if (scoreProvider.appTheme.teamNameShadow != null)
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
                        scoreProvider.appTheme.topIconColor ??
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
                    if (scoreProvider.appTheme.teamNameShadow != null)
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
                        scoreProvider.appTheme.topIconColor ??
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

  const CenterScoreCircle({
    super.key,
    required this.limitScoreKey,
  });

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        top: scoreProvider.appTheme.centerSectionOffset,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: scoreProvider.appTheme.centerCircleDecoration ??
                BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreProvider.appTheme.centerCircleColor,
                  border: scoreProvider.appTheme.hideCenterCircleBorder
                      ? null
                      : Border.all(
                          color: scoreProvider.appTheme.accentColor
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                  boxShadow: !scoreProvider.appTheme.hideCenterCircleBorder
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
          if (scoreProvider.appTheme.centerOrnamentAsset != null)
            Transform.scale(
              scale: scoreProvider.appTheme.centerOrnamentScale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (scoreProvider.appTheme.centerOrnamentShadows != null)
                    ...scoreProvider.appTheme.centerOrnamentShadows!
                        .map((s) => Transform.translate(
                              offset: s.offset,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    s.color, BlendMode.srcIn),
                                child: _centerOrnament(
                                  scoreProvider.appTheme.centerOrnamentAsset!,
                                ),
                              ),
                            )),
                  _centerOrnament(scoreProvider.appTheme.centerOrnamentAsset!),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              top: scoreProvider.appTheme.scoreVerticalOffset > 0
                  ? scoreProvider.appTheme.scoreVerticalOffset
                  : 0,
            ),
            child: Transform.translate(
              offset: Offset(
                0,
                scoreProvider.appTheme.scoreVerticalOffset < 0
                    ? scoreProvider.appTheme.scoreVerticalOffset
                    : 0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (scoreProvider.appTheme.belowScoreAsset != null)
                    Transform.translate(
                      offset: Offset(
                          0, scoreProvider.appTheme.belowScoreAssetOffset),
                      child: Image.asset(
                        scoreProvider.appTheme.belowScoreAsset!,
                        height: scoreProvider.appTheme.belowScoreAssetSize,
                      ),
                    ),
                  Text(
                    key: limitScoreKey,
                    "${scoreProvider.currentGameMode.totalPoints}",
                    style: TextStyle(
                      fontFamily: AppFonts.caminito,
                      fontSize: scoreProvider.appTheme.scoreFontSize,
                      color: scoreProvider.appTheme.scoreColor,
                      fontWeight: FontWeight.bold,
                      shadows: scoreProvider.appTheme.teamNameShadow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
