import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truco_pro/providers/score_provider.dart';
import 'package:truco_pro/providers/premium_provider.dart';
import 'package:truco_pro/screens/live_match_screen.dart';
import 'package:truco_pro/theme/app_theme.dart';
import 'package:truco_pro/widgets/game_dialogs.dart';

void main() {
  testWidgets('preview dismisses without changing theme or unlocking',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final score = ScoreProvider();
    final premium = PremiumProvider();
    final original = score.appTheme;
    final theme = TrucoTheme.allThemes.last;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: score),
        ChangeNotifierProvider.value(value: premium),
      ],
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => GameDialogs.showUnlock(
                            context, 'theme_${theme.name}', 'tema'),
                        child: const Text('Abrir')),
                  ))),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemePreview), findsOneWidget);
    expect(tester.widget<ThemePreview>(find.byType(ThemePreview)).theme, theme);
    expect(score.appTheme, original);
    expect(premium.isThemeUnlocked(theme.name), isFalse);
    await tester.tapAt(tester.getCenter(find.byKey(const Key('themePreview'))));
    await tester.pumpAndSettle();
    expect(find.byType(ThemePreview), findsNothing);
    expect(find.text('Vista previa'), findsOneWidget);
    expect(score.appTheme, original);
    expect(premium.isThemeUnlocked(theme.name), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    score.dispose();
    premium.dispose();
  });
}
