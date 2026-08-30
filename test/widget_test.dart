import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truco_pro/models/match_record.dart';
import 'package:truco_pro/services/live_match_service.dart';
import 'package:truco_pro/services/persistence_service.dart';
import 'package:truco_pro/widgets/victory_share_card.dart';

void main() {
  MatchRecord record({required int target, required bool hasBuenas}) {
    return MatchRecord(
      id: 'partida-1',
      startedAt: DateTime(2026, 7, 20, 20),
      finishedAt: DateTime(2026, 7, 20, 21),
      nosotrosName: 'NOSOTROS',
      ellosName: 'ELLOS',
      nosotrosScore: target,
      ellosScore: hasBuenas ? 24 : 8,
      targetScore: target,
      hasBuenas: hasBuenas,
      winner: 'nosotros',
      events: const [],
    );
  }

  test('expresa el resultado en malas y buenas', () {
    final match = record(target: 30, hasBuenas: true);

    expect(match.formattedScore(30), '15 BUENAS');
    expect(match.formattedScore(24), '9 BUENAS');
    expect(match.formattedScore(12), '12 MALAS');
    expect(match.formattedScore(15), '0 BUENAS');
  });

  test('las modalidades sin buenas se muestran como malas', () {
    final match = record(target: 15, hasBuenas: false);

    expect(match.formattedScore(15), '15 MALAS');
    expect(match.formattedScore(8), '8 MALAS');
  });

  test('se serializa y recupera sin perder datos', () {
    final original = record(target: 30, hasBuenas: true);
    final decoded = MatchRecord.decode(original.encode());

    expect(decoded.id, original.id);
    expect(decoded.finishedAt, original.finishedAt);
    expect(decoded.winnerName, 'NOSOTROS');
    expect(decoded.formattedScore(decoded.ellosScore), '9 BUENAS');
  });

  test('lee el id de partida desde QR web, deep link o id directo', () {
    expect(
      LiveMatchService.parseMatchId(
        'https://martostudio.com/purotruco/live/abc_123-XYZ',
      ),
      'abc_123-XYZ',
    );
    expect(
      LiveMatchService.parseMatchId('purotruco://live/abc_123-XYZ'),
      'abc_123-XYZ',
    );
    expect(LiveMatchService.parseMatchId('abc_123-XYZ'), 'abc_123-XYZ');
    expect(
        LiveMatchService.parseMatchId('https://purotruco.app/foo/bar'), isNull);
  });

  test('deshacer una finalización revierte el contador sin bajar de cero',
      () async {
    SharedPreferences.setMockInitialValues({});

    await PersistenceService.decrementMatchesCompletedCount();
    expect(await PersistenceService.getMatchesCompletedCount(), 0);

    await PersistenceService.incrementMatchesCompletedCount();
    await PersistenceService.incrementMatchesCompletedCount();
    await PersistenceService.decrementMatchesCompletedCount();
    expect(await PersistenceService.getMatchesCompletedCount(), 1);
  });

  testWidgets('la tarjeta compartible no desborda con nombres largos',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: VictoryShareCard(
              winnerName: 'NOSOTROS CON UN NOMBRE MUY LARGO',
              nosotrosName: 'NOSOTROS CON UN NOMBRE MUY LARGO',
              ellosName: 'ELLOS CON OTRO NOMBRE EXTENSO',
              nosotrosResult: '15 BUENAS',
              ellosResult: '14 BUENAS',
              tagline: 'No apto para cardíacos',
              dateLabel: '20/07/2026 · 13:31',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);

    final ellos = tester.getCenter(find.byKey(const ValueKey('ellos-result')));
    final nosotros =
        tester.getCenter(find.byKey(const ValueKey('nosotros-result')));
    expect(ellos.dx, lessThan(nosotros.dx));
    expect(ellos.dy, closeTo(nosotros.dy, 1));
  });
}
