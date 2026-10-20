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

/// How the recent-decks list writes a date: `YYYY-MM-DD HH:MM` on this
/// machine's clock.
String _minute(DateTime when) {
  final DateTime local = when.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  late String alpha;
  late String beta;
  final LocalTimestamp betaEdited = LocalTimestamp.tryParse(
    '2026-01-02T03:04:05+01:00',
  )!;
  final DateTime betaLearned = DateTime(2026, 3, 4, 17, 45, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_last_edited_');
    addTearDown(() => temp.deleteSync(recursive: true));
    // Fixture writes stay synchronous: a real async dart:io Future awaited
    // in a testWidgets body before the first pump never completes (see
    // mask_sync_shell_test.dart).
    alpha = p.join(temp.path, 'alpha.vok');
    beta = p.join(temp.path, 'beta.vok');
    File(alpha).writeAsStringSync(encodeDeckJson(_deck('one')));
    File(beta).writeAsStringSync(
      encodeDeckJson(_deck('uno').copyWith(lastEdited: betaEdited)),
    );
    File(p.join(temp.path, 'statistics', 'beta.sta'))
      ..parent.createSync()
      ..writeAsStringSync(
        encodeStatisticsJson(
          const StatisticsFile(
            deckRef: 'beta.vok',
            perUnit: <UnitStats>[UnitStats(index: 1)],
          ),
        ),
      )
      ..setLastModifiedSync(betaLearned);
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

  Future<void> loadDeck(
    WidgetTester tester,
    _ScriptedFilePicker picker,
    String path,
  ) async {
    picker.nextOpenPath = path;
    await pickMenuItem(tester, 'File', 'Load deck...');
  }

  /// Back to the workspace. Loading and saving leave the learner on the File
  /// operations screen, which Esc deliberately does not close, so this goes
  /// the way a learner would: through another screen and out of it.
  Future<void> goHome(WidgetTester tester) async {
    await tester.tap(find.text('Lexicon'));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleAfterIo(tester);
  }

  testWidgets('editing a unit and saving dates the deck, and the recent decks '
      'show when each was last edited and last learned', (
    WidgetTester tester,
  ) async {
    final _ScriptedFilePicker picker = _ScriptedFilePicker();
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LearnAnywhereDesktopApp(
          prefs: prefs,
          filePicker: picker,
          settingsPath: p.join(temp.path, 'settings.json'),
        ),
      );
      await settleAfterIo(tester);

      await loadDeck(tester, picker, beta);
      await loadDeck(tester, picker, alpha);

      await pickMenuItem(tester, 'Edit', 'Unit editor');
      await tester.enterText(find.byType(TextField).first, 'one, edited');
      await settle(tester);
      await tester.tap(find.text('Done'));
      await settle(tester);

      final DateTime before = DateTime.now();
      await pickMenuItem(tester, 'File', 'Save deck');
      final DateTime after = DateTime.now();

      final LearningDeck saved = decodeDeckJson(File(alpha).readAsStringSync());
      expect(saved.units.single.valueForFieldId(0).plainText, 'one, edited');
      final LocalTimestamp edited = saved.lastEdited!;
      expect(
        edited.instant.isBefore(
          before.toUtc().subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(edited.instant.isAfter(after.toUtc()), isFalse);
      expect(edited.offset, after.timeZoneOffset);

      // The other deck, dated in its file and learned beside it.
      await goHome(tester);
      expect(
        find.text(
          'Last edited: ${_minute(betaEdited.instant)} · '
          'Last learned: ${_minute(betaLearned)}',
        ),
        findsOneWidget,
      );

      // And the deck just saved, from the other side.
      await loadDeck(tester, picker, beta);
      await goHome(tester);
      expect(
        find.textContaining('Last edited: ${_minute(edited.instant)} · '),
        findsOneWidget,
      );
    });
  });
}

LearningDeck _deck(String term) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_last-edited-shell',
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
