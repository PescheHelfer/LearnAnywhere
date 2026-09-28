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

  List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
    for (final LearningUnit unit in deck.units)
      (unit.manualDifficult, unit.autoDifficult),
  ];

  const String noDifficultUnits =
      'No unit in the selected range is marked as difficult, so there is '
      'nothing to ask.';

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
        _deck(<(String, String, bool, bool)>[
          ('house', 'Haus', false, false),
          ('tree', 'Baum', true, false),
          ('dog', 'Hund', false, false),
          ('cat', 'Katze', false, true),
        ]),
      ),
    );

    await tester.runAsync(() async {
      await openSetup(tester, deckPath);
      await tester.tap(find.text('Difficult units only'));
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
      expect(flags(deckOnDisk(deckPath)!), <(bool, bool)>[
        (false, false),
        (true, false),
        (false, false),
        (false, true),
      ]);
      expect(
        decodeSettingsJson(File(settingsPath).readAsStringSync()).difficultOnly,
        isTrue,
      );
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
          _deck(<(String, String, bool, bool)>[
            ('house', 'Haus', true, false),
            ('tree', 'Baum', false, false),
            ('dog', 'Hund', false, true),
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

  testWidgets('with no difficult unit the setup says so and does not start', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'plain.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(<(String, String, bool, bool)>[
          ('house', 'Haus', false, false),
          ('tree', 'Baum', false, false),
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
      await tester.tap(find.text('Difficult units only'));
      await settleAfterIo(tester);
      expect(find.text(noDifficultUnits), findsNothing);
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);
      expect(find.text('Check'), findsOneWidget);
    });
  });
}

/// A deck of `(question, answer, manual flag, automatic flag)` units.
LearningDeck _deck(List<(String, String, bool, bool)> units) {
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
