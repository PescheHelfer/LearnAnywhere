import 'dart:convert';
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
    temp = Directory.systemTemp.createTempSync('la_difficult_flag_');
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

  /// Opens the app on [deckPath] and starts a session on its only unit.
  Future<void> startSession(
    WidgetTester tester,
    String deckPath, {
    TtsEngine? speechEngine,
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: p.join(temp.path, 'settings.json'),
        speechEngine: speechEngine,
      ),
    );
    await settleAfterIo(tester);
    picker.nextOpenPath = deckPath;
    await pickMenuItem(tester, 'File', 'Load deck...');
    await pickMenuItem(tester, 'Learn', 'Practice setup');
    await tester.tap(find.text('Start session'));
    await settleAfterIo(tester);
    expect(find.text('Check'), findsOneWidget);
  }

  /// The single unit's keys exactly as they stand in the file on disk.
  Map<String, Object?> unitOnDisk(String deckPath) {
    final Map<String, Object?> json =
        jsonDecode(File(deckPath).readAsStringSync()) as Map<String, Object?>;
    return (json['units']! as List<Object?>).single! as Map<String, Object?>;
  }

  /// Waits until [key] is [present] in the unit on disk — polled, not a fixed
  /// sleep, so a slow host only takes longer — then settles, so the screen
  /// reflects the write too. Gives up after five seconds and lets the
  /// caller's expectation report what the file holds.
  Future<void> untilOnDisk(
    WidgetTester tester,
    String deckPath,
    String key, {
    required bool present,
  }) async {
    bool landed() {
      try {
        return unitOnDisk(deckPath).containsKey(key) == present;
      } on FormatException {
        // Caught mid-write: the file is truncated before it is rewritten.
        return false;
      }
    }

    for (var i = 0; i < 100; i += 1) {
      if (landed()) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await settle(tester);
  }

  /// The session's difficulty badge.
  final Finder badge = find.byKey(const Key('learnDifficultBadge'));

  /// Finds [icon] inside the badge.
  Finder badgeShows(IconData icon) =>
      find.descendant(of: badge, matching: find.byIcon(icon));

  /// Every label and key hint in the row keyed [rowKey], in reading order.
  List<String?> rowTexts(String rowKey) => find
      .descendant(of: find.byKey(Key(rowKey)), matching: find.byType(Text))
      .evaluate()
      .map((Element e) => (e.widget as Text).data)
      .toList();

  final Finder readAloudPill = find.byKey(const Key('learnReadAloudPill'));

  testWidgets('the session pills run in key order in both stages, and Read '
      'aloud appears with the answer and plays it', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'spoken.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(speakAnswer: true)));
    final _RecordingTtsEngine engine = _RecordingTtsEngine();
    await tester.runAsync(() async {
      await startSession(tester, deckPath, speechEngine: engine);

      // No answer on screen yet, so F4 would say nothing and no pill offers
      // it; Cancel ends its group and Difficult follows.
      expect(readAloudPill, findsNothing);
      expect(rowTexts('learnQuestionPills'), <String>[
        'Check', 'F10', //
        'Cancel', 'Esc', //
        'Difficult', 'F12', //
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      expect(rowTexts('learnActionPillsGroup'), <String>[
        'Continue', 'F3', //
        'Read aloud', 'F4', //
        'Correction', 'Switch: F9', //
        'Cancel', 'Esc', //
      ]);
      expect(rowTexts('learnEvaluationPillsGroup'), <String>[
        'Evaluate as:', //
        'Wrong', 'F5', //
        'Actually correct', 'F6', //
        'No count', 'F7', //
      ]);
      // The groups keep their order, Difficult on its own at the end.
      expect(rowTexts('learnAnswerPills'), <String?>[
        ...rowTexts('learnActionPillsGroup'),
        ...rowTexts('learnEvaluationPillsGroup'),
        'Difficult', 'F12', //
      ]);

      await tester.tap(readAloudPill);
      await settle(tester);
      expect(engine.spoken, <String>['Haus']);
      // Still on the answer: listening is not a rating.
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a host that cannot speak offers no Read aloud pill', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'silent.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck(speakAnswer: true)));
    await tester.runAsync(() async {
      await startSession(
        tester,
        deckPath,
        speechEngine: const UnavailableTtsEngine(),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      expect(find.text('Continue'), findsOneWidget);
      expect(readAloudPill, findsNothing);
      expect(rowTexts('learnActionPillsGroup'), <String>[
        'Continue', 'F3', //
        'Correction', 'Switch: F9', //
        'Cancel', 'Esc', //
      ]);
    });
  });

  testWidgets('F12 writes the manual flag to the deck at once and F12 again '
      'removes it, in the question and in the answer stage; the badge follows '
      'and the last-edited date does not move', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'deck.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      expect(find.byTooltip('Manual flag'), findsNothing);

      // Question stage.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      expect(unitOnDisk(deckPath)['manualDifficult1'], isTrue);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult1'), isFalse);
      expect(find.byTooltip('Manual flag'), findsOneWidget);
      // The badge: the manual flag's icon, then "Difficult".
      expect(badgeShows(Icons.flag), findsOneWidget);
      expect(badgeShows(Icons.auto_awesome), findsNothing);
      expect(
        find.descendant(of: badge, matching: find.text('Difficult')),
        findsOneWidget,
      );
      // A flag is not an edit: the stored date is the one it had.
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).lastEdited,
        edited,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: false);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);
      expect(find.byTooltip('Manual flag'), findsNothing);

      // Answer stage: F12, then the pill.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      expect(find.text('Continue'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      expect(unitOnDisk(deckPath)['manualDifficult1'], isTrue);
      expect(find.byTooltip('Manual flag'), findsOneWidget);

      await tester.tap(find.byKey(const Key('learnDifficultPill')));
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: false);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);
      expect(find.byTooltip('Manual flag'), findsNothing);
      // Still in the session, still on the answer.
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  testWidgets('F12 on an automatically flagged unit removes the flag', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'auto.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(direction1Flags: const DifficultFlags(automatic: true)),
      ),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      expect(find.byTooltip('Automatic flag'), findsOneWidget);
      expect(badgeShows(Icons.auto_awesome), findsOneWidget);
      expect(badgeShows(Icons.flag), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'autoDifficult1', present: false);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult1'), isFalse);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);
      expect(find.byTooltip('Automatic flag'), findsNothing);
      expect(find.byTooltip('Manual flag'), findsNothing);
    });
  });

  testWidgets('F12 on an automatically flagged unit cycles none, manual, the '
      'automatic flag back, none; a card served again starts over from what is '
      'on disk', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'cycle.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(direction1Flags: const DifficultFlags(automatic: true)),
      ),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      Future<void> press(String key, {required bool present}) async {
        await tester.sendKeyEvent(LogicalKeyboardKey.f12);
        await untilOnDisk(tester, deckPath, key, present: present);
      }

      Set<String> flagKeys() => unitOnDisk(deckPath).keys
          .where((String k) => k.contains('Difficult'))
          .toSet();

      await press('autoDifficult1', present: false);
      expect(flagKeys(), isEmpty);
      await press('manualDifficult1', present: true);
      expect(flagKeys(), <String>{'manualDifficult1'});
      expect(badgeShows(Icons.flag), findsOneWidget);
      await press('autoDifficult1', present: true);
      expect(flagKeys(), <String>{'autoDifficult1'});
      expect(badgeShows(Icons.auto_awesome), findsOneWidget);
      await press('autoDifficult1', present: false);
      expect(flagKeys(), isEmpty);

      // Serve the unit again: what is on disk now (no flag) is the start, so
      // the flag removed on the earlier card is gone for good.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settleAfterIo(tester);
      expect(find.text('Check'), findsOneWidget);
      await press('manualDifficult1', present: true);
      expect(flagKeys(), <String>{'manualDifficult1'});
      await press('manualDifficult1', present: false);
      expect(flagKeys(), isEmpty);
    });
  });

  testWidgets('F12 on a unit with no automatic flag toggles between none and '
      'manual only', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'plain.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(direction1Flags: const DifficultFlags(manual: true)),
      ),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: false);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult1'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult1'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: false);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult1'), isFalse);
    });
  });

  testWidgets('in a Direction 2 question F12 writes the Direction 2 manual '
      'flag at once, and the badge and pill show only that direction', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'direction2.vok');
    // Difficult in Direction 1 only, by the program's verdict.
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        _deck(direction1Flags: const DifficultFlags(automatic: true)),
      ),
    );
    File(p.join(temp.path, 'settings.json')).writeAsStringSync(
      encodeSettingsJson(
        const LearnAnywhereSettings(direction: DirectionSelection.direction2),
      ),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      // Asked the other way round: the unit is not difficult this way.
      expect(find.text('Haus', findRichText: true), findsOneWidget);
      expect(find.byTooltip('Automatic flag'), findsNothing);
      expect(find.byKey(const Key('learnDifficultBadge')), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult2', present: true);
      expect(unitOnDisk(deckPath)['manualDifficult2'], isTrue);
      // Direction 1 keeps exactly what it had.
      expect(unitOnDisk(deckPath)['autoDifficult1'], isTrue);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult2'), isFalse);
      expect(find.byTooltip('Manual flag'), findsOneWidget);

      // The pill unmarks Direction 2 only.
      await tester.tap(find.byKey(const Key('learnDifficultPill')));
      await untilOnDisk(tester, deckPath, 'manualDifficult2', present: false);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult2'), isFalse);
      expect(unitOnDisk(deckPath)['autoDifficult1'], isTrue);
      expect(find.byKey(const Key('learnDifficultBadge')), findsNothing);
    });
  });

  testWidgets('a flag write also saves unit edits pending from the sitting, '
      'and those date the deck', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'pending.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final _ScriptedFilePicker picker = _ScriptedFilePicker()
        ..nextOpenPath = deckPath;
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: picker,
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);
      await pickMenuItem(tester, 'File', 'Load deck...');
      await pickMenuItem(tester, 'Edit', 'Unit editor');
      await tester.enterText(find.byType(TextField).first, 'home');
      await settle(tester);
      await tester.tap(find.text('Done'));
      await settle(tester);
      await pickMenuItem(tester, 'Learn', 'Practice setup');
      await tester.tap(find.text('Start session'));
      await settleAfterIo(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      final LearningDeck onDisk = decodeDeckJson(
        File(deckPath).readAsStringSync(),
      );
      expect(onDisk.units.single.direction1Flags.manual, isTrue);
      expect(onDisk.units.single.valueForFieldId(0).plainText, 'home');
      expect(onDisk.lastEdited, isNot(edited));
      expect(onDisk.lastEdited!.instant.isAfter(edited.instant), isTrue);
    });
  });

  testWidgets('a deck that cannot be written names the file and the session '
      'carries on', (WidgetTester tester) async {
    final Directory gone = Directory(p.join(temp.path, 'gone'))..createSync();
    final String deckPath = p.join(gone.path, 'unwritable.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck()));
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      // Nowhere left to write to.
      gone.deleteSync(recursive: true);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settleAfterIo(tester);
      expect(find.textContaining('"unwritable.vok"'), findsOneWidget);
      // The verdict is kept in memory, and the session is where it was.
      expect(find.byTooltip('Manual flag'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
    });
  });

  testWidgets('F12 in the unit editor writes nothing until the editor '
      'saves, and a flag-only save leaves the last-edited date unchanged', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'editor.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final _ScriptedFilePicker picker = _ScriptedFilePicker()
        ..nextOpenPath = deckPath;
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: picker,
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);
      await pickMenuItem(tester, 'File', 'Load deck...');
      await pickMenuItem(tester, 'Edit', 'Unit editor');

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settle(tester);
      expect(find.byTooltip('Manual flag'), findsOneWidget);
      // Nothing reaches disk from the editor on its own.
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);

      // Cancelling drops the flag change along with everything else pending.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.text('Please confirm'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);

      await pickMenuItem(tester, 'Edit', 'Unit editor');
      expect(find.byTooltip('Manual flag'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settle(tester);
      expect(find.byTooltip('Manual flag'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await settle(tester);
      // Still not written: Done keeps the change in memory only.
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);

      await pickMenuItem(tester, 'File', 'Save deck');
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      final LearningDeck onDisk = decodeDeckJson(
        File(deckPath).readAsStringSync(),
      );
      expect(onDisk.units.single.direction1Flags.manual, isTrue);
      // A flag is not an edit: the stored date is the one it had.
      expect(onDisk.lastEdited, edited);
    });
  });

  testWidgets('the editor\'s pills follow the pending flags, its row is in '
      'key order, and Shift+F12 saves Direction 2 alone', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'editor_direction2.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final _ScriptedFilePicker picker = _ScriptedFilePicker()
        ..nextOpenPath = deckPath;
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: picker,
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);
      await pickMenuItem(tester, 'File', 'Load deck...');
      await pickMenuItem(tester, 'Edit', 'Unit editor');

      // Every pill, in F-key order with Done and Cancel last.
      expect(
        find
            .descendant(
              of: find.byKey(const Key('editorActionRow')),
              matching: find.byType(Text),
            )
            .evaluate()
            .map((Element e) => (e.widget as Text).data)
            .toList(),
        <String>[
          'Previous', 'F2', //
          'Next', 'F3', //
          'Search', 'F5', //
          'Jump', 'F6', //
          'Delete', 'F7', //
          'Insert before', 'F8', //
          'Difficult 1', 'F12', //
          'Difficult 2', 'Shift+F12', //
          'Done', 'F10', //
          'Cancel', 'Esc', //
        ],
      );

      bool filled(int direction) => find
          .descendant(
            of: find.byKey(Key('editorDifficultPill$direction')),
            matching: find.byType(FilledButton),
          )
          .evaluate()
          .isNotEmpty;
      expect(filled(1), isFalse);
      expect(filled(2), isFalse);

      // F12, then Cancel: the pill showed it, the file never gets it.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settle(tester);
      expect(filled(1), isTrue);
      expect(filled(2), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult1'), isFalse);

      await pickMenuItem(tester, 'Edit', 'Unit editor');
      expect(filled(1), isFalse);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await settle(tester);
      expect(filled(1), isFalse);
      expect(filled(2), isTrue);
      expect(find.byKey(const Key('editorDifficultBadge1')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('editorDifficultBadge2')),
          matching: find.text('Difficult 2'),
        ),
        findsOneWidget,
      );
      expect(unitOnDisk(deckPath).containsKey('manualDifficult2'), isFalse);

      await tester.tap(find.text('Done'));
      await settle(tester);
      await pickMenuItem(tester, 'File', 'Save deck');
      await untilOnDisk(tester, deckPath, 'manualDifficult2', present: true);
      final Map<String, Object?> unit = unitOnDisk(deckPath);
      expect(unit['manualDifficult2'], isTrue);
      for (final String other in <String>[
        'manualDifficult1',
        'autoDifficult1',
        'autoDifficult2',
      ]) {
        expect(unit.containsKey(other), isFalse, reason: other);
      }
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).lastEdited,
        edited,
      );
    });
  });

  testWidgets('a save with both a flag change and a content edit dates the '
      'deck and keeps both', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'editor_pending.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final _ScriptedFilePicker picker = _ScriptedFilePicker()
        ..nextOpenPath = deckPath;
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: picker,
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);
      await pickMenuItem(tester, 'File', 'Load deck...');
      await pickMenuItem(tester, 'Edit', 'Unit editor');

      await tester.enterText(find.byType(TextField).first, 'home');
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await settle(tester);
      expect(find.byTooltip('Manual flag'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await settle(tester);

      await pickMenuItem(tester, 'File', 'Save deck');
      await untilOnDisk(tester, deckPath, 'manualDifficult1', present: true);
      final LearningDeck onDisk = decodeDeckJson(
        File(deckPath).readAsStringSync(),
      );
      expect(onDisk.units.single.direction1Flags.manual, isTrue);
      expect(onDisk.units.single.valueForFieldId(0).plainText, 'home');
      expect(onDisk.lastEdited, isNot(edited));
      expect(onDisk.lastEdited!.instant.isAfter(edited.instant), isTrue);
    });
  });
}

/// The shell tests' one-unit deck; [speakAnswer] lets the Direction 1 answer
/// field be read aloud in German.
LearningDeck _deck({
  DifficultFlags direction1Flags = DifficultFlags.none,
  bool speakAnswer = false,
}) {
  return LearningDeck(
    mask: LearningMask(
      maskId: 'm_new_difficult-flag-shell',
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
              language: speakAnswer ? 'de-DE' : noSpokenLanguage,
              speak: speakAnswer,
            ),
          ],
        ),
      ],
    ),
    units: <LearningUnit>[
      LearningUnit(
        categoryId: 1,
        fields: const <int, FieldValue>{
          0: FieldValue.plain('house'),
          1: FieldValue.plain('Haus'),
        },
        direction1Flags: direction1Flags,
      ),
    ],
  );
}

/// A host that speaks German and records what it is asked to say instead of
/// saying it.
final class _RecordingTtsEngine implements TtsEngine {
  /// The text of every utterance handed to [speak], in order.
  final List<String> spoken = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<List<SpeechVoice>> voices() async => const <SpeechVoice>[
    SpeechVoice(id: 'de', name: 'German', language: 'de-DE'),
  ];

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    spoken.add(utterance.text);
  }

  @override
  Future<void> stop() async {}
}
