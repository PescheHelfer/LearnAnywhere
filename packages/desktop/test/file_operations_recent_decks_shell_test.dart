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

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  late String alpha;
  late String beta;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_file_ops_recent_');
    addTearDown(() => temp.deleteSync(recursive: true));
    // Fixture writes stay synchronous: a real async dart:io Future awaited
    // in a testWidgets body before the first pump never completes (see
    // mask_sync_shell_test.dart).
    alpha = p.join(temp.path, 'alpha.vok');
    beta = p.join(temp.path, 'beta.vok');
    File(alpha).writeAsStringSync(encodeDeckJson(_deck('one')));
    File(beta).writeAsStringSync(encodeDeckJson(_deck('uno')));
  });

  // The same bounded settle the mask-sync shell test uses: the whole body runs
  // inside one `tester.runAsync`, so real dart:io completes, and
  // `pumpAndSettle` must not be nested in it.
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
    await tester.tap(find.text(menu));
    await settle(tester);
    await tester.tap(find.text(item).last);
    await settleAfterIo(tester);
  }

  Future<void> pumpShell(WidgetTester tester, _ScriptedFilePicker picker) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: p.join(temp.path, 'settings.json'),
        speechEngine: const UnavailableTtsEngine(),
      ),
    );
    await settleAfterIo(tester);
  }

  /// Opens alpha, then beta, through File ▸ Load deck..., leaving the learner
  /// on the File operations screen with beta open and alpha one entry back.
  Future<void> openAlphaThenBeta(
    WidgetTester tester,
    _ScriptedFilePicker picker,
  ) async {
    picker.nextOpenPath = alpha;
    await pickMenuItem(tester, 'File', 'Load deck...');
    picker.nextOpenPath = beta;
    await pickMenuItem(tester, 'File', 'Load deck...');
  }

  testWidgets('after opening a deck, File operations lists the other recent '
      'decks below the status line, and one tap opens one', (
    WidgetTester tester,
  ) async {
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.runAsync(() async {
      await pumpShell(tester, picker);
      await openAlphaThenBeta(tester, picker);

      expect(find.text('File operations'), findsWidgets);
      expect(find.text('Deck loaded.'), findsWidgets);
      expect(find.text('Recent decks:'), findsOneWidget);
      expect(find.text(DeckPaths.folderAndFileName(alpha)), findsOneWidget);
      // The open deck is left out, as on the Workspace.
      expect(find.text(DeckPaths.folderAndFileName(beta)), findsNothing);
      // The same dates line the Workspace shows.
      expect(find.textContaining('Last edited: '), findsOneWidget);

      await tester.tap(find.text(DeckPaths.folderAndFileName(alpha)));
      await settleAfterIo(tester);

      expect(find.text('Deck: $alpha'), findsOneWidget);
      // Now beta is the one offered, and alpha is gone from the list.
      expect(find.text(DeckPaths.folderAndFileName(beta)), findsOneWidget);
      expect(find.text(DeckPaths.folderAndFileName(alpha)), findsNothing);
    });
  });

  testWidgets('the list stays after an operation other than opening', (
    WidgetTester tester,
  ) async {
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.runAsync(() async {
      await pumpShell(tester, picker);
      await openAlphaThenBeta(tester, picker);

      await pickMenuItem(tester, 'File', 'Save deck');

      expect(find.text('Deck saved.'), findsWidgets);
      expect(find.text('Recent decks:'), findsOneWidget);
      expect(find.text(DeckPaths.folderAndFileName(alpha)), findsOneWidget);
    });
  });
}

LearningDeck _deck(String term) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_file-ops-recent-shell',
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
          0: FieldValue.plain(term),
          1: const FieldValue.plain('answer'),
        },
      ),
    ],
  );
}
