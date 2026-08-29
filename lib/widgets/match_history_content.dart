import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match_record.dart';
import '../providers/score_provider.dart';
import '../services/analytics_service.dart';
import '../services/persistence_service.dart';
import '../services/result_share_service.dart';
import '../theme/app_theme.dart';
import 'truco_buttons.dart';

class MatchHistoryContent extends StatefulWidget {
  final ValueChanged<VoidCallback?>? onBackActionChanged;

  const MatchHistoryContent({super.key, this.onBackActionChanged});

  @override
  State<MatchHistoryContent> createState() => _MatchHistoryContentState();
}

class _MatchHistoryContentState extends State<MatchHistoryContent> {
  late Future<List<MatchRecord>> _history;
  MatchRecord? _selected;

  @override
  void initState() {
    super.initState();
    _history = _loadAndTrackHistory();
  }

  Future<List<MatchRecord>> _loadAndTrackHistory() async {
    final records = await PersistenceService.loadMatchHistory();
    await AnalyticsService.logMatchHistoryOpened(
      savedMatches: records.length,
    );
    return records;
  }

  void _reload() {
    _history = PersistenceService.loadMatchHistory();
  }

  void _showList() {
    setState(() => _selected = null);
    widget.onBackActionChanged?.call(null);
  }

  void _showDetail(MatchRecord record) {
    AnalyticsService.logMatchHistoryDetailOpened(
      daysSinceMatch: _daysSince(record),
      targetScore: record.targetScore,
      hasBuenas: record.hasBuenas,
    );
    setState(() => _selected = record);
    widget.onBackActionChanged?.call(_showList);
  }

  String _dateLabel(DateTime value) {
    final date = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final prefix = day == today
        ? 'HOY'
        : day == today.subtract(const Duration(days: 1))
            ? 'AYER'
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return '$prefix · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _delete(MatchRecord record) async {
    await PersistenceService.deleteCompletedMatch(record.id);
    await AnalyticsService.logMatchHistoryMatchDeleted(
      daysSinceMatch: _daysSince(record),
    );
    if (!mounted) return;
    setState(() {
      _selected = null;
      _reload();
    });
    widget.onBackActionChanged?.call(null);
  }

