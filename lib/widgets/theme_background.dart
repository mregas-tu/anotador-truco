import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeBackground extends StatelessWidget {
  final TrucoTheme theme;
  final BoxFit fit;

  const ThemeBackground({
    super.key,
    required this.theme,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    switch (theme.backgroundType) {
      case ThemeBackgroundType.mate:
        return MateThemeBackground(theme: theme, fit: fit);
      case ThemeBackgroundType.generic:
        return GenericThemeBackground(theme: theme, fit: fit);
    }
  }
}

class GenericThemeBackground extends StatelessWidget {
  final TrucoTheme theme;
  final BoxFit fit;

  const GenericThemeBackground({
    super.key,
    required this.theme,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final asset = theme.backgroundAsset;
    if (asset == null) return const SizedBox.shrink();

    return _BackgroundImage(asset: asset, fit: fit);
  }
}

class MateThemeBackground extends StatelessWidget {
  final TrucoTheme theme;
  final BoxFit fit;

  const MateThemeBackground({
    super.key,
    required this.theme,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final asset = theme.backgroundAsset;
    if (asset == null) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: _BackgroundImage(asset: asset, fit: fit),
        ),
        const BackgroundAssetLayer(
          asset: 'assets/images/mate_top_objects_overlay.png',
          alignment: Alignment.topCenter,
          offset: Offset(0, -20),
          widthFactor: 1.0,
          rotation: 0.0,
          opacity: 0.92,
        ),
        const BackgroundAssetLayer(
          asset: 'assets/images/mate_corner_overlay.png',
          alignment: Alignment.bottomRight,
          offset: Offset(18, -12),
          widthFactor: 0.34,
          rotation: 0.0,
          opacity: 0.95,
        ),
      ],
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  final String asset;
  final BoxFit fit;

  const _BackgroundImage({
    required this.asset,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, fit: fit);
  }
}

class BackgroundAssetLayer extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  final Offset offset;
  final double? width;
  final double? height;
  final double? widthFactor;
  final double? heightFactor;
  final double rotation;
  final double opacity;
  final BoxFit fit;

  const BackgroundAssetLayer({
    super.key,
    required this.asset,
    required this.alignment,
    this.offset = Offset.zero,
    this.width,
    this.height,
    this.widthFactor,
    this.heightFactor,
    this.rotation = 0,
    this.opacity = 1,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width ??
            (widthFactor == null ? null : constraints.maxWidth * widthFactor!);
        final resolvedHeight = height ??
            (heightFactor == null
                ? null
                : constraints.maxHeight * heightFactor!);

        return Align(
          alignment: alignment,
          child: Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  asset,
                  width: resolvedWidth,
                  height: resolvedHeight,
                  fit: fit,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
