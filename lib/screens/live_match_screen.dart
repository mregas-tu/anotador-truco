import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_match_state.dart';
import '../models/match_record.dart';
import '../providers/premium_provider.dart';
import '../providers/score_provider.dart';
import '../services/ad_service.dart';
import '../services/live_match_service.dart';
import '../services/persistence_service.dart';
import '../services/result_share_service.dart';
import '../theme/app_theme.dart';
import '../theme/live_display_scope.dart';
import '../widgets/main_screen_widgets.dart';
import '../widgets/theme_background.dart';
import '../widgets/truco_dialog.dart';
import '../widgets/truco_buttons.dart';
import '../widgets/matchstick_box.dart';
import '../widgets/matchstick_widget.dart';
import '../widgets/bean_widget.dart';

/// Reconstructs the host's visual choices (theme, fichas, palettes) from the
/// names published in [LiveMatchState], so the spectator sees an exact
/// reflection of the host's board instead of their own local settings.
extension LiveMatchDisplay on LiveMatchState {
  TrucoTheme resolveTheme() => TrucoTheme.allThemes.firstWhere(
        (t) => t.name == themeName,
        orElse: () => TrucoTheme.navyTheme,
      );

  PointType resolvePointType() =>
      pointType == PointType.beans.name ? PointType.beans : PointType.matches;

  MatchstickPalette resolveMatchstickPalette() => availablePalettes.firstWhere(
        (p) => p.name == paletteName,
        orElse: () => availablePalettes[1],
      );

  BeanPalette resolveBeanPalette() => availableBeanPalettes.firstWhere(
        (p) => p.name == paletteName,
        orElse: () => availableBeanPalettes[0],
      );
}

class LiveMatchViewerContent extends StatefulWidget {
  final String matchId;
  final VoidCallback onExit;

  const LiveMatchViewerContent({
    super.key,
    required this.matchId,
    required this.onExit,
  });

  @override
  State<LiveMatchViewerContent> createState() => _LiveMatchViewerContentState();
}

class _LiveMatchViewerContentState extends State<LiveMatchViewerContent> {
  bool _endedDialogShown = false;
  bool _finishedDialogShown = false;
  late final String _viewerId;

  @override
  void initState() {
    super.initState();
    _viewerId = LiveMatchService.generateViewerId();
    LiveMatchService.joinAsViewer(
      matchId: widget.matchId,
      viewerId: _viewerId,
    ).catchError((_) {});
  }

  @override
  void dispose() {
    LiveMatchService.leaveAsViewer(
      matchId: widget.matchId,
      viewerId: _viewerId,
    ).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackTheme = context.watch<ScoreProvider>().appTheme;

    return StreamBuilder<LiveMatchState?>(
      stream: LiveMatchService.watchMatch(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: fallbackTheme.cream),
          );
        }

        final state = snapshot.data;
        if (state == null) {
          return _ViewerMessage(
            icon: Icons.search_off,
            message: 'No encontramos esa partida.',
            theme: fallbackTheme,
          );
        }

        // Reflect the host's own theme, not the spectator's local one.
        final theme = state.resolveTheme();