  int _daysSince(MatchRecord record) {
    final days = DateTime.now().difference(record.finishedAt).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final contentHeight = (screenHeight * 0.55).clamp(300.0, 420.0);

    if (_selected != null) {
      return _buildDetail(context, _selected!);
    }

    return SizedBox(
      height: contentHeight,
      child: _buildHistoryList(context),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final colors = _HistoryColors.of(context);
    return FutureBuilder<List<MatchRecord>>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final records = snapshot.data ?? const <MatchRecord>[];
        if (records.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 48, color: colors.muted),
                  const SizedBox(height: 14),
                  Text(
                    'TODAVÍA NO TERMINASTE\nNINGUNA PARTIDA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 16,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final record = records[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDetail(record),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _dateLabel(record.finishedAt),
                      style: TextStyle(
                        fontFamily: AppFonts.oswald,
                        fontSize: 11,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _teamLine(
                        record.nosotrosName,
                        record.formattedScore(record.nosotrosScore),
                        record.winner == 'nosotros',
                        colors),
                    const SizedBox(height: 6),
                    _teamLine(
                        record.ellosName,
                        record.formattedScore(record.ellosScore),
                        record.winner == 'ellos',
                        colors),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _teamLine(
      String name, String score, bool winner, _HistoryColors colors) {
    return Row(
      children: [
        if (winner) ...[
          Icon(Icons.emoji_events, size: 16, color: colors.accent),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontWeight: winner ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
              color: colors.text,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _scoreColor(score, colors),
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context, MatchRecord record) {
    final colors = _HistoryColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 500),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_dateLabel(record.finishedAt),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppFonts.oswald,
                    fontSize: 12,
                    color: colors.muted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, size: 28, color: colors.accent),
                  const SizedBox(height: 5),
                  Text('GANÓ ${record.winnerName.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: colors.accent)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _detailTeam(
                          record.ellosName,
                          record.formattedScore(record.ellosScore),
                          record.winner == 'ellos',
                          colors,
                        ),
                      ),
                      Container(width: 1, height: 54, color: colors.border),
                      Expanded(
                        child: _detailTeam(
                          record.nosotrosName,
                          record.formattedScore(record.nosotrosScore),
                          record.winner == 'nosotros',
                          colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'COMPARTIR RESULTADO',
              width: double.infinity,
              iconAsset: 'assets/images/share_icon.svg',
              onPressed: () {
                AnalyticsService.logMatchHistoryResultShared(
                  daysSinceMatch: _daysSince(record),
                  targetScore: record.targetScore,
                  hasBuenas: record.hasBuenas,
                );
                ResultShareService.shareRecord(record);
              },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _confirmDelete(context, record),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('ELIMINAR PARTIDA',
                  style: TextStyle(
                      fontFamily: AppFonts.oswald, color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTeam(
      String name, String score, bool winner, _HistoryColors colors) {
    return Column(
      children: [
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: 14,
            fontWeight: winner ? FontWeight.bold : FontWeight.normal,
            color: winner ? colors.text : colors.muted,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            score,
            style: TextStyle(
              fontFamily: AppFonts.oswald,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _scoreColor(score, colors),
            ),
          ),
        ),
      ],
    );
  }

  Color _scoreColor(String score, _HistoryColors colors) =>
      score.endsWith('BUENAS') ? colors.buenas : colors.malas;

  Future<void> _confirmDelete(BuildContext context, MatchRecord record) async {
    final colors = _HistoryColors.of(context);
    AnalyticsService.logMatchHistoryDeleteRequested(
      daysSinceMatch: _daysSince(record),
    );
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Provider.of<ScoreProvider>(dialogContext, listen: false)
                    .appTheme
                    .navy,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 27),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿ELIMINAR ESTA PARTIDA?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta acción no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 14,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.text,
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('CANCELAR',
                              style: TextStyle(fontFamily: AppFonts.oswald)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('ELIMINAR',
                              style: TextStyle(fontFamily: AppFonts.oswald)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (confirmed) await _delete(record);
  }
}

class _HistoryColors {
  final Color text;
  final Color muted;
  final Color accent;
  final Color buenas;
  final Color malas;
  final Color card;
  final Color border;

  const _HistoryColors(
      {required this.text,
      required this.muted,
      required this.accent,
      required this.buenas,
      required this.malas,
      required this.card,
      required this.border});

  factory _HistoryColors.of(BuildContext context) {
    final theme = Provider.of<ScoreProvider>(context, listen: false).appTheme;
    final text = _mostReadableOn(theme.navy, [theme.cream, Colors.white]);
    final muted = Color.lerp(theme.navy, text, 0.68)!;
    final accent = _hasEnoughContrast(theme.accentColor, theme.navy)
        ? theme.accentColor
        : text;
    final buenas =
        _hasEnoughContrast(theme.buenas, theme.navy) ? theme.buenas : text;
    final malas =
        _hasEnoughContrast(theme.malas, theme.navy) ? theme.malas : text;

    return _HistoryColors(
      text: text,
      muted: muted,
      accent: accent,
      buenas: buenas,
      malas: malas,
      card: Colors.white.withValues(alpha: 0.045),
      border: text.withValues(alpha: 0.14),
    );
  }

  static Color _mostReadableOn(Color background, List<Color> candidates) {
    return candidates.reduce(
      (best, candidate) =>
          _contrast(candidate, background) > _contrast(best, background)
              ? candidate
              : best,
    );
  }

  static bool _hasEnoughContrast(Color foreground, Color background) =>
      _contrast(foreground, background) >= 3;

  static double _contrast(Color first, Color second) {
    final lighter = first.computeLuminance() > second.computeLuminance()
        ? first.computeLuminance()
        : second.computeLuminance();
    final darker = first.computeLuminance() < second.computeLuminance()
        ? first.computeLuminance()
        : second.computeLuminance();
    return (lighter + 0.05) / (darker + 0.05);
  }
}
