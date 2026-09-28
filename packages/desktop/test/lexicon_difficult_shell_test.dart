import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// A [DesktopFilePicker] whose folder and save dialogs answer with
/// [folder] and [saveTo].
final class _ScriptedFilePicker extends DesktopFilePicker {
  _ScriptedFilePicker({required this.folder, required this.saveTo});

  final String folder;
  final String saveTo;

  @override
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async => null;

  @override
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async => saveTo;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => folder;
}

void main() {
  late DesktopPrefs prefs;
  late Directory temp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_lexicon_difficult_');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });
  });

  // The bounded settle the other shell tests use: the body runs inside one
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

  /// Taps the control labelled [label], scrolling it into view first.
  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).last);
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  /// Each unit's (manual, automatic) flags in the deck file at [path], keyed
  /// by its question: the folder walk decides the order of the hits, so the
  /// order of the saved units is not asserted.
  Map<String, (bool, bool)> flagsByQuestion(String path) {
    return <String, (bool, bool)>{
      for (final LearningUnit unit in decodeDeckJson(
        File(path).readAsStringSync(),
      ).units)
        unit.valueForFieldId(0).plainText: (
          unit.manualDifficult,
          unit.autoDifficult,
        ),
    };
  }

  testWidgets('a recursive file search with Difficult only finds just the '
      'flagged units of several decks, and loading and saving them keeps '
      'their flags', (WidgetTester tester) async {
    final Directory folder = Directory(p.join(temp.path, 'decks'))
      ..createSync();
    Directory(p.join(folder.path, 'sub')).createSync();
    File(p.join(folder.path, 'a.vok')).writeAsStringSync(
      encodeDeckJson(
        LearningDeck(
          mask: _mask,
          units: <LearningUnit>[
            _unit('house', 'Haus', manual: true),
            _unit('cat', 'Katze'),
            _unit('dog', 'Hund', auto: true),
          ],
        ),
      ),
    );
    // The same mask a revision later, with a field renamed: whichever deck
    // the walk meets first gives the reference mask, so the other deck's
    // hits are re-keyed onto it when they are loaded.
    File(p.join(folder.path, 'sub', 'b.vok')).writeAsStringSync(
      encodeDeckJson(
        LearningDeck(
          mask: _mask.copyWith(
            revision: _mask.revision + 1,
            categories: <CategoryDefinition>[
              CategoryDefinition(
                id: 1,
                name: 'Default',
                fields: <FieldDefinition>[
                  _mask.categories.single.fields[0].copyWith(name: 'Word'),
                  _mask.categories.single.fields[1],
                ],
              ),
            ],
          ),
          units: <LearningUnit>[
            _unit('mouse', 'Maus', manual: true, auto: true),
            _unit('bird', 'Vogel'),
          ],
        ),
      ),
    );
    final String savedPath = p.join(temp.path, 'hard.vok');

    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: _ScriptedFilePicker(
            folder: folder.path,
            saveTo: savedPath,
          ),
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);
      await tester.tap(find.text('Lexicon'));
      await settle(tester);

      await press(tester, 'Difficult only');
      await press(tester, 'Search files');
      await settleAfterIo(tester);

      expect(find.text('Results: 3'), findsOneWidget);
      expect(find.text('house'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
      expect(find.text('mouse'), findsOneWidget);
      expect(find.text('cat'), findsNothing);
      expect(find.text('bird'), findsNothing);
      expect(find.byTooltip('Difficult (manual flag)'), findsOneWidget);
      expect(find.byTooltip('Difficult (automatic flag)'), findsOneWidget);
      expect(
        find.byTooltip('Difficult (manual and automatic flag)'),
        findsOneWidget,
      );

      await press(tester, 'Load found units');
      await press(tester, 'Load results');
      await press(tester, 'Continue');

      // The loaded deck has no path, so saving asks where to.
      await tester.tap(find.text('File'));
      await settle(tester);
      await tester.tap(find.text('Save deck').last);
      await settleAfterIo(tester);
      for (var i = 0; i < 100 && !File(savedPath).existsSync(); i += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }

      expect(flagsByQuestion(savedPath), <String, (bool, bool)>{
        'house': (true, false),
        'dog': (false, true),
        'mouse': (true, true),
      });
    });
  });
}

const LearningMask _mask = LearningMask(
  maskId: 'm_new_lexicon-difficult-shell',
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
);

LearningUnit _unit(
  String question,
  String answer, {
  bool manual = false,
  bool auto = false,
}) {
  return LearningUnit(
    categoryId: 1,
    fields: <int, FieldValue>{
      0: FieldValue.plain(question),
      1: FieldValue.plain(answer),
    },
    manualDifficult: manual,
    autoDifficult: auto,
  );
}
