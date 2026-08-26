import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [DesktopFilePicker] that opens no native dialog and instead records the
/// starting directory it was asked for.
///
/// Every dialog answers "cancelled" (null) except [pickDirectory], which
/// returns [directoryToReturn] so the Options prompt can be driven to the end.
final class _RecordingFilePicker extends DesktopFilePicker {
  _RecordingFilePicker({this.directoryToReturn});

  final String? directoryToReturn;

  final List<({String extension, String? directory})> openCalls =
      <({String extension, String? directory})>[];
  final List<({String extension, String? directory})> saveCalls =
      <({String extension, String? directory})>[];
  final List<String?> directoryCalls = <String?>[];

  /// The directory of the last dialog of any kind.
  String? get lastDirectory => <String?>[
    ...openCalls.map((({String extension, String? directory}) c) => c.directory),
    ...saveCalls.map((({String extension, String? directory}) c) => c.directory),
    ...directoryCalls,
  ].last;

  String? directoryOfOpen(String extension) => openCalls
      .lastWhere(
        (({String extension, String? directory}) c) => c.extension == extension,
      )
      .directory;

  String? directoryOfSave(String extension) => saveCalls
      .lastWhere(
        (({String extension, String? directory}) c) => c.extension == extension,
      )
      .directory;

  @override
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async {
    openCalls.add((extension: extension, directory: initialDirectory));
    return null;
  }

  @override
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async {
    saveCalls.add((extension: extension, directory: initialDirectory));
    return null;
  }

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async {
    directoryCalls.add(initialDirectory);
    return directoryToReturn;
  }
}

void main() {
  late DesktopPrefs prefs;
  late Directory startFolder;
  late Directory rememberedFolder;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    startFolder = Directory.systemTemp.createTempSync('la_start_');
    rememberedFolder = Directory.systemTemp.createTempSync('la_remembered_');
    addTearDown(() {
      for (final Directory dir in <Directory>[startFolder, rememberedFolder]) {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  /// Pumps the shell on a surface wide enough for the whole menu bar, so no
  /// test has to drag the bar sideways to reach a menu.
  Future<void> pumpShell(
    WidgetTester tester,
    _RecordingFilePicker picker,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(prefs: prefs, filePicker: picker),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickMenuItem(
    WidgetTester tester,
    String menu,
    String item,
  ) async {
    await tester.tap(find.text(menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the start folder outranks the remembered directory everywhere', (
    WidgetTester tester,
  ) async {
    // Every remembered directory points elsewhere — as it would right after
    // saving somewhere other than the start folder.
    prefs.setLastDirVok(rememberedFolder.path);
    prefs.setLastDirSta(rememberedFolder.path);
    prefs.setLastDirInf(rememberedFolder.path);
    prefs.setStartFolder(startFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'File', 'Load deck...');
    await pickMenuItem(tester, 'File', 'Load stats...');
    await pickMenuItem(tester, 'File', 'Save mask as...');

    expect(picker.directoryOfOpen('vok'), startFolder.path);
    expect(picker.directoryOfOpen('sta'), startFolder.path);
    expect(picker.directoryOfSave('inf'), startFolder.path);
  });

  testWidgets('the lexicon file search opens at the start folder', (
    WidgetTester tester,
  ) async {
    prefs.setLastDirFileSearch(rememberedFolder.path);
    prefs.setStartFolder(startFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await tester.tap(find.text('Lexicon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search files'));
    await tester.pumpAndSettle();

    expect(picker.directoryCalls, <String?>[startFolder.path]);
  });

  testWidgets('the mask-copies dialog ignores the start folder', (
    WidgetTester tester,
  ) async {
    // With no deck open it falls back to the last mask directory; with one open
    // it uses that deck's folder. Neither is the start folder — deliberately.
    prefs.setLastDirInf(rememberedFolder.path);
    prefs.setStartFolder(startFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'Edit', 'Update other copies of this mask...');

    expect(picker.directoryCalls, <String?>[rememberedFolder.path]);
  });

  testWidgets('a start folder that no longer exists falls through silently', (
    WidgetTester tester,
  ) async {
    prefs.setLastDirVok(rememberedFolder.path);
    prefs.setStartFolder(startFolder.path);
    startFolder.deleteSync();
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'File', 'Load deck...');

    // The dialog still opened, at the remembered directory.
    expect(picker.directoryOfOpen('vok'), rememberedFolder.path);

    // The setting is kept, but the prompt admits it is not in force.
    await pickMenuItem(tester, 'Options', 'Start folder...');
    expect(find.text(startFolder.path), findsOneWidget);
    expect(
      find.textContaining('This folder cannot be reached'),
      findsOneWidget,
    );
  });

  testWidgets('with no start folder set the remembered directory is used', (
    WidgetTester tester,
  ) async {
    prefs.setLastDirVok(rememberedFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'File', 'Load deck...');

    expect(picker.directoryOfOpen('vok'), rememberedFolder.path);
  });

  testWidgets('the Options menu sets a start folder that outlives a relaunch', (
    WidgetTester tester,
  ) async {
    prefs.setLastDirVok(rememberedFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker(
      directoryToReturn: startFolder.path,
    );
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'Options', 'Start folder...');
    expect(find.text('No start folder set'), findsOneWidget);
    await tester.tap(find.text('Choose folder...'));
    await tester.pumpAndSettle();

    expect(prefs.startFolder, startFolder.path);
    // In force immediately, with no restart.
    await pickMenuItem(tester, 'File', 'Load deck...');
    expect(picker.directoryOfOpen('vok'), startFolder.path);

    // Relaunching reads the setting back from the preference store.
    final _RecordingFilePicker relaunched = _RecordingFilePicker();
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    await pumpShell(tester, relaunched);
    await pickMenuItem(tester, 'File', 'Load deck...');
    expect(relaunched.directoryOfOpen('vok'), startFolder.path);
  });

  testWidgets('clearing the start folder restores the remembered directory', (
    WidgetTester tester,
  ) async {
    prefs.setLastDirVok(rememberedFolder.path);
    prefs.setStartFolder(startFolder.path);
    final _RecordingFilePicker picker = _RecordingFilePicker();
    await pumpShell(tester, picker);

    await pickMenuItem(tester, 'Options', 'Start folder...');
    expect(find.text(startFolder.path), findsOneWidget);
    await tester.tap(find.text('Clear start folder'));
    await tester.pumpAndSettle();

    expect(prefs.startFolder, isNull);
    await pickMenuItem(tester, 'File', 'Load deck...');
    expect(picker.directoryOfOpen('vok'), rememberedFolder.path);
  });
}
