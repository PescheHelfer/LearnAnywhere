import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Opens [nextDeckPath] for a `.vok` dialog, cancels every other dialog, and
/// records the folder each `.sta` dialog was asked to start in.
final class _RecordingFilePicker extends DesktopFilePicker {
  String? nextDeckPath;
  final List<String?> staOpenFolders = <String?>[];
  final List<String?> staSaveFolders = <String?>[];

  @override
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async {
    if (extension == 'sta') {
      staOpenFolders.add(initialDirectory);
      return null;
    }
    return nextDeckPath;
  }

  @override
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async {
    if (extension == 'sta') {
      staSaveFolders.add(initialDirectory);
    }
    return null;
  }

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => null;
}

void main() {
  late DesktopPrefs prefs;
  late Directory temp;
  late Directory startFolder;
  late String deck;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    temp = Directory.systemTemp.createTempSync('la_stats_dialog_');
    startFolder = Directory(p.join(temp.path, 'start'))..createSync();
    addTearDown(() => temp.deleteSync(recursive: true));
    prefs.setStartFolder(startFolder.path);
    // Synchronous on purpose: see last_edited_shell_test.dart.
    final Directory decks = Directory(p.join(temp.path, 'decks'))..createSync();
    deck = p.join(decks.path, 'alpha.vok');
    File(deck).writeAsStringSync(encodeDeckJson(_deck()));
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }

  Future<void> pickMenuItem(
    WidgetTester tester,
    String menu,
    String item,
  ) async {
    await tester.tap(find.text(menu));
    await settle(tester);
    await tester.tap(find.text(item).last);
    await settle(tester);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await settle(tester);
  }

  /// Loads the deck, then opens both statistics dialogs.
  Future<_RecordingFilePicker> openStatisticsDialogs(
    WidgetTester tester,
  ) async {
    final _RecordingFilePicker picker = _RecordingFilePicker();
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
      await settle(tester);
      picker.nextDeckPath = deck;
      await pickMenuItem(tester, 'File', 'Load deck...');
      await pickMenuItem(tester, 'File', 'Load stats...');
      await pickMenuItem(tester, 'File', 'Save stats as...');
    });
    return picker;
  }

  testWidgets("with the deck's statistics folder present both statistics "
      'dialogs start in it, ahead of the start folder', (
    WidgetTester tester,
  ) async {
    final String statistics = p.join(p.dirname(deck), 'statistics');
    Directory(statistics).createSync();

    final _RecordingFilePicker picker = await openStatisticsDialogs(tester);

    expect(picker.staOpenFolders, <String?>[statistics]);
    expect(picker.staSaveFolders, <String?>[statistics]);
  });

  testWidgets('without a statistics folder the start folder still applies', (
    WidgetTester tester,
  ) async {
    final _RecordingFilePicker picker = await openStatisticsDialogs(tester);

    expect(picker.staOpenFolders, <String?>[startFolder.path]);
    expect(picker.staSaveFolders, <String?>[startFolder.path]);
  });
}

LearningDeck _deck() {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_stats-folder-shell',
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
          0: const FieldValue.plain('term'),
          1: const FieldValue.plain('answer'),
        },
      ),
    ],
  );
}
