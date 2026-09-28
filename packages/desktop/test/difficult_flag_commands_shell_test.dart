import 'dart:io';

import 'package:flutter/material.dart';
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

const String _recompute = 'Recompute automatic flags in the open deck...';
const String _removeManual = 'Remove all manual flags in the open deck...';

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  final LocalTimestamp edited = LocalTimestamp.tryParse(
    '2026-01-02T03:04:05+01:00',
  )!;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_difficult_commands_');
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

  /// Opens the app on [deckPath].
  Future<void> openDeck(WidgetTester tester, String deckPath) async {
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

  /// Polls — rather than sleeping a fixed time — until [done] holds or ten
  /// seconds have passed, pumping as it goes; the caller's expectation then
  /// reports what it found. Ten, because a message queues behind "Deck
  /// loaded." for about four. Each pump also moves the test clock, so the
  /// SnackBar queue advances however slowly the machine runs.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
  }

  // Messages are asserted with `findsWidgets`, not `findsOneWidget`: the File
  // operations screen that "Load deck..." leaves on show prints the latest
  // status as well, so once the queued SnackBar arrives the text is there
  // twice — and whether it has arrived yet depends on the machine's load.

  /// Picks [command] from the Statistics menu and waits for its warning.
  Future<void> openWarning(WidgetTester tester, String command) async {
    await pickMenuItem(tester, 'Statistics', command);
    await until(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty);
  }

  List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
    for (final LearningUnit unit in deck.units)
      (unit.manualDifficult, unit.autoDifficult),
  ];

  // 3 wrong of 4: qualifies under the default rule.
  const DirectionStats hard = DirectionStats(attempts: 4, correct: 1);
  // 1 wrong of 4: does not.
  const DirectionStats easy = DirectionStats(attempts: 4, correct: 3);

  testWidgets('recompute warns, removes a stale automatic flag, adds a due '
      'one, keeps manual flags, reports the counts and leaves the last-edited '
      'date alone', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'flags.vok');
    final LearningDeck deck = _deck(<(String, String, bool, bool)>[
      ('house', 'Haus', false, true),
      ('tree', 'Baum', true, false),
      ('dog', 'Hund', false, false),
      ('cat', 'Katze', true, true),
    ]).copyWith(lastEdited: edited);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[
      easy,
      easy,
      hard,
      easy,
    ]);

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      await openWarning(tester, _recompute);

      expect(find.text('Recompute automatic flags?'), findsOneWidget);
      expect(
        find.textContaining('Every unit in “flags.vok” is checked'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Decks made with Save selected units start'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue').last);
      await settleAfterIo(tester);

      final Finder message = find.text(
        'Automatic flags in “flags.vok” recomputed: 1 added, 2 removed.',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      final LearningDeck onDisk = deckOnDisk(deckPath)!;
      expect(flags(onDisk), <(bool, bool)>[
        (false, false),
        (true, false),
        (false, true),
        (true, false),
      ]);
      expect(onDisk.lastEdited, edited);
    });
  });

  testWidgets('remove all manual flags warns, clears manual flags only and '
      'reports the count', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'manual.vok');
    final LearningDeck deck = _deck(<(String, String, bool, bool)>[
      ('house', 'Haus', true, false),
      ('tree', 'Baum', true, true),
      ('dog', 'Hund', false, true),
      ('cat', 'Katze', false, false),
    ]).copyWith(lastEdited: edited);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[
      easy,
      easy,
      easy,
      easy,
    ]);

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      await openWarning(tester, _removeManual);

      expect(find.text('Remove all manual flags?'), findsOneWidget);
      expect(
        find.textContaining('Every manual flag in “manual.vok” is removed.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue').last);
      await settleAfterIo(tester);

      final Finder message = find.text(
        'Manual flags in “manual.vok” removed: 2.',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      final LearningDeck onDisk = deckOnDisk(deckPath)!;
      // The automatic flags stay, though the statistics no longer back them:
      // only recompute judges those.
      expect(flags(onDisk), <(bool, bool)>[
        (false, false),
        (false, true),
        (false, true),
        (false, false),
      ]);
      expect(onDisk.lastEdited, edited);
    });
  });

  testWidgets('declining either warning changes nothing', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'kept.vok');
    final LearningDeck deck = _deck(<(String, String, bool, bool)>[
      ('house', 'Haus', true, true),
      ('tree', 'Baum', false, false),
    ]);
    writeDeckWithHistory(deckPath, deck, <DirectionStats>[easy, hard]);
    final String before = File(deckPath).readAsStringSync();

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      for (final String command in <String>[_recompute, _removeManual]) {
        await openWarning(tester, command);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Cancel').last);
        await settleAfterIo(tester);
        expect(find.byType(AlertDialog), findsNothing);
      }
      expect(File(deckPath).readAsStringSync(), before);
    });
  });

  testWidgets('recompute refuses when the all-time statistics could not be '
      'read, rather than strip every automatic flag', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'locked.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, bool, bool)>[('house', 'Haus', false, true)]),
      ),
    );
    // There, but not readable as a lifetime record.
    File(DeckPaths.allTimeStatistics(deckPath)).writeAsStringSync('{broken');
    final String before = File(deckPath).readAsStringSync();

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      await pickMenuItem(tester, 'Statistics', _recompute);

      expect(find.byType(AlertDialog), findsNothing);
      final Finder message = find.textContaining(
        'The all-time statistics of “locked.vok” could not be read',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      expect(File(deckPath).readAsStringSync(), before);
    });
  });

  testWidgets('neither command runs while the unit editor is open', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'editing.vok');
    writeDeckWithHistory(
      deckPath,
      _deck(<(String, String, bool, bool)>[('house', 'Haus', true, true)]),
      <DirectionStats>[easy],
    );
    final String before = File(deckPath).readAsStringSync();

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      await pickMenuItem(tester, 'Edit', 'Unit editor');
      for (final String command in <String>[_recompute, _removeManual]) {
        await pickMenuItem(tester, 'Statistics', command);
        expect(find.byType(AlertDialog), findsNothing);
      }
      final Finder message = find.text(
        'Leave the unit editor first: F10 keeps your changes, Esc discards '
        'them.',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      expect(File(deckPath).readAsStringSync(), before);
    });
  });

  testWidgets('Show statistics opens the statistics screen', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'show.vok');
    writeDeckWithHistory(
      deckPath,
      _deck(<(String, String, bool, bool)>[('house', 'Haus', false, false)]),
      <DirectionStats>[easy],
    );

    await tester.runAsync(() async {
      await openDeck(tester, deckPath);
      await pickMenuItem(tester, 'Statistics', 'Show statistics');
      expect(find.text('Unit list'), findsOneWidget);
    });
  });
}

/// A deck of `(question, answer, manual flag, automatic flag)` units.
LearningDeck _deck(List<(String, String, bool, bool)> units) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_difficult-commands-shell',
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
      for (final (String question, String answer, bool manual, bool automatic)
          in units)
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{
            0: FieldValue.plain(question),
            1: FieldValue.plain(answer),
          },
          manualDifficult: manual,
          autoDifficult: automatic,
        ),
    ],
  );
}
