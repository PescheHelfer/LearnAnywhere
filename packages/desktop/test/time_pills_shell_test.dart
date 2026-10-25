import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// A [DesktopFilePicker] whose open dialog answers with whatever
/// [nextOpenPath] holds at the time; every other dialog is cancelled.
final class _ScriptedFilePicker extends DesktopFilePicker {
  String? nextOpenPath;

  @override
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async => nextOpenPath;

  @override
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async => null;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => null;
}

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  late String settingsPath;
  late String deckPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    // These tests are about the lifetime record, which is written whatever
    // the toggles say; with them on, a reopen would stop at the auto-load
    // prompt. The one test about the session file switches auto-save on.
    prefs.setAutoLoadStats(false);
    prefs.setAutoSaveStats(false);
    temp = Directory.systemTemp.createTempSync('la_time_pills_');
    settingsPath = p.join(temp.path, 'settings.json');
    deckPath = p.join(temp.path, 'deck.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck),
    );
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });
  });

  // The bounded settle the other shell tests use: each body runs inside one
  // `tester.runAsync`, so real dart:io completes, and `pumpAndSettle` must not
  // be nested in it.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }

  Future<void> settleAfterIo(WidgetTester tester) async {
    await settle(tester);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await settle(tester);
  }

  Future<void> pickMenuItem(
    WidgetTester tester,
    String menu,
    String item,
  ) async {
    await tester.tap(find.text(menu).first);
    await settle(tester);
    await tester.tap(find.text(item).last);
    await settleAfterIo(tester);
  }

  /// Opens the app with the deck loaded, on the home screen.
  Future<void> openDeck(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: settingsPath,
        speechEngine: const UnavailableTtsEngine(),
      ),
    );
    await settleAfterIo(tester);
    picker.nextOpenPath = deckPath;
    await pickMenuItem(tester, 'File', 'Load deck...');
  }

  Future<void> startSession(WidgetTester tester) async {
    await pickMenuItem(tester, 'Learn', 'Practice setup');
    await tester.tap(find.text('Start session'));
    await settleAfterIo(tester);
    expect(find.text('Check'), findsOneWidget);
  }

  // The pill's value ticks while the test settles, so only its label is
  // matched.
  final Finder unitTimePill = find.textContaining('Unit time: ');
  final Finder sittingTimePill = find.textContaining('Sitting time: ');
  final Finder statisticsTimePill = find.textContaining('Statistics time: ');
  final Finder totalTimePill = find.textContaining('Total time: ');

  /// Flips the learning option [label] on the Advanced Learning Options
  /// page, then leaves it with Esc (its Close button is below the fold).
  Future<void> toggleOption(WidgetTester tester, String label) async {
    await pickMenuItem(tester, 'Options', 'Advanced Learning Options');
    // The time group sits below the fold of the test window.
    await tester.ensureVisible(find.text(label));
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleAfterIo(tester);
  }

  testWidgets('the Unit time option shows and hides the Unit time pill', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await openDeck(tester);
      await startSession(tester);
      expect(unitTimePill, findsNothing);

      await toggleOption(tester, 'Unit time');
      await startSession(tester);
      expect(unitTimePill, findsOneWidget);
      expect(
        decodeSettingsJson(File(settingsPath).readAsStringSync()).showUnitTime,
        isTrue,
      );

      await toggleOption(tester, 'Unit time');
      await startSession(tester);
      expect(unitTimePill, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the Sitting time option shows and hides the Sitting time pill', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await openDeck(tester);
      await startSession(tester);
      expect(sittingTimePill, findsNothing);

      await toggleOption(tester, 'Sitting time');
      await startSession(tester);
      expect(sittingTimePill, findsOneWidget);
      // Each option shows its own pill only.
      expect(unitTimePill, findsNothing);
      expect(
        decodeSettingsJson(
          File(settingsPath).readAsStringSync(),
        ).showSittingTime,
        isTrue,
      );

      await toggleOption(tester, 'Sitting time');
      await startSession(tester);
      expect(sittingTimePill, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'the Statistics time option shows and hides the Statistics time pill',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await openDeck(tester);
        await startSession(tester);
        expect(statisticsTimePill, findsNothing);

        await toggleOption(tester, 'Statistics time');
        await startSession(tester);
        expect(statisticsTimePill, findsOneWidget);
        expect(unitTimePill, findsNothing);
        expect(sittingTimePill, findsNothing);
        expect(
          decodeSettingsJson(
            File(settingsPath).readAsStringSync(),
          ).showStatisticsTime,
          isTrue,
        );

        await toggleOption(tester, 'Statistics time');
        await startSession(tester);
        expect(statisticsTimePill, findsNothing);
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('the Total time option shows and hides the Total time pill', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await openDeck(tester);
      await startSession(tester);
      expect(totalTimePill, findsNothing);

      await toggleOption(tester, 'Total time');
      await startSession(tester);
      expect(totalTimePill, findsOneWidget);
      expect(unitTimePill, findsNothing);
      expect(sittingTimePill, findsNothing);
      expect(statisticsTimePill, findsNothing);
      expect(
        decodeSettingsJson(File(settingsPath).readAsStringSync()).showTotalTime,
        isTrue,
      );

      await toggleOption(tester, 'Total time');
      await startSession(tester);
      expect(totalTimePill, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a No count answer writes its time to the lifetime file, which '
      'the pill starts from on the next open', (WidgetTester tester) async {
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(const LearnAnywhereSettings(showTotalTime: true)),
    );
    final File lifetimeFile = File(
      p.join(temp.path, 'statistics', 'deck_alltime.sta'),
    );

    await tester.runAsync(() async {
      await openDeck(tester);
      await startSession(tester);
      expect(lifetimeFile.existsSync(), isFalse);

      // The shell runs on real timers here: let the unit's clock pass a
      // couple of seconds, then answer it and rate it No count.
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.text('Check'));
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settleAfterIo(tester);

      // No counter moved, yet the answer reached the lifetime file.
      final StatisticsFile written = decodeStatisticsJson(
        lifetimeFile.readAsStringSync(),
      );
      expect(written.scope, StatisticsScope.allTime);
      expect(written.learningSeconds, greaterThanOrEqualTo(2));
      expect(
        written.perUnit.every(
          (UnitStats stats) =>
              stats.direction1.attempts == 0 && stats.direction2.attempts == 0,
        ),
        isTrue,
      );

      // Reopened, the deck reads its total back, and the pill starts there
      // (plus whatever the new unit has run for).
      await pickMenuItem(tester, 'File', 'Load deck...');
      await startSession(tester);
      final String shown = tester
          .widget<Text>(totalTimePill)
          .data!
          .substring('Total time: '.length);
      final int shownSeconds = shown
          .split(':')
          .map(int.parse)
          .fold(0, (int total, int part) => total * 60 + part);
      expect(shownSeconds, greaterThanOrEqualTo(written.learningSeconds));
      expect(shownSeconds, lessThan(written.learningSeconds + 10));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'each answer saves its time into the session file, and a unit left '
    'unrated when the sitting ends adds nothing',
    (WidgetTester tester) async {
      prefs.setAutoSaveStats(true);
      File(settingsPath).writeAsStringSync(
        encodeSettingsJson(
          const LearnAnywhereSettings(showStatisticsTime: true),
        ),
      );

      /// The one timestamped session file the sitting writes to.
      File sessionFile() {
        final RegExp pattern = DeckPaths.timestampedStatisticsPattern(
          deckPath,
        );
        return Directory(p.join(temp.path, 'statistics'))
            .listSync()
            .whereType<File>()
            .singleWhere((File file) => pattern.hasMatch(p.basename(file.path)));
      }

      int savedSeconds() => decodeStatisticsJson(
        sessionFile().readAsStringSync(),
      ).learningSeconds;

      await tester.runAsync(() async {
        await openDeck(tester);
        await startSession(tester);
        expect(statisticsTimePill, findsOneWidget);
        expect(savedSeconds(), 0);

        // The shell runs on real timers here: let the first unit's clock
        // pass a couple of seconds, then answer it.
        await Future<void>.delayed(const Duration(milliseconds: 2200));
        await tester.enterText(find.byType(TextField), 'x');
        await tester.tap(find.text('Check'));
        await settle(tester);
        await tester.tap(find.text('Continue'));
        await settleAfterIo(tester);
        final int saved = savedSeconds();
        expect(saved, greaterThanOrEqualTo(2));

        // The second unit runs as long again, is never rated, and the sitting
        // ends.
        expect(find.text('Check'), findsOneWidget);
        await Future<void>.delayed(const Duration(milliseconds: 2200));
        await pickMenuItem(tester, 'Learn', 'Practice setup');
        expect(savedSeconds(), saved);

        await pickMenuItem(tester, 'Statistics', 'Show statistics');
        expect(
          find.text(
            'Statistics time: ${formatElapsedTime(Duration(seconds: saved))}',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('a settings file with Show clock on still shows the clock', (
    WidgetTester tester,
  ) async {
    File(settingsPath).writeAsStringSync(
      '{"format": "learn-anywhere/settings", "version": 1, '
      '"showClock": true}',
    );

    await tester.runAsync(() async {
      await openDeck(tester);
      await startSession(tester);
      expect(unitTimePill, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const LearningDeck _deck = LearningDeck(
  mask: LearningMask(
    maskId: 'm_new_time-pills-shell',
    name: 'Sample',
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
        name: 'Default',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'Question',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'Answer',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
        ],
      ),
    ],
  ),
  units: <LearningUnit>[
    LearningUnit(
      categoryId: 1,
      fields: <int, FieldValue>{
        0: FieldValue.plain('house'),
        1: FieldValue.plain('Haus'),
      },
    ),
    LearningUnit(
      categoryId: 1,
      fields: <int, FieldValue>{
        0: FieldValue.plain('tree'),
        1: FieldValue.plain('Baum'),
      },
    ),
  ],
);
