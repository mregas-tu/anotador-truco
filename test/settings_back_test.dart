import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truco_pro/providers/premium_provider.dart';
import 'package:truco_pro/providers/score_provider.dart';
import 'package:truco_pro/widgets/settings_dialog.dart';

void main() {
  testWidgets('device back follows submenu hierarchy before closing settings',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
        appName: 'Truco',
        packageName: 'truco',
        version: '1.0',
        buildNumber: '1',
        buildSignature: '');
    final score = ScoreProvider();
    final premium = PremiumProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: score),
        ChangeNotifierProvider.value(value: premium),
      ],
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                      child: const Text('Abrir'),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                            child: SingleChildScrollView(
                          child: SettingsDialogContent(
                            onThemeLockedTap: (_) {},
                            onPaletteLockedTap: (_) {},
                            onBeanPaletteLockedTap: (_) {},
                            onPremiumTap: () {},
                            onRepeatTutorial: () {},
                            onMoreScorekeepersVisibilityChanged: (_) {},
                          ),
                        )),
                      ),
                    ),
                  ))),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DISEÑO'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('AJUSTES'), findsOneWidget);
    expect(find.byType(SettingsDialogContent), findsOneWidget);

    await tester.tap(find.text('AYUDA Y SOPORTE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VALORES Y SEÑAS'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('AYUDA Y SOPORTE'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('AJUSTES'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsDialogContent), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    score.dispose();
    premium.dispose();
  });
}
