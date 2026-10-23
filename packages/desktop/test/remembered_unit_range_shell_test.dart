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

const String _maskId = 'm_new_remembered-range-shell';

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  late String settingsPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_remembered_range_');
    settingsPath = p.join(temp.path, 'settings.json');
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

  /// Starts an app instance on the shared temporary settings file; open
  /// dialogs answer through [picker].
  Future<void> startApp(WidgetTester tester, _ScriptedFilePicker picker) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: settingsPath,
        speechEngine: const UnavailableTtsEngine(),
      ),
    );
    await settleAfterIo(tester);
  }

  Future<void> loadDeck(
    WidgetTester tester,
    _ScriptedFilePicker picker,
    String deckPath,
  ) async {
    picker.nextOpenPath = deckPath;
    await pickMenuItem(tester, 'File', 'Load deck...');
  }

  /// What the setup screen's Start unit and End unit fields show.
  (String, String) shownRange(WidgetTester tester) {
    String field(String label) => tester
        .widget<TextField>(find.widgetWithText(TextField, label))
        .controller!
        .text;
    return (field('Start unit'), field('End unit'));
  }

  Future<void> typeRange(WidgetTester tester, int start, int end) async {
    await tester.enterText(find.widgetWithText(TextField, 'Start unit'), '$start');
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'End unit'), '$end');
    await settleAfterIo(tester);
  }

  /// Answers every question until the session ends, each right the first
  /// time (which masters it), and returns the questions in the order asked.
  Future<List<String>> answerUntilDone(WidgetTester tester) async {
    final List<String> asked = <String>[];
    while (find.text('Check').evaluate().isNotEmpty) {
      expect(asked.length, lessThan(8), reason: 'the session never ended');
      final String question = <String>[
        for (var unit = 1; unit <= 8; unit += 1) 'q$unit',
      ].singleWhere(
        (String q) => find.text(q, findRichText: true).evaluate().isNotEmpty,
      );
      asked.add(question);
      await tester.enterText(
        find.byType(TextField).first,
        question.replaceFirst('q', 'a'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settleAfterIo(tester);
    }
    return asked;
  }

  /// The range remembered for [deckPath] in the settings file, or null while
  /// the file is missing or being rewritten.
  UnitRangeSelection? rangeOnDisk(String deckPath) {
    try {
      return decodeSettingsJson(
        File(settingsPath).readAsStringSync(),
      ).unitRangeFor(deckPath);
    } on Object {
      return null;
    }
  }

  void writeSettings(LearnAnywhereSettings settings) {
    File(settingsPath).writeAsStringSync(encodeSettingsJson(settings));
  }

  const String allMastered =
      'You have now mastered all learning units in the selected range. '
      'Congratulations!';

  testWidgets('a deck reopened after a restart is back at its range, on the '
      'setup screen and for Learn with last settings', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(8)));

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);
      await loadDeck(tester, picker, deckPath);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      await typeRange(tester, 3, 5);
      expect(
        rangeOnDisk(deckPath),
        const UnitRangeSelection(startUnit: 3, endUnit: 5, endManuallySet: true),
      );

      // The restart: the old instance goes, and a new one reads the same
      // settings file.
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      await startApp(tester, _ScriptedFilePicker());

      // Reopened from the Workspace's Recent decks.
      await tester.tap(find.text(DeckPaths.folderAndFileName(deckPath)));
      await settleAfterIo(tester);
      expect(find.text('Deck: $deckPath'), findsOneWidget);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('3', '5'));

      await pickMenuItem(tester, 'Learn', 'Learn with last settings');
      final List<String> asked = await answerUntilDone(tester);
      expect(asked.toSet(), <String>{'q3', 'q4', 'q5'});
      expect(find.text(allMastered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a remembered range with every unit mastered ends Learn with '
      'last settings on the completion view, offering Extend session', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(8)));
    writeSettings(
      LearnAnywhereSettings(
        recentDeckPaths: <String>[deckPath],
        unitRanges: <String, UnitRangeSelection>{
          deckPath: const UnitRangeSelection(
            startUnit: 7,
            endUnit: 8,
            endManuallySet: true,
          ),
        },
      ),
    );

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);
      await loadDeck(tester, picker, deckPath);
      await pickMenuItem(tester, 'Learn', 'Learn with last settings');
      expect((await answerUntilDone(tester)).toSet(), <String>{'q7', 'q8'});

      // Back on the setup screen, nothing in range is left to learn.
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(find.text(allMastered), findsNothing);
      await pickMenuItem(tester, 'Learn', 'Learn with last settings');

      expect(find.text('Check'), findsNothing);
      expect(find.text(allMastered), findsOneWidget);
      expect(find.text('Extend session'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a remembered range is clamped to a deck that shrank, and one '
      'starting past its last unit gives the whole deck', (
    WidgetTester tester,
  ) async {
    final String shrunk = p.join(temp.path, 'shrunk.vok');
    final String short = p.join(temp.path, 'short.vok');
    File(shrunk).writeAsStringSync(encodeDeckJson(_deck(8)));
    File(short).writeAsStringSync(encodeDeckJson(_deck(8)));
    writeSettings(
      LearnAnywhereSettings(
        recentDeckPaths: <String>[shrunk, short],
        unitRanges: <String, UnitRangeSelection>{
          shrunk: const UnitRangeSelection(
            startUnit: 3,
            endUnit: 20,
            endManuallySet: true,
          ),
          short: const UnitRangeSelection(
            startUnit: 10,
            endUnit: 12,
            endManuallySet: true,
          ),
        },
      ),
    );

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);

      await loadDeck(tester, picker, shrunk);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('3', '8'));

      await loadDeck(tester, picker, short);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('1', '8'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Update deck from new version keeps the range', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String incomingPath = p.join(temp.path, 'words-new.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(8)));
    File(incomingPath).writeAsStringSync(encodeDeckJson(_deck(10)));

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);
      await loadDeck(tester, picker, deckPath);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      await typeRange(tester, 3, 5);

      picker.nextOpenPath = incomingPath;
      await pickMenuItem(tester, 'File', 'Update deck from new version...');
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).units,
        hasLength(10),
      );

      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('3', '5'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a range pinned with Use all units grows with the deck '
      'instead of being remembered as set by hand', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String incomingPath = p.join(temp.path, 'words-new.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(8)));
    File(incomingPath).writeAsStringSync(encodeDeckJson(_deck(10)));

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);
      await loadDeck(tester, picker, deckPath);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      await typeRange(tester, 3, 5);
      await tester.tap(find.text('Use all units (8)'));
      await settleAfterIo(tester);
      expect(shownRange(tester), ('1', '8'));
      expect(rangeOnDisk(deckPath), resetUnitRange(8));

      picker.nextOpenPath = incomingPath;
      await pickMenuItem(tester, 'File', 'Update deck from new version...');
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('1', '10'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a new deck starts at the full range, and the deck before it '
      'keeps its own', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String maskPath = p.join(temp.path, 'words.inf');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(8)));
    File(maskPath).writeAsStringSync(encodeMaskJson(_deck(0).mask));

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = _ScriptedFilePicker();
      await startApp(tester, picker);
      await loadDeck(tester, picker, deckPath);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      await typeRange(tester, 3, 5);

      await pickMenuItem(tester, 'File', 'Clear units from memory...');
      await tester.tap(find.text('Continue'));
      await settle(tester);
      picker.nextOpenPath = maskPath;
      await tester.tap(find.text('Load existing mask...'));
      await settleAfterIo(tester);

      // Two units for the new deck, through the unit editor.
      await pickMenuItem(tester, 'Edit', 'Unit editor');
      await tester.tap(find.text('Insert unit'));
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.tap(find.text('Insert before'));
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.tap(find.text('Done'));
      await settle(tester);

      await pickMenuItem(tester, 'Learn', 'Practice setup');
      expect(shownRange(tester), ('1', '2'));
      expect(
        rangeOnDisk(deckPath),
        const UnitRangeSelection(startUnit: 3, endUnit: 5, endManuallySet: true),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// A deck of [count] units, unit `n` asking `qn` and answered `an`.
LearningDeck _deck(int count) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: _maskId,
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
      for (var unit = 1; unit <= count; unit += 1)
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{
            0: FieldValue.plain('q$unit'),
            1: FieldValue.plain('a$unit'),
          },
        ),
    ],
  );
}