        if (state.finished && !_finishedDialogShown) {
          _finishedDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showFinishedDialog(state, theme);
          });
        } else if (!state.isLive &&
            !_finishedDialogShown &&
            !_endedDialogShown) {
          _endedDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showEndedDialog(theme);
          });
        }

        return _LiveScoreBoard(
          matchId: widget.matchId,
          state: state,
          theme: theme,
          onExit: widget.onExit,
        );
      },
    );
  }

  Future<void> _showEndedDialog(TrucoTheme theme) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.navy,
        title: Text(
          'EL VIVO TERMINÓ',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            color: theme.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'El anfitrión dejó de transmitir esta partida.',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            // theme.slate can be identical to theme.navy (e.g. MALVINAS,
            // MATE), making this invisible against the dialog background.
            color: theme.cream.withValues(alpha: 0.75),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                color: theme.cream,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    widget.onExit();
  }

  void _showFinishedDialog(LiveMatchState state, TrucoTheme theme) {
    final winnerName = state.winnerName;
    bool matchSaved = false;

    final isPremium =
        Provider.of<PremiumProvider>(context, listen: false).isPremium;
    AdService.showInterstitial(
      isPremium: isPremium,
      source: 'spectator_game_finished',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LiveDisplayScope(
        theme: theme,
        pointType: state.resolvePointType(),
        matchstickPalette: state.resolveMatchstickPalette(),
        beanPalette: state.resolveBeanPalette(),
        totalPoints: state.targetScore,
        child: TrucoDialog(
          title: '¡Partida finalizada!',
          toUpperCaseTitle: false,
          titleFontSize: 20,
          titleColor: theme.cream,
          marginHorizontal: 50,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GANADOR',
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 20,
                  color: theme.cream,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  winnerName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 38,
                    color: theme.buenas,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _finalScoreColumn(state, 'nosotros', theme),
                  ),
                  Text(
                    '–',
                    style: TextStyle(
                      fontFamily: AppFonts.caminito,
                      fontSize: 38,
                      color: theme.cream,
                    ),
                  ),
                  Expanded(
                    child: _finalScoreColumn(state, 'ellos', theme),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                PrimaryButton(
                  text: 'Salir del vivo',
                  width: double.infinity,
                  fontSize: 16,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    widget.onExit();
                  },
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) => Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: matchSaved
                              ? 'Partida guardada'
                              : 'Guardar partida',
                          toUpperCase: false,
                          onPressed: () {
                            if (matchSaved) return;
                            _saveMatchToHistory(state);
                            setDialogState(() => matchSaved = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SecondaryButton(
                          text: 'Compartir',
                          toUpperCase: false,
                          iconAsset: 'assets/images/share_icon.svg',
                          onPressed: () => _shareLiveResult(state),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _finalScoreColumn(
    LiveMatchState state,
    String team,
    TrucoTheme theme,
  ) {
    final score = team == 'nosotros' ? state.nosotrosScore : state.ellosScore;
    final milestone = state.targetScore ~/ 2;
    final finishedMalas = state.finishedMalasFor(team);
    final isBuenas = ScorePhase.isBuenas(
      score: score,
      milestone: milestone,
      hasBuenas: state.hasBuenas,
      finishedMalas: finishedMalas,
    );
    final displayPoints = ScorePhase.displayPoints(
      score: score,
      milestone: milestone,
      hasBuenas: state.hasBuenas,
      finishedMalas: finishedMalas,
    );
    return Column(
      children: [
        Text(
          displayPoints.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: AppFonts.caminito,
            fontSize: 38,
            color: theme.cream,
          ),
        ),
        Text(
          isBuenas ? 'BUENAS' : 'MALAS',
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 14,
            color: isBuenas ? theme.buenas : theme.malas,
          ),
        ),
      ],
    );
  }

  Future<void> _saveMatchToHistory(LiveMatchState state) async {
    await PersistenceService.saveCompletedMatch(MatchRecord(
      id: state.id,
      startedAt: state.createdAt,
      finishedAt: state.updatedAt,
      nosotrosName: state.nosotrosName,
      ellosName: state.ellosName,
      nosotrosScore: state.nosotrosScore,
      ellosScore: state.ellosScore,
      targetScore: state.targetScore,
      hasBuenas: state.hasBuenas,
      winner: state.winner!,
      events: state.events
          .map((event) => MatchPointEvent(
                team: event.team,
                delta: event.delta,
                timestamp: event.timestamp,
                nosotrosTotal: event.nosotrosTotal,
                ellosTotal: event.ellosTotal,
              ))
          .toList(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partida guardada en tu historial.')),
    );
  }

  Future<void> _shareLiveResult(LiveMatchState state) async {
    await ResultShareService.shareCurrent(
      winnerName: state.winnerName,
      nosotrosName: state.nosotrosName,
      ellosName: state.ellosName,
      nosotrosScore: state.nosotrosScore,
      ellosScore: state.ellosScore,
      targetScore: state.targetScore,
      hasBuenas: state.hasBuenas,
    );
  }
}

class _LiveScoreBoard extends StatelessWidget {
  final String matchId;
  final LiveMatchState state;
  final TrucoTheme theme;
  final VoidCallback onExit;
  static final GlobalKey _historyKey = GlobalKey();

  const _LiveScoreBoard({
    required this.matchId,
    required this.state,
    required this.theme,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final totalRemaining =
        (state.targetScore * 2 - state.nosotrosScore - state.ellosScore)
            .clamp(0, state.targetScore * 2);

    return LiveDisplayScope(
      theme: theme,
      pointType: state.resolvePointType(),
      matchstickPalette: state.resolveMatchstickPalette(),
      beanPalette: state.resolveBeanPalette(),
      totalPoints: state.targetScore,
      child: Stack(
        children: [
          // Themes without a background image (e.g. NAVY PROFUNDO) render
          // nothing here, so this solid layer guarantees the host's own
          // color always shows through instead of the outer Scaffold's.
          Positioned.fill(child: Container(color: theme.navy)),
          Positioned.fill(child: ThemeBackground(theme: theme)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _LiveHeader(
                  theme: theme,
                  onExit: () => _confirmExit(context),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LiveTeamColumn(
                              name: state.nosotrosName,
                              points: state.nosotrosScore,
                              state: state,
                              isNosotros: true,
                            ),
                          ),
                          Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 1,
                                  color:
                                      theme.dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              SizedBox(
                                height: 10 +
                                    (theme.footerAsset != null
                                        ? theme.footerHeight
                                        : 0) +
                                    20,
                              ),
                            ],
                          ),
                          Expanded(
                            child: _LiveTeamColumn(
                              name: state.ellosName,
                              points: state.ellosScore,
                              state: state,
                              isNosotros: false,
                            ),
                          ),
                        ],
                      ),
                      CenterScoreCircle(
                        limitScoreKey: _historyKey,
                        onTap: () => _showLiveHistory(context, state, theme),
                      ),
                      if (theme.footerAsset != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: assetWithShadows(
                                  asset: theme.footerAsset!,
                                  height: theme.footerHeight,
                                  colorFilter: theme.tintFooter
                                      ? ColorFilter.mode(
                                          Colors.white.withValues(alpha: 0.8),
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                  shadows: theme.footerShadows,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height:
                        (theme.footerAsset != null ? theme.footerHeight : 0) +
                            20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: MatchstickBox(count: totalRemaining),
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

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => LiveDisplayScope(
        theme: theme,
        pointType: state.resolvePointType(),
        matchstickPalette: state.resolveMatchstickPalette(),
        beanPalette: state.resolveBeanPalette(),
        totalPoints: state.targetScore,
        child: TrucoDialog(
          title: 'Salir del vivo',
          contentText: '¿Querés dejar de ver esta partida en vivo?',
          actions: [
            SecondaryButton(
              text: 'Cancelar',
              width: double.infinity,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: 'Salir',
              width: double.infinity,
              onPressed: () {
                Navigator.pop(dialogContext);
                onExit();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveHistory(
    BuildContext context,
    LiveMatchState initialState,
    TrucoTheme theme,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => LiveDisplayScope(
        theme: theme,
        pointType: initialState.resolvePointType(),
        matchstickPalette: initialState.resolveMatchstickPalette(),
        beanPalette: initialState.resolveBeanPalette(),
        totalPoints: initialState.targetScore,
        child: TrucoDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      'PUNTOS ANOTADOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.cream,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: theme.cream),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: StreamBuilder<LiveMatchState?>(
                  stream: LiveMatchService.watchMatch(matchId),
                  initialData: initialState,
                  builder: (context, snapshot) {
                    final liveState = snapshot.data ?? initialState;
                    return SingleChildScrollView(
                      child: _buildHistoryContent(liveState, theme),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(LiveMatchState state, TrucoTheme theme) {
    final historyNow = DateTime.now();
    if (state.events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'Todavía no hay puntos anotados',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 14,
            color: theme.teamNameColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final reversedEvents = state.events.reversed.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < reversedEvents.length; i++) ...[
          if (i > 0)
            _buildHistoryDivider(
              reversedEvents[i - 1],
              reversedEvents[i],
              theme,
              historyNow,
            ),
          _buildHistoryRow(reversedEvents[i], state, theme, historyNow),
        ],
      ],
    );
  }

  Widget _buildHistoryRow(
    LiveMatchPointEvent event,
    LiveMatchState state,
    TrucoTheme theme,
    DateTime historyNow,
  ) {
    final teamName =
        event.team == 'nosotros' ? state.nosotrosName : state.ellosName;
    final action = event.delta > 0 ? 'sumó' : 'restó';
    final points = event.delta.abs();
    final pointsLabel = points == 1 ? 'punto' : 'puntos';
    final deltaStr = event.delta > 0 ? '+$points' : '-$points';
    final timeStr = _formatHistoryTime(event.timestamp, historyNow);
    final actionColor = event.delta > 0 ? theme.buenas : theme.malas;
    final nosotrosAfter = _formatHistoryScore(event.nosotrosTotal, state);
    final ellosAfter = _formatHistoryScore(event.ellosTotal, state);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              timeStr,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 11,
                color: theme.teamNameColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teamName $action $points $pointsLabel',
                  style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.teamNameColor,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 12,
                      color: theme.teamNameColor.withValues(alpha: 0.55),
                    ),
                    children: [
                      const TextSpan(text: 'Quedó '),
                      TextSpan(
                        text: nosotrosAfter,
                        style: TextStyle(
                          fontWeight: event.team == 'nosotros'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: event.team == 'nosotros' ? actionColor : null,
                        ),
                      ),
                      const TextSpan(text: ' - '),
                      TextSpan(
                        text: ellosAfter,
                        style: TextStyle(
                          fontWeight: event.team == 'ellos'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: event.team == 'ellos' ? actionColor : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: actionColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              deltaStr,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDivider(
    LiveMatchPointEvent previousEvent,
    LiveMatchPointEvent currentEvent,
    TrucoTheme theme,
    DateTime historyNow,
  ) {
    final sameTimeLabel =
        _formatHistoryTime(previousEvent.timestamp, historyNow) ==
            _formatHistoryTime(currentEvent.timestamp, historyNow);

    return Divider(
      color: theme.teamNameColor.withValues(alpha: sameTimeLabel ? 0.1 : 0.34),
      thickness: sameTimeLabel ? 0.5 : 1.25,
      height: sameTimeLabel ? 1 : 14,
    );
  }

  String _formatHistoryTime(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Recién';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatHistoryScore(int total, LiveMatchState state) {
    if (!state.hasBuenas || total == 0) return total.toString().padLeft(2, '0');

    final milestone = state.targetScore ~/ 2;
    if (total <= milestone) return '${total.toString().padLeft(2, '0')} MALAS';

    final buenas = (total - milestone).clamp(0, milestone);
    return '${buenas.toString().padLeft(2, '0')} BUENAS';
  }
}

class _LiveHeader extends StatelessWidget {
  final TrucoTheme theme;
  final VoidCallback onExit;

  const _LiveHeader({
    required this.theme,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
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
                tooltip: 'Salir del vivo',
                icon: Icon(
                  Icons.logout,
                  color:
                      theme.topIconColor ?? Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: onExit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveTeamColumn extends StatelessWidget {
  final String name;
  final int points;
  final LiveMatchState state;
  final bool isNosotros;

  const _LiveTeamColumn({
    required this.name,
    required this.points,
    required this.state,
    required this.isNosotros,
  });

  @override
  Widget build(BuildContext context) {
    final theme = state.resolveTheme();
    final teamKey = isNosotros ? 'nosotros' : 'ellos';
    final milestone = state.targetScore ~/ 2;
    final finishedMalas = state.finishedMalasFor(teamKey);
    final isBuenas = ScorePhase.isBuenas(
      score: points,
      milestone: milestone,
      hasBuenas: state.hasBuenas,
      finishedMalas: finishedMalas,
    );
    final displayPoints = ScorePhase.displayPoints(
      score: points,
      milestone: milestone,
      hasBuenas: state.hasBuenas,
      finishedMalas: finishedMalas,
    );
    final label = isBuenas ? 'BUENAS' : 'MALAS';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: isNosotros ? theme.nosotrosMarginRight : 0.0,
            left: !isNosotros ? theme.ellosMarginLeft : 0.0,
          ),
          child: Column(
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                width: double.infinity,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 20,
                      color: theme.teamNameColor,
                      fontWeight: FontWeight.bold,
                      shadows: theme.teamNameShadow,
                    ),
                  ),
                ),
              ),
              Text(
                displayPoints.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: AppFonts.caminito,
                  fontSize: 32,
                  color: theme.teamScoreColor,
                  shadows: theme.teamNameShadow,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.oswald,
                  fontSize: 16,
                  color: isBuenas ? theme.buenas : theme.malas,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final totalInPhase = displayPoints;
            final groups = (state.targetScore / (state.hasBuenas ? 10 : 5))
                .ceil()
                .clamp(1, 8);
            final effectiveWidth = constraints.maxWidth -
                (isNosotros
                    ? theme.nosotrosMarginRight
                    : theme.ellosMarginLeft);
            final slotSize = (constraints.maxHeight / groups)
                .clamp(60.0, effectiveWidth < 60.0 ? 60.0 : effectiveWidth);
            final groupOffset = isBuenas ? groups : 0;

            return Padding(
              padding: EdgeInsets.only(
                right: isNosotros ? theme.nosotrosMarginRight : 0.0,
                left: !isNosotros ? theme.ellosMarginLeft : 0.0,
              ),
              child: Column(
                children: List.generate(groups, (groupIndex) {
                  final pointsInGroup =
                      (totalInPhase - (groupIndex * 5)).clamp(0, 5);
                  return Expanded(
                    child: Center(
                      child: pointsInGroup > 0
                          ? _LiveScoreGroup(
                              points: pointsInGroup,
                              size: slotSize * 0.9,
                              team: teamKey,
                              groupIndex: groupIndex + groupOffset,
                              state: state,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
        SizedBox(
          height:
              10 + (theme.footerAsset != null ? theme.footerHeight : 0) + 20,
        ),
      ],
    );
  }
}

class _LiveScoreGroup extends StatelessWidget {
  final int points;
  final double size;
  final String team;
  final int groupIndex;
  final LiveMatchState state;

  const _LiveScoreGroup({
    required this.points,
    required this.size,
    required this.team,
    required this.groupIndex,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final padding = size * 0.05;
    final thickness = size * 0.1;
    final matchHeight = size * 0.85;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 1; i <= 5; i++)
            if (points >= i) _positionPiece(i, padding, thickness, matchHeight),
        ],
      ),
    );
  }

  Widget _positionPiece(int i, double p, double thickness, double matchHeight) {
    final content = _piece(i, matchHeight);
    if (state.resolvePointType() == PointType.beans) {
      final offsets = [
        Offset(size * 0.2, size * 0.55),
        Offset(size * 0.25, size * 0.2),
        Offset(size * 0.5, size * 0.55),
        Offset(size * 0.55, size * 0.2),
        Offset(size * 0.35, size * 0.38),
      ];
      return Positioned(
        left: offsets[i - 1].dx,
        top: offsets[i - 1].dy,
        child: content,
      );
    }

    if (i == 5) {
      return Positioned.fill(child: Center(child: content));
    }

    return Positioned(
      left: i == 1 || i == 2 || i == 4 ? p : null,
      right: i == 2 || i == 3 || i == 4 ? p : null,
      top: i == 1 || i == 2 || i == 3 ? p : null,
      bottom: i == 1 || i == 3 || i == 4 ? p : null,
      width: (i == 1 || i == 3) ? thickness : null,
      height: (i == 2 || i == 4) ? thickness : null,
      child: content,
    );
  }

  Widget _piece(int i, double matchHeight) {
    if (state.resolvePointType() == PointType.beans) {
      final angle = [0.2, -0.15, 0.4, -0.3, 0.05][i % 5];
      return Transform.rotate(
        angle: angle,
        child: BeanWidget(
          size: size * 0.3,
          seed: groupIndex * 5 + i,
          beanType: state.resolveBeanPalette().type,
        ),
      );
    }
    return MatchstickWidget(
      height: matchHeight,
      width: size * 0.1,
      horizontal: i == 2 || i == 4,
      flipped: i == 3 || i == 4,
      diagonal: i == 5,
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final TrucoTheme theme;

  const _ViewerMessage({
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.cream, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              color: theme.cream,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
