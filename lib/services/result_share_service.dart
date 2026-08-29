import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/match_record.dart';
import '../widgets/victory_share_card.dart';
import 'analytics_service.dart';
import 'support_service.dart';

class ResultShareService {
  static final Random _random = Random();

  static const List<String> _onePointTaglines = [
    'No apto para cardíacos',
    'Se definió en la última',
    'Final para el infarto',
    'Se ganó con lo justo',
  ];

  static const List<String> _closeGameTaglines = [
    'Partidazo hasta el final',
    'Se peleó hasta el final',
    'Pura tensión hasta el cierre',
    'Qué manera de sufrir',
  ];

  static const List<String> _dominantWinTaglines = [
    'Victoria contundente',
    'Victoria sin discusión',
    'El otro equipo ni jugó',
    'Partida sin oposición',
    'Una paliza inolvidable',
  ];

  static const List<String> _generalWinTaglines = [
    '¡Qué manera de ganar!',
    'La victoria tiene dueño',
    'Una victoria para recordar',
    'Así se gana una partida',
  ];

  static Future<void> shareRecord(MatchRecord record) async {
    final dateLabel = _formatDate(record.finishedAt);
    await _share(
      winnerName: record.winnerName,
      nosotrosName: record.nosotrosName,
      ellosName: record.ellosName,
      nosotrosResult: record.formattedScore(record.nosotrosScore),
      ellosResult: record.formattedScore(record.ellosScore),
      tagline: _taglineFor(
        winnerScore: record.winner == 'nosotros'
            ? record.nosotrosScore
            : record.ellosScore,
        loserScore: record.winner == 'nosotros'
            ? record.ellosScore
            : record.nosotrosScore,
        targetScore: record.targetScore,
        hasBuenas: record.hasBuenas,
      ),
      dateLabel: dateLabel,
    );
  }

  static Future<void> shareCurrent({
    required String winnerName,
    required String nosotrosName,
    required String ellosName,
    required int nosotrosScore,
    required int ellosScore,
    required int targetScore,
    required bool hasBuenas,
  }) async {
    final temporaryRecord = MatchRecord(
      id: '',
      startedAt: DateTime.now(),
      finishedAt: DateTime.now(),
      nosotrosName: nosotrosName,
      ellosName: ellosName,
      nosotrosScore: nosotrosScore,
      ellosScore: ellosScore,
      targetScore: targetScore,
      hasBuenas: hasBuenas,
      winner: nosotrosScore == targetScore ? 'nosotros' : 'ellos',
      events: const [],
    );
    await _share(
      winnerName: winnerName,
      nosotrosName: nosotrosName,
      ellosName: ellosName,
      nosotrosResult: temporaryRecord.formattedScore(nosotrosScore),
      ellosResult: temporaryRecord.formattedScore(ellosScore),
      tagline: _taglineFor(
        winnerScore: targetScore,
        loserScore: nosotrosScore == targetScore ? ellosScore : nosotrosScore,
        targetScore: targetScore,
        hasBuenas: hasBuenas,
      ),
      dateLabel: _formatDate(DateTime.now()),
    );
  }

  static Future<void> _share({
    required String winnerName,
    required String nosotrosName,
    required String ellosName,
    required String nosotrosResult,
    required String ellosResult,
    required String tagline,
    String? dateLabel,
  }) async {
    final controller = ScreenshotController();
    final Uint8List imageBytes = await controller.captureFromWidget(
      VictoryShareCard(
        winnerName: winnerName,
        nosotrosName: nosotrosName,
        ellosName: ellosName,
        nosotrosResult: nosotrosResult,
        ellosResult: ellosResult,
        tagline: tagline,
        dateLabel: dateLabel,
      ),
      delay: const Duration(milliseconds: 100),
    );
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/resultado_truco.png';
    await File(path).writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(path)],
      text: '#AnotadorDeTruco\n${SupportService.appUrl}',
    );
    AnalyticsService.logShareGameResult();
  }

  static String _taglineFor({
    required int winnerScore,
    required int loserScore,
    required int targetScore,
    required bool hasBuenas,
  }) {
    final difference = winnerScore - loserScore;
    if (difference == 1) return _pick(_onePointTaglines);
    if (difference <= 3) return _pick(_closeGameTaglines);
    if (hasBuenas && loserScore < targetScore ~/ 2) {
      return _pick(_dominantWinTaglines);
    }
    return _pick(_generalWinTaglines);
  }

  static String _pick(List<String> options) =>
      options[_random.nextInt(options.length)];

  static String _formatDate(DateTime value) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    final date = value.toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$minute';
  }
}
