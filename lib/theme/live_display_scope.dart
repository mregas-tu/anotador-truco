import 'package:flutter/material.dart';

import '../providers/score_provider.dart';
import 'app_theme.dart';

/// Bundles the visual choices (theme, fichas) that a spectator's view
/// should mirror from the host, instead of the viewer's own local
/// [ScoreProvider] settings. Wrap it once around a subtree — the live
/// scoreboard, or a dialog opened from it — and every descendant, now or
/// added later, picks it up automatically via [BuildContext.activeTheme]
/// and friends below, instead of needing its own override parameter.
///
/// Not present outside a live spectator context, in which case those
/// helpers fall back to the ambient [ScoreProvider]'s own settings.
class LiveDisplayScope extends InheritedWidget {
  final TrucoTheme theme;
  final PointType pointType;
  final MatchstickPalette matchstickPalette;
  final BeanPalette beanPalette;
  final int totalPoints;

  const LiveDisplayScope({
    super.key,
    required this.theme,
    required this.pointType,
    required this.matchstickPalette,
    required this.beanPalette,
    required this.totalPoints,
    required super.child,
  });

  static LiveDisplayScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiveDisplayScope>();

  @override
  bool updateShouldNotify(LiveDisplayScope oldWidget) {
    return theme != oldWidget.theme ||
        pointType != oldWidget.pointType ||
        matchstickPalette != oldWidget.matchstickPalette ||
        beanPalette != oldWidget.beanPalette ||
        totalPoints != oldWidget.totalPoints;
  }
}

extension ActiveDisplay on BuildContext {
  TrucoTheme activeTheme(ScoreProvider scoreProvider) =>
      LiveDisplayScope.maybeOf(this)?.theme ?? scoreProvider.appTheme;

  PointType activePointType(ScoreProvider scoreProvider) =>
      LiveDisplayScope.maybeOf(this)?.pointType ?? scoreProvider.pointType;

  MatchstickPalette activeMatchstickPalette(ScoreProvider scoreProvider) =>
      LiveDisplayScope.maybeOf(this)?.matchstickPalette ??
      scoreProvider.currentPalette;

  BeanPalette activeBeanPalette(ScoreProvider scoreProvider) =>
      LiveDisplayScope.maybeOf(this)?.beanPalette ??
      scoreProvider.currentBeanPalette;

  int activeTotalPoints(ScoreProvider scoreProvider) =>
      LiveDisplayScope.maybeOf(this)?.totalPoints ??
      scoreProvider.currentGameMode.totalPoints;
}
