import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VictoryShareCard extends StatelessWidget {
  final String winnerName;
  final String nosotrosName;
  final String ellosName;
  final String nosotrosResult;
  final String ellosResult;
  final String tagline;
  final String? dateLabel;

  const VictoryShareCard({
    super.key,
    required this.winnerName,
    required this.nosotrosName,
    required this.ellosName,
    required this.nosotrosResult,
    required this.ellosResult,
    required this.tagline,
    this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    const theme = TrucoTheme.navyTheme;
    final winnerIsNosotros =
        winnerName.toUpperCase() == nosotrosName.toUpperCase();

    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.noScaling),
      child: Container(
        width: 400,
        height: 550,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.navy,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(52),
                  child: Opacity(
                    opacity: 0.10,
                    child: Image.asset(
                      'assets/images/markwatter.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 32, 34, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'PURO TRUCO',
                      style: TextStyle(
                        fontFamily: AppFonts.caminito,
                        fontSize: 38,
                        color: theme.cream,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PARTIDA FINALIZADA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.oswald,
                      fontSize: 12,
                      color: theme.cream.withValues(alpha: 0.48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: theme.cream.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: theme.accentColor,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'GANÓ',
                            style: TextStyle(
                              fontFamily: AppFonts.oswald,
                              fontSize: 13,
                              color: theme.cream.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                winnerName.toUpperCase(),
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: AppFonts.oswald,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.cream,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 110,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _TeamResult(
                                    key: const ValueKey('ellos-result'),
                                    name: ellosName,
                                    result: ellosResult,
                                    highlighted: !winnerIsNosotros,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 9),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color:
                                            theme.cream.withValues(alpha: 0.12),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        child: Text(
                                          'VS',
                                          style: TextStyle(
                                            fontFamily: AppFonts.oswald,
                                            fontSize: 10,
                                            color: theme.cream
                                                .withValues(alpha: 0.32),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 34,
                                        color:
                                            theme.cream.withValues(alpha: 0.12),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _TeamResult(
                                    key: const ValueKey('nosotros-result'),
                                    name: nosotrosName,
                                    result: nosotrosResult,
                                    highlighted: winnerIsNosotros,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 210,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tagline.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppFonts.oswald,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.cream.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Divider(
                          color: theme.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      if (dateLabel != null)
                        Text(
                          dateLabel!,
                          style: TextStyle(
                            fontFamily: AppFonts.oswald,
                            fontSize: 9,
                            color: theme.cream.withValues(alpha: 0.42),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '¿SALE REVANCHA?',
                        style: TextStyle(
                          fontFamily: AppFonts.oswald,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.cream.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamResult extends StatelessWidget {
  final String name;
  final String result;
  final bool highlighted;

  const _TeamResult({
    super.key,
    required this.name,
    required this.result,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    const theme = TrucoTheme.navyTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          height: 30,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppFonts.oswald,
                fontSize: 22,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
                color: highlighted
                    ? theme.cream
                    : theme.cream.withValues(alpha: 0.68),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _Score(result: result, highlighted: highlighted),
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  final String result;
  final bool highlighted;

  const _Score({required this.result, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    const theme = TrucoTheme.navyTheme;
    final parts = result.split(' ');
    final score = parts.first;
    final stage = parts.skip(1).join(' ');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          score,
          style: TextStyle(
            fontFamily: AppFonts.caminito,
            fontSize: highlighted ? 43 : 35,
            height: 0.9,
            color:
                highlighted ? theme.cream : theme.cream.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          stage,
          style: TextStyle(
            fontFamily: AppFonts.oswald,
            fontSize: highlighted ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: highlighted
                ? theme.accentColor
                : theme.cream.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}
