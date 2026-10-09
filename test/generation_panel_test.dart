import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odyn_diffusion_android/l10n/app_localizations.dart';
import 'package:odyn_diffusion_android/widgets/generation_panel.dart';

void main() {
  Widget harness(Locale locale) => MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const Scaffold(body: GenerationPanel(isVideo: false)),
      );

  testWidgets('Polish prompt field is editable and generation is disabled',
      (tester) async {
    await tester.pumpWidget(harness(const Locale('pl')));
    expect(find.text('Opis (prompt)'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('generation_prompt')), 'Zachód słońca');
    expect(find.text('Zachód słońca'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('English form shows dimensions', (tester) async {
    await tester.pumpWidget(harness(const Locale('en')));
    expect(find.text('Width'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });
}
