import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/settings/detection_settings_dialog.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Options ▸ Statistics ▸ Detect difficult units: what it shows, what it
/// accepts, and what it hands back.
void main() {
  const String minWrong = 'Minimum wrong answers (1–10)';
  const String minWrongRate = 'Minimum wrong rate in % (10–90)';
  const String minAttempts =
      'Attempts that count without a correct answer (3–20)';

  /// Opens the dialog on [enabled] and [thresholds], and returns what it
  /// will complete with once it closes.
  Future<Future<DetectionSettings?>> openDialog(
    WidgetTester tester, {
    bool enabled = true,
    DetectionThresholds thresholds = DetectionThresholds.defaults,
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late Future<DetectionSettings?> result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => result = showDetectionSettingsDialog(
              context,
              enabled: enabled,
              thresholds: thresholds,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> press(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<TextField>(find.widgetWithText(TextField, label))
      .controller!
      .text;

  testWidgets('shows the stored values, and OK returns the switch and the '
      'typed thresholds', (WidgetTester tester) async {
    final Future<DetectionSettings?> result = await openDialog(
      tester,
      thresholds: const DetectionThresholds(
        minWrong: 3,
        minWrongRatePercent: 50,
        minAttemptsWithoutCorrect: 8,
      ),
    );
    expect(find.text('Detect difficult units'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(fieldText(tester, minWrong), '3');
    expect(fieldText(tester, minWrongRate), '50');
    expect(fieldText(tester, minAttempts), '8');

    await tester.tap(find.byType(Switch));
    await type(tester, minWrongRate, '40');
    await press(tester, 'OK');

    final DetectionSettings? chosen = await result;
    expect(chosen?.enabled, isFalse);
    expect(
      chosen?.thresholds,
      const DetectionThresholds(
        minWrong: 3,
        minWrongRatePercent: 40,
        minAttemptsWithoutCorrect: 8,
      ),
    );
  });

  testWidgets('Reset to defaults restores the three thresholds but not the '
      'switch', (WidgetTester tester) async {
    final Future<DetectionSettings?> result = await openDialog(
      tester,
      enabled: false,
      thresholds: const DetectionThresholds(
        minWrong: 9,
        minWrongRatePercent: 80,
        minAttemptsWithoutCorrect: 19,
      ),
    );
    await press(tester, 'Reset to defaults');
    expect(fieldText(tester, minWrong), '2');
    expect(fieldText(tester, minWrongRate), '33');
    expect(fieldText(tester, minAttempts), '6');
    await press(tester, 'OK');

    final DetectionSettings? chosen = await result;
    expect(chosen?.enabled, isFalse);
    expect(chosen?.thresholds, DetectionThresholds.defaults);
  });

  testWidgets('a value outside its range says so and cannot be saved', (
    WidgetTester tester,
  ) async {
    final Future<DetectionSettings?> result = await openDialog(tester);
    await type(tester, minWrongRate, '95');
    expect(find.text('Enter a whole number from 10 to 90.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
          .onPressed,
      isNull,
    );
    await type(tester, minWrong, '');
    expect(find.text('Enter a whole number from 1 to 10.'), findsOneWidget);

    await press(tester, 'Cancel');
    expect(await result, isNull);
  });
}
