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

const String _update = 'Update deck from new version...';

const DifficultFlags _manual = DifficultFlags(manual: true);
const DifficultFlags _automatic = DifficultFlags(automatic: true);

void main() {
  late DesktopPrefs prefs;
  late Directory temp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_new_version_');
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

  /// Starts the app and opens [deckPath]; later open dialogs answer through
  /// the returned picker.
  Future<_ScriptedFilePicker> openDeck(
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
    return picker;
  }

  /// Polls until [done] holds or ten seconds have passed; a message can queue
  /// behind "Deck loaded." for about four.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
  }

  /// Each unit on disk as `question:d1/d2`, flags as `M`/`A`.
  List<String> flagsOnDisk(String deckPath) {
    String code(DifficultFlags flags) =>
        '${flags.manual ? 'M' : '-'}${flags.automatic ? 'A' : '-'}';
    String line(LearningUnit unit) =>
        '${unit.valueForFieldId(0).plainText}:'
        '${code(unit.direction1Flags)}/${code(unit.direction2Flags)}';
    final LearningDeck deck = decodeDeckJson(
      File(deckPath).readAsStringSync(),
    );
    return <String>[for (final LearningUnit unit in deck.units) line(unit)];
  }

  // Messages are asserted with `findsWidgets`: the File operations screen
  // prints the latest status as well as the SnackBar.

  testWidgets('the open deck takes the new version\'s units with its own '
      'flags, the incoming file stays as it was, and the counts are '
      'reported', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'mine', 'words.vok');
    final String incomingPath = p.join(temp.path, 'author', 'words.vok');
    Directory(p.dirname(deckPath)).createSync();
    Directory(p.dirname(incomingPath)).createSync();
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(_maskId, <LearningUnit>[
          _word('house', 'Haus', d1: _manual),
          _word('neighbour', 'Nachbarr', d2: _automatic),
          _word('dog', 'Hund', d1: _manual),
        ]),
      ),
    );
    final LocalTimestamp authored = LocalTimestamp.tryParse(
      '2026-09-20T10:00:00+02:00',
    )!;
    File(incomingPath).writeAsStringSync(
      encodeDeckJson(
        _deck(_maskId, <LearningUnit>[
          _word('garden', 'Garten', d1: _manual),
          _word('neighbour', 'Nachbar', d1: _automatic),
          _word('house', 'Haus'),
        ]).copyWith(lastEdited: authored),
      ),
    );
    final List<int> incomingBytes = File(incomingPath).readAsBytesSync();

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = await openDeck(tester, deckPath);
      picker.nextOpenPath = incomingPath;
      await pickMenuItem(tester, 'File', _update);

      final Finder message = find.text(
        'Updated “words.vok” to the new version: 2 flags carried over, 1 '
        'dropped because their unit no longer exists.',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      // The author's flags on "garden" and "neighbour" are gone; the
      // learner's follow "house" (moved) and "neighbour" (typo fixed).
      expect(flagsOnDisk(deckPath), <String>[
        'garden:--/--',
        'neighbour:--/-A',
        'house:M-/--',
      ]);
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).lastEdited,
        authored,
      );
      expect(File(incomingPath).readAsBytesSync(), incomingBytes);
    });
  });

  testWidgets('an undated new version is dated now', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String incomingPath = p.join(temp.path, 'words-new.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck(_maskId, <LearningUnit>[_word('house', 'Haus')])),
    );
    File(incomingPath).writeAsStringSync(
      encodeDeckJson(
        _deck(_maskId, <LearningUnit>[
          _word('house', 'Haus'),
          _word('tree', 'Baum'),
        ]),
      ),
    );

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = await openDeck(tester, deckPath);
      picker.nextOpenPath = incomingPath;
      final DateTime before = DateTime.now().subtract(
        const Duration(seconds: 2),
      );
      await pickMenuItem(tester, 'File', _update);

      final Finder message = find.textContaining('to the new version');
      await until(tester, () => message.evaluate().isNotEmpty);
      final LearningDeck onDisk = decodeDeckJson(
        File(deckPath).readAsStringSync(),
      );
      expect(onDisk.units, hasLength(2));
      expect(onDisk.lastEdited, isNotNull);
      expect(onDisk.lastEdited!.instant.isAfter(before), isTrue);
    });
  });

  testWidgets('a file on a different mask is refused and nothing is written', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String incomingPath = p.join(temp.path, 'other.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(_maskId, <LearningUnit>[_word('house', 'Haus', d1: _manual)]),
      ),
    );
    File(incomingPath).writeAsStringSync(
      encodeDeckJson(
        _deck('m_new_another-deck', <LearningUnit>[_word('house', 'Haus')]),
      ),
    );
    final List<int> deckBytes = File(deckPath).readAsBytesSync();

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = await openDeck(tester, deckPath);
      picker.nextOpenPath = incomingPath;
      await pickMenuItem(tester, 'File', _update);

      final Finder message = find.text(
        'Cannot update: the selected file is not a version of this deck (it '
        'belongs to a different mask).',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      expect(File(deckPath).readAsBytesSync(), deckBytes);
    });
  });

  testWidgets('a new version that would lose data on the newer mask is '
      'refused with what it would lose', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'words.vok');
    final String incomingPath = p.join(temp.path, 'old-author.vok');
    // The open deck's newer revision shortened the answer below what the
    // older incoming file stores.
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(
          _maskId,
          <LearningUnit>[_word('house', 'Haus', d1: _manual)],
          revision: 2,
          answerLength: 4,
        ),
      ),
    );
    File(incomingPath).writeAsStringSync(
      encodeDeckJson(
        _deck(_maskId, <LearningUnit>[_word('house', 'Hausmeister')]),
      ),
    );
    final List<int> deckBytes = File(deckPath).readAsBytesSync();

    await tester.runAsync(() async {
      final _ScriptedFilePicker picker = await openDeck(tester, deckPath);
      picker.nextOpenPath = incomingPath;
      await pickMenuItem(tester, 'File', _update);

      final Finder message = find.textContaining(
        'Shortening field "Answer" in category "Default" to 4 would '
        'truncate 1 unit(s).',
      );
      await until(tester, () => message.evaluate().isNotEmpty);
      expect(message, findsWidgets);
      expect(find.textContaining('would lose data:'), findsWidgets);
      expect(File(deckPath).readAsBytesSync(), deckBytes);
    });
  });
}

const String _maskId = 'm_new_update-new-version-shell';

LearningUnit _word(
  String question,
  String answer, {
  DifficultFlags d1 = DifficultFlags.none,
  DifficultFlags d2 = DifficultFlags.none,
}) {
  return LearningUnit(
    categoryId: 1,
    fields: <int, FieldValue>{
      0: FieldValue.plain(question),
      1: FieldValue.plain(answer),
    },
    direction1Flags: d1,
    direction2Flags: d2,
  );
}

LearningDeck _deck(
  String maskId,
  List<LearningUnit> units, {
  int revision = 0,
  int answerLength = 40,
}) {
  return LearningDeck(
    mask: LearningMask(
      maskId: maskId,
      name: 'Sample',
      direction1Label: 'Direction 1',
      direction2Label: 'Direction 2',
      revision: revision,
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 1,
          name: 'Default',
          fields: <FieldDefinition>[
            const FieldDefinition(
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
              length: answerLength,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
            ),
          ],
        ),
      ],
    ),
    units: units,
  );
}
