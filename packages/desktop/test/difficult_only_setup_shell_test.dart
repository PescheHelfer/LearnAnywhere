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

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_difficult_only_');
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

  /// Opens the app on [deckPath] and goes to the practice setup.
  Future<void> openSetup(WidgetTester tester, String deckPath) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: settingsPath,
      ),
    );
    await settleAfterIo(tester);
    picker.nextOpenPath = deckPath;
    await pickMenuItem(tester, 'File', 'Load deck...');
    await pickMenuItem(tester, 'Learn', 'Practice setup');
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

  List<(DifficultFlags, DifficultFlags)> flags(LearningDeck deck) =>
      <(DifficultFlags, DifficultFlags)>[
        for (final LearningUnit unit in deck.units)
          (unit.direction1Flags, unit.direction2Flags),
      ];

  const String noDifficultUnits =
      'No unit in the selected range is difficult in the chosen direction, '
      'so there is nothing to ask.';

  testWidgets('a session with Difficult units only asks just the flagged '
      'units, mastering them keeps their flags, and the option is '
      'remembered', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'deck.vok');
    const Map<String, String> answers = <String, String>{
      'house': 'Haus',
      'tree': 'Baum',
      'dog': 'Hund',
      'cat': 'Katze',
    };
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', manual, none),
          ('dog', 'Hund', none, none),
          ('cat', 'Katze', automatic, none),
        ]),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.textContaining('Difficult units only'));
      await settleAfterIo(tester);
      expect(find.text(noDifficultUnits), findsNothing);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      // The drill asks each flagged unit until it is mastered: one right
      // answer each, then the session is complete.
      final List<String> asked = <String>[];
      while (find.text('Check').evaluate().isNotEmpty) {
        final String question = answers.keys.singleWhere(
          (String q) => find.text(q, findRichText: true).evaluate().isNotEmpty,
        );
        asked.add(question);
        await tester.enterText(find.byType(TextField).first, answers[question]!);
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await settle(tester);
        await tester.tap(find.text('Continue'));
        await settleAfterIo(tester);
        expect(asked.length, lessThanOrEqualTo(2));
      }
      expect(asked.toSet(), <String>{'tree', 'cat'});

      // Mastering a unit is not unmarking it.
      expect(flags(deckOnDisk(deckPath)!), <(DifficultFlags, DifficultFlags)>[
        (none, none),
        (manual, none),
        (none, none),
        (automatic, none),
      ]);
      expect(
        decodeSettingsJson(File(settingsPath).readAsStringSync()).difficultOnly,
        isTrue,
      );
    });
  });

  testWidgets('a Both session with Difficult units only asks each unit only '
      'in the direction it is difficult in', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'both.vok');
    // Question text to answer, in either direction.
    const Map<String, String> answers = <String, String>{
      'house': 'Haus',
      'Haus': 'house',
      'tree': 'Baum',
      'Baum': 'tree',
      'dog': 'Hund',
      'Hund': 'dog',
    };
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', manual, none),
          ('tree', 'Baum', none, automatic),
          ('dog', 'Hund', none, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.both,
          difficultOnly: true,
        ),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      // One right answer masters a question; the session then ends.
      final List<String> asked = <String>[];
      while (find.text('Check').evaluate().isNotEmpty) {
        expect(asked.length, lessThan(2));
        final String question = answers.keys.singleWhere(
          (String q) => find.text(q, findRichText: true).evaluate().isNotEmpty,
        );
        asked.add(question);
        await tester.enterText(
          find.byType(TextField).first,
          answers[question]!,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await settle(tester);
        await tester.tap(find.text('Continue'));
        await settleAfterIo(tester);
      }
      // house in Direction 1 and tree in Direction 2 (asked as "Baum"); never
      // the easy way round, and never the unflagged dog.
      expect(asked.toSet(), <String>{'house', 'Baum'});
      expect(tester.takeException(), isNull);
    });
  });

  for (final (SessionMode mode, bool shuffle) in <(SessionMode, bool)>[
    (SessionMode.practice, true),
    (SessionMode.onceThrough, false),
  ]) {
    testWidgets('in ${mode.name}, a unit unmarked with F12 is not asked again, '
        'and unmarking the last one ends the session', (
      WidgetTester tester,
    ) async {
      final String deckPath = p.join(temp.path, 'ordered.vok');
      const Map<String, String> answers = <String, String>{
        'house': 'Haus',
        'tree': 'Baum',
        'dog': 'Hund',
      };
      File(deckPath).writeAsStringSync(
        encodeDeckJson(
          _deck(<(String, String, DifficultFlags, DifficultFlags)>[
            ('house', 'Haus', manual, none),
            ('tree', 'Baum', none, none),
            ('dog', 'Hund', automatic, none),
          ]),
        ),
      );
      File(settingsPath).writeAsStringSync(
        encodeSettingsJson(
          LearnAnywhereSettings(
            mode: mode,
            shuffle: shuffle,
            difficultOnly: true,
          ),
        ),
      );

      await tester.runAsync(() async {
        await openSetup(tester, deckPath);
        await tester.tap(find.text('Start session'));
        await settleAfterIo(tester);

        final List<String> asked = <String>[];
        while (find.text('Check').evaluate().isNotEmpty) {
          expect(asked.length, lessThan(2));
          final String question = answers.keys.singleWhere(
            (String q) =>
                find.text(q, findRichText: true).evaluate().isNotEmpty,
          );
          asked.add(question);
          await tester.sendKeyEvent(LogicalKeyboardKey.f12);
          await settleAfterIo(tester);
          await tester.enterText(
            find.byType(TextField).first,
            answers[question]!,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.f10);
          await settle(tester);
          await tester.tap(find.text('Continue'));
          await settleAfterIo(tester);
        }
        expect(asked.toSet(), <String>{'house', 'dog'});
        expect(tester.takeException(), isNull);
      });
    });
  }

  /// The tooltip of the stat pill reading [text].
  String pillTooltip(WidgetTester tester, String text) => tester
      .widget<Tooltip>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Tooltip))
            .first,
      )
      .message!;

  /// Answers the question on screen with [answer] and moves on.
  Future<void> answer(WidgetTester tester, String answer) async {
    await tester.enterText(find.byType(TextField).first, answer);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settleAfterIo(tester);
  }

  const String allMastered =
      'You have now mastered all learning units in the selected range. '
      'Congratulations!';
  const String noneLeft = 'No difficult units left to ask.';

  testWidgets('a restricted drill shows Remaining as "n (m)", m runs down to '
      'the all-mastered ending, and every pill says what it counts', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'readout.vok');
    const Map<String, String> answers = <String, String>{
      'house': 'Haus',
      'tree': 'Baum',
      'dog': 'Hund',
      'cat': 'Katze',
    };
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', manual, none),
          ('dog', 'Hund', none, none),
          ('cat', 'Katze', automatic, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.direction1,
          mode: SessionMode.superQuery,
          difficultOnly: true,
        ),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      expect(find.text('Remaining: 4 (2)'), findsOneWidget);
      expect(
        pillTooltip(tester, 'Remaining: 4 (2)'),
        'Questions not yet mastered: 4 in the whole deck, 2 of them in what '
        'this session asks.',
      );
      expect(
        pillTooltip(tester, 'Attempts: 0'),
        "Answers given for the whole deck in this session's direction, from "
        'the current statistics.',
      );
      expect(
        pillTooltip(tester, 'Mastered: 0/4'),
        'Questions mastered out of all questions in the whole deck, in this '
        "session's direction.",
      );
      expect(
        pillTooltip(tester, 'Accuracy: 0/0 (0%)'),
        'Correct answers out of all answers, for the whole deck in this '
        "session's direction.",
      );

      String question() => answers.keys.singleWhere(
        (String q) => find.text(q, findRichText: true).evaluate().isNotEmpty,
      );
      await answer(tester, answers[question()]!);
      expect(find.text('Remaining: 3 (1)'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);

      await answer(tester, answers[question()]!);
      expect(find.text('Check'), findsNothing);
      expect(find.text(allMastered), findsOneWidget);
      expect(find.text(noneLeft), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a whole-deck drill shows Remaining as a single figure', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'whole.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', manual, none),
          ('tree', 'Baum', none, none),
          ('dog', 'Hund', none, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.direction1,
          mode: SessionMode.superQuery,
        ),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      expect(find.text('Remaining: 3'), findsOneWidget);
      expect(
        pillTooltip(tester, 'Remaining: 3'),
        'Questions not yet mastered in the whole deck, in this '
        "session's direction.",
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('F12 on the last difficult unit ends the drill with "none '
      'left", not "all mastered"', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'last.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', manual, none),
          ('dog', 'Hund', none, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.direction1,
          mode: SessionMode.superQuery,
          difficultOnly: true,
        ),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);
      expect(find.text('tree', findRichText: true), findsOneWidget);
      expect(find.text('Remaining: 3 (1)'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settleAfterIo(tester);
      // The unit stays on screen, but the session has nothing left to ask.
      expect(find.text('Remaining: 3 (0)'), findsOneWidget);

      // A wrong answer: tree is not mastered, only no longer difficult.
      await answer(tester, 'Bäume');
      expect(find.text('Check'), findsNothing);
      expect(find.text(noneLeft), findsOneWidget);
      expect(find.text(allMastered), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('unmarking the last unit left ends with "none left" even while '
      'a mastered unit keeps its flag', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'mastered.vok');
    const Map<String, String> answers = <String, String>{
      'house': 'Haus',
      'tree': 'Baum',
      'cat': 'Katze',
    };
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', manual, none),
          ('cat', 'Katze', automatic, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.direction1,
          mode: SessionMode.superQuery,
          difficultOnly: true,
        ),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      String question() => answers.keys.singleWhere(
        (String q) => find.text(q, findRichText: true).evaluate().isNotEmpty,
      );
      // The first unit is mastered and keeps its flag.
      await answer(tester, answers[question()]!);
      expect(find.text('Remaining: 2 (1)'), findsOneWidget);

      // The second is unmarked, then answered wrong.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settleAfterIo(tester);
      await answer(tester, 'x');
      expect(find.text('Check'), findsNothing);
      expect(find.text(noneLeft), findsOneWidget);
      expect(find.text(allMastered), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Level Learning pills and the clock carry tooltips, and there '
      'is no Remaining', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'levels.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', none, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(
          direction: DirectionSelection.direction1,
          mode: SessionMode.levelLearning,
          showClock: true,
        ),
      ),
    );

    Finder tooltipSaying(String message) => find.byWidgetPredicate(
      (Widget widget) => widget is Tooltip && widget.message == message,
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      expect(find.textContaining('Remaining'), findsNothing);
      expect(
        tooltipSaying(
          'Answers given for the whole deck on every level, in this '
          "session's direction.",
        ),
        findsOneWidget,
      );
      expect(
        tooltipSaying(
          'Units mastered without help, as a share of the whole deck, in '
          "this session's direction.",
        ),
        findsOneWidget,
      );
      expect(
        tooltipSaying(
          'Units currently at this level, as a share of the whole deck, in '
          "this session's direction.",
        ),
        findsNWidgets(kMaxSupportLevel - kFreeRecallLevel + 1),
      );
      expect(
        tooltipSaying(
          'Time spent on this unit. At the time limit a tone sounds and the '
          'clock is highlighted.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the option counts the difficult units in the range and the '
      'deck, following End and the direction', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'count.vok');
    // Direction 1: units 1, 3, 4. Direction 2: units 2, 3. Either: all four.
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', manual, none),
          ('tree', 'Baum', none, automatic),
          ('dog', 'Hund', automatic, manual),
          ('cat', 'Katze', manual, none),
        ]),
      ),
    );
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(direction: DirectionSelection.direction1),
      ),
    );

    /// The tooltip on the help icon beside the option, in the option's own
    /// row (the nearest one).
    String tooltip() => tester
        .widget<Tooltip>(
          find.descendant(
            of: find
                .ancestor(
                  of: find.textContaining('Difficult units only'),
                  matching: find.byType(Row),
                )
                .first,
            matching: find.byType(Tooltip),
          ),
        )
        .message!;

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      expect(find.text('Difficult units only (3)'), findsOneWidget);
      expect(
        tooltip(),
        '3 units in this deck are difficult in the chosen direction.',
      );

      await tester.enterText(find.widgetWithText(TextField, 'End unit'), '2');
      await settle(tester);
      expect(find.text('Difficult units only (1/3)'), findsOneWidget);
      expect(
        tooltip(),
        "1 of the deck's 3 difficult units are in the selected range.",
      );

      await tester.tap(find.text('Direction 1').last);
      await settle(tester);
      await tester.tap(find.text('Both').last);
      await settleAfterIo(tester);
      expect(find.text('Difficult units only (2/4)'), findsOneWidget);

      await tester.tap(find.text('Both').last);
      await settle(tester);
      await tester.tap(find.text('Direction 2').last);
      await settleAfterIo(tester);
      // Of units 2 and 3, only unit 2 is within units 1 to 2.
      expect(find.text('Difficult units only (1/2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('with no difficult unit the setup says so and does not start', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'plain.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, DifficultFlags, DifficultFlags)>[
          ('house', 'Haus', none, none),
          ('tree', 'Baum', none, none),
        ]),
      ),
    );
    // Remembered from an earlier run.
    File(settingsPath).writeAsStringSync(
      encodeSettingsJson(const LearnAnywhereSettings(difficultOnly: true)),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      expect(find.text(noDifficultUnits), findsOneWidget);

      final FilledButton start = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Start session'),
          matching: find.byWidgetPredicate(
            (Widget widget) => widget is FilledButton,
          ),
        ),
      );
      expect(start.onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await settleAfterIo(tester);
      expect(find.text('Check'), findsNothing);
      expect(find.text(noDifficultUnits), findsOneWidget);

      // Switching the option off lets the whole deck be asked again.
      await tester.tap(find.textContaining('Difficult units only'));
      await settleAfterIo(tester);
      expect(find.text(noDifficultUnits), findsNothing);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);
      expect(find.text('Check'), findsOneWidget);
    });
  });
}

const DifficultFlags none = DifficultFlags.none;
const DifficultFlags manual = DifficultFlags(manual: true);
const DifficultFlags automatic = DifficultFlags(automatic: true);

/// A deck of `(question, answer, Direction 1 flags, Direction 2 flags)`
/// units.
LearningDeck _deck(
  List<(String, String, DifficultFlags, DifficultFlags)> units,
) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_difficult-only-shell',
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
      for (final (
            String question,
            String answer,
            DifficultFlags direction1,
            DifficultFlags direction2,
          )
          in units)
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{
            0: FieldValue.plain(question),
            1: FieldValue.plain(answer),
          },
          direction1Flags: direction1,
          direction2Flags: direction2,
        ),
    ],
  );
}
