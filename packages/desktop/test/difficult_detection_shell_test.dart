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
  final LocalTimestamp edited = LocalTimestamp.tryParse(
    '2026-01-02T03:04:05+01:00',
  )!;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_difficult_detection_');
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

  /// Writes [deck] to [deckPath] and, beside it, a lifetime record holding
  /// [direction1] for each unit in turn.
  void writeDeckWithHistory(
    String deckPath,
    LearningDeck deck,
    List<DirectionStats> direction1,
  ) {
    File(deckPath).writeAsStringSync(encodeDeckJson(deck));
    File(DeckPaths.allTimeStatistics(deckPath)).writeAsStringSync(
      encodeStatisticsJson(
        StatisticsFile(
          deckRef: p.basename(deckPath),
          scope: StatisticsScope.allTime,
          perUnit: withUnitHashes(deck, <UnitStats>[
            for (var i = 0; i < direction1.length; i += 1)
              UnitStats(index: i + 1, direction1: direction1[i]),
          ]),
        ),
      ),
    );
  }

  /// Opens the app on [deckPath] and starts a session; returns the picker,
  /// so a test can open another deck.
  Future<_ScriptedFilePicker> startSession(
    WidgetTester tester,
    String deckPath,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: p.join(temp.path, 'settings.json'),
      ),
    );
    await settleAfterIo(tester);
    picker.nextOpenPath = deckPath;
    await pickMenuItem(tester, 'File', 'Load deck...');
    await pickMenuItem(tester, 'Learn', 'Practice setup');
    await tester.tap(find.text('Start session'));
    await settleAfterIo(tester);
    expect(find.text('Check'), findsOneWidget);
    return picker;
  }

  /// The deck as it stands on disk, or null while it is being rewritten
  /// (`writeAsString` truncates the file first).
  LearningDeck? deckOnDisk(String deckPath) {
    try {
      return decodeDeckJson(File(deckPath).readAsStringSync());
    } on FormatException {
      return null;
    }
  }

  /// Polls — rather than sleeping a fixed time — until [done] holds or five
  /// seconds have passed, pumping as it goes; the caller's expectation then
  /// reports what it found.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await settle(tester);
  }

  List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
    for (final LearningUnit unit in deck.units)
      (unit.manualDifficult, unit.autoDifficult),
  ];

  // 3 wrong of 4: qualifies under the default rule.
  const DirectionStats hard = DirectionStats(attempts: 4, correct: 1);
  // 1 wrong of 4: does not.
  const DirectionStats easy = DirectionStats(attempts: 4, correct: 3);

  testWidgets('stopping a session writes the automatic flag of a unit that '
      'qualifies, keeps one that no longer does, and leaves the last-edited '
      'date alone', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'deck.vok');
    final LearningDeck deck = _deck(<(String, String, bool)>[
      ('house', 'Haus', false),
      ('tree', 'Baum', true),
      ('dog', 'Hund', false),
    ]).copyWith(lastEdited: edited);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[hard, easy, easy]);

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      // Nothing is detected while the session runs.
      expect(flags(deckOnDisk(deckPath)!), <(bool, bool)>[
        (false, false),
        (false, true),
        (false, false),
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await until(
        tester,
        () => deckOnDisk(deckPath)?.units.first.autoDifficult ?? false,
      );
      final LearningDeck onDisk = deckOnDisk(deckPath)!;
      expect(flags(onDisk), <(bool, bool)>[
        (false, true),
        (false, true),
        (false, false),
      ]);
      expect(onDisk.lastEdited, edited);
    });
  });

  testWidgets('mastering the pool ends the session and writes the flag', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'mastered.vok');
    final LearningDeck deck = _deck(<(String, String, bool)>[
      ('house', 'Haus', false),
    ]);
    // Still 3 wrong of 5 after the right answer given below.
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[hard]);

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await tester.enterText(find.byType(TextField).first, 'Haus');
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settleAfterIo(tester);
      expect(find.text('Check'), findsNothing);

      await until(
        tester,
        () => deckOnDisk(deckPath)?.units.single.autoDifficult ?? false,
      );
      expect(deckOnDisk(deckPath)!.units.single.autoDifficult, isTrue);
    });
  });

  testWidgets('opening another deck mid-session judges the deck that was '
      'practised, not the one arriving', (WidgetTester tester) async {
    final String practisedPath = p.join(temp.path, 'practised.vok');
    final String arrivingPath = p.join(temp.path, 'arriving.vok');
    writeDeckWithHistory(
      practisedPath,
      _deck(<(String, String, bool)>[('house', 'Haus', false)]),
      <DirectionStats>[hard],
    );
    writeDeckWithHistory(
      arrivingPath,
      _deck(<(String, String, bool)>[('tree', 'Baum', false)]),
      <DirectionStats>[hard],
    );
    final String arrivingBefore = File(arrivingPath).readAsStringSync();

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = await startSession(
        tester,
        practisedPath,
      );
      picker.nextOpenPath = arrivingPath;
      await pickMenuItem(tester, 'File', 'Load deck...');
      await until(
        tester,
        () => deckOnDisk(practisedPath)?.units.single.autoDifficult ?? false,
      );
      expect(deckOnDisk(practisedPath)!.units.single.autoDifficult, isTrue);
      // No session ended for the arriving deck, so its file is untouched.
      expect(File(arrivingPath).readAsStringSync(), arrivingBefore);
    });
  });

  testWidgets('leaving a session for a screen the shell switches to directly '
      'still ends it', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'masked.vok');
    final LearningDeck deck = _deck(<(String, String, bool)>[
      ('house', 'Haus', false),
    ]);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[hard]);
    // The deck's own mask file, so the Mask Editor opens without asking.
    File(p.join(temp.path, 'masked.inf'))
        .writeAsStringSync(encodeMaskJson(deck.mask));

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await pickMenuItem(tester, 'Edit', 'Mask Editor');
      await until(
        tester,
        () => deckOnDisk(deckPath)?.units.single.autoDifficult ?? false,
      );
      expect(find.text('Check'), findsNothing);
      expect(deckOnDisk(deckPath)!.units.single.autoDifficult, isTrue);
    });
  });

  testWidgets('a session ending with nothing to add leaves the file as it '
      'was', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'quiet.vok');
    final LearningDeck deck = _deck(<(String, String, bool)>[
      ('house', 'Haus', false),
    ]);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[easy]);
    final String before = File(deckPath).readAsStringSync();

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleAfterIo(tester);
      expect(File(deckPath).readAsStringSync(), before);
    });
  });

  testWidgets('with detection switched off, a session end writes nothing', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'off.vok');
    writeDeckWithHistory(
      deckPath,
      _deck(<(String, String, bool)>[('house', 'Haus', false)]),
      <DirectionStats>[hard],
    );
    File(p.join(temp.path, 'settings.json')).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(detectDifficultUnits: false),
      ),
    );
    final String before = File(deckPath).readAsStringSync();

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleAfterIo(tester);
      expect(File(deckPath).readAsStringSync(), before);
    });
  });

  testWidgets('a session end judges by the stored thresholds', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'strict.vok');
    writeDeckWithHistory(
      deckPath,
      _deck(<(String, String, bool)>[
        ('house', 'Haus', false),
        ('tree', 'Baum', false),
      ]),
      // 3 wrong of 4, and 4 wrong of 8: both answered right at least once
      // and both at or above the rate, so the wrong count alone decides.
      <DirectionStats>[
        hard,
        const DirectionStats(attempts: 8, correct: 4),
      ],
    );
    // 4 wrong needed: the first unit (3 wrong) no longer qualifies.
    File(p.join(temp.path, 'settings.json')).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          detectionThresholds: DetectionThresholds(minWrong: 4),
        ),
      ),
    );

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await until(
        tester,
        () => deckOnDisk(deckPath)?.units.last.autoDifficult ?? false,
      );
      expect(flags(deckOnDisk(deckPath)!), <(bool, bool)>[
        (false, false),
        (false, true),
      ]);
    });
  });

  testWidgets('a deck that cannot be written at session end names the file '
      'without blocking', (WidgetTester tester) async {
    final Directory gone = Directory(p.join(temp.path, 'gone'))..createSync();
    final String deckPath = p.join(gone.path, 'unwritable.vok');
    writeDeckWithHistory(
      deckPath,
      _deck(<(String, String, bool)>[('house', 'Haus', false)]),
      <DirectionStats>[hard],
    );

    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      // Nowhere left to write to.
      gone.deleteSync(recursive: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      // Snack bars queue behind "Deck loaded.", so poll for this one.
      final Finder message = find.textContaining(
        'Could not write "unwritable.vok", so the automatic flags',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsOneWidget);
      // Nothing modal: the app is on the screen the learner went to.
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

/// A deck of `(question, answer, automatic flag)` units.
LearningDeck _deck(List<(String, String, bool)> units) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_difficult-detection-shell',
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
      for (final (String question, String answer, bool automatic) in units)
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{
            0: FieldValue.plain(question),
            1: FieldValue.plain(answer),
          },
          autoDifficult: automatic,
        ),
    ],
  );
}
