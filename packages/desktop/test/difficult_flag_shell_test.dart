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
  Future<void> startSession(WidgetTester tester, String deckPath) async {
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

  testWidgets('F12 writes the manual flag to the deck at once and F12 again '
      'removes it, in the question and in the answer stage; the badge follows '
      'and the last-edited date does not move', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'deck.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      expect(find.text('Difficult (manual flag)'), findsNothing);

      // Question stage.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult', present: true);
      expect(unitOnDisk(deckPath)['manualDifficult'], isTrue);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult'), isFalse);
      expect(find.text('Difficult (manual flag)'), findsOneWidget);
      // A flag is not an edit: the stored date is the one it had.
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).lastEdited,
        edited,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult', present: false);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult'), isFalse);
      expect(find.text('Difficult (manual flag)'), findsNothing);

      // Answer stage: F12, then the pill.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await settle(tester);
      expect(find.text('Continue'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'manualDifficult', present: true);
      expect(unitOnDisk(deckPath)['manualDifficult'], isTrue);
      expect(find.text('Difficult (manual flag)'), findsOneWidget);

      await tester.tap(find.text('Difficult'));
      await untilOnDisk(tester, deckPath, 'manualDifficult', present: false);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult'), isFalse);
      expect(find.text('Difficult (manual flag)'), findsNothing);
      // Still in the session, still on the answer.
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  testWidgets('F12 on an automatically flagged unit removes the flag', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'auto.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck(autoDifficult: true)),
    );
    await tester.runAsync(() async {
      await startSession(tester, deckPath);
      expect(find.text('Difficult (automatic flag)'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await untilOnDisk(tester, deckPath, 'autoDifficult', present: false);
      expect(unitOnDisk(deckPath).containsKey('autoDifficult'), isFalse);
      expect(unitOnDisk(deckPath).containsKey('manualDifficult'), isFalse);
      expect(find.text('Difficult (automatic flag)'), findsNothing);
      expect(find.text('Difficult (manual flag)'), findsNothing);
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
      await untilOnDisk(tester, deckPath, 'manualDifficult', present: true);
      final LearningDeck onDisk = decodeDeckJson(
        File(deckPath).readAsStringSync(),
      );
      expect(onDisk.units.single.manualDifficult, isTrue);
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
      expect(find.text('Difficult (manual flag)'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
    });
  });
}

LearningDeck _deck({bool autoDifficult = false}) {
  return LearningDeck(
    mask: const LearningMask(
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
        autoDifficult: autoDifficult,
      ),
    ],
  );
}
