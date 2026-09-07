import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [DesktopFilePicker] that opens no native dialog: `openPath` answers with
/// [openPathToReturn] and `pickDirectory` with [directoryToReturn]; every
/// other dialog is cancelled. Enough to drive File ▸ Load mask... and
/// Edit ▸ Update other copies of this mask... without a filesystem dialog —
/// the technique `start_folder_test.dart`'s `_RecordingFilePicker` uses.
final class _ScriptedFilePicker extends DesktopFilePicker {
  _ScriptedFilePicker({this.openPathToReturn, this.directoryToReturn});

  final String? openPathToReturn;
  final String? directoryToReturn;

  @override
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async => openPathToReturn;

  @override
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async => null;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async =>
      directoryToReturn;
}

void main() {
  late DesktopPrefs prefs;
  late Directory maskDir;
  late Directory scanDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
    maskDir = Directory.systemTemp.createTempSync('la_mask_');
    scanDir = Directory.systemTemp.createTempSync('la_scan_');
    addTearDown(() {
      for (final Directory dir in <Directory>[maskDir, scanDir]) {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });
  });

  // Every interaction below runs from inside a single `tester.runAsync`
  // block (one per test, wrapping the whole body). The shell's own mask
  // load/scan does real, non-fake `dart:io` reads, and a Future's completion
  // is dispatched back into the zone that captured it — the zone active when
  // the triggering tap ran, not whichever zone happens to call `pump()`
  // afterwards. So the tap has to happen inside `runAsync` too, and
  // `pumpAndSettle()` — which loops `pump()` internally — must not be
  // nested inside it; every settle here is a bounded, explicit `pump()`
  // pair instead. `waitForRealIo` yields real wall-clock time so those
  // dart:io reads actually land before the next settle checks state.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }

  Future<void> waitForRealIo() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  Future<void> pumpShell(
    WidgetTester tester,
    _ScriptedFilePicker picker,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(prefs: prefs, filePicker: picker),
    );
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
    await settle(tester);
  }

  /// Loads [path] as a standalone mask through File ▸ Load mask..., which
  /// leaves the document without a deck path — the standalone-mask case the
  /// From: line has to survive.
  Future<void> loadMask(WidgetTester tester) async {
    await pickMenuItem(tester, 'File', 'Load mask...');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await waitForRealIo();
    await settle(tester);
  }

  /// The rendered "From: {path}" line, or null if no such line is on screen.
  ///
  /// Matched by predicate rather than an exact string: the Mask Editor's own
  /// subtitle shows the same path bare (no "From:" prefix), so this only
  /// matches the sync dialog's own line.
  Text? findFromLine(WidgetTester tester) {
    final Iterable<Text> matches = tester
        .widgetList<Text>(find.byType(Text))
        .where((Text t) => t.data?.startsWith('From: ') ?? false);
    return matches.isEmpty ? null : matches.first;
  }

  testWidgets(
    'the reference is the Mask Editor\'s mask when the editor holds one, and '
    'the From: line falls back to the last mask path',
    (WidgetTester tester) async {
      final LearningMask original = _mask(name: 'Original');
      final String originalPath = '${maskDir.path}${Platform.pathSeparator}'
          'original.inf';
      final String copyPath = '${scanDir.path}${Platform.pathSeparator}'
          'copy.inf';
      // Synchronous: a real (non-fake) async dart:io Future awaited directly
      // in a testWidgets body, before the first pump, never observes its own
      // completion — only I/O reached through the widget's own tap/pump
      // cycle does. Fixture writes stay synchronous for that reason.
      File(originalPath).writeAsStringSync(encodeMaskJson(original));
      // The scanned copy is byte-identical to the ORIGINAL document mask, so
      // classifying it against the edited editor mask (name changed, same
      // revision) rather than the document's own mask is the only way it can
      // come out "Differs" instead of "Up to date".
      File(copyPath).writeAsStringSync(encodeMaskJson(original));

      final _ScriptedFilePicker picker = _ScriptedFilePicker(
        openPathToReturn: originalPath,
        directoryToReturn: scanDir.path,
      );
      await tester.runAsync(() async {
        await pumpShell(tester, picker);
        await loadMask(tester);

        await pickMenuItem(tester, 'Edit', 'Mask Editor');
        // Opening the editor re-reads the linked file to confirm it still
        // describes this mask (see _openMaskEditor) — another real read.
        await waitForRealIo();
        await settle(tester);

        await tester.enterText(
          find.byKey(const ValueKey<String>('mask-name-field')),
          'Edited',
        );
        await settle(tester);

        await pickMenuItem(
          tester,
          'Edit',
          'Update other copies of this mask...',
        );
        await waitForRealIo();
        await settle(tester);

        // The reference shown is the editor's own (unsaved) mask, not the
        // document's — its edited name and the "Differs" status prove which
        // mask was actually compared, since only the edited one differs
        // from the on-disk copy.
        expect(find.textContaining('Edited'), findsWidgets);
        expect(find.text('Differs (same revision)'), findsOneWidget);
        expect(find.text('Up to date'), findsNothing);

        // The From: line names the last mask path, because no deck is open.
        final Text? fromLine = findFromLine(tester);
        expect(fromLine, isNotNull);
        expect(fromLine!.data, endsWith('original.inf'));

        // Closing without ticking anything reports that no copies were
        // updated, in the same place a success would be reported.
        // (.last: the Mask Editor underneath has its own Cancel button too.)
        await tester.tap(find.text('Cancel').last);
        await settle(tester);
        expect(find.text('No copies were updated'), findsWidgets);
      });
    },
  );

  testWidgets(
    'the reference falls back to the document\'s mask when the Mask Editor '
    'is not open',
    (WidgetTester tester) async {
      final LearningMask original = _mask(name: 'Original');
      final String originalPath = '${maskDir.path}${Platform.pathSeparator}'
          'original.inf';
      final String copyPath = '${scanDir.path}${Platform.pathSeparator}'
          'copy.inf';
      File(originalPath).writeAsStringSync(encodeMaskJson(original));
      File(copyPath).writeAsStringSync(encodeMaskJson(original));

      final _ScriptedFilePicker picker = _ScriptedFilePicker(
        openPathToReturn: originalPath,
        directoryToReturn: scanDir.path,
      );
      await tester.runAsync(() async {
        await pumpShell(tester, picker);
        await loadMask(tester);

        // The Mask Editor is never opened, so _maskEditorMask stays null
        // and the document's own mask is the reference.
        await pickMenuItem(
          tester,
          'Edit',
          'Update other copies of this mask...',
        );
        await waitForRealIo();
        await settle(tester);

        expect(find.text('Up to date'), findsOneWidget);
        expect(find.text('Differs (same revision)'), findsNothing);
      });
    },
  );

  testWidgets(
    'closing the sync dialog having written nothing reports "no copies '
    'updated" — the same whether closed by Cancel, Escape or the barrier',
    (WidgetTester tester) async {
      final LearningMask original = _mask(name: 'Original');
      final String originalPath = '${maskDir.path}${Platform.pathSeparator}'
          'original.inf';
      final String copyPath = '${scanDir.path}${Platform.pathSeparator}'
          'copy.inf';
      // A copy one revision behind, so the row is selectable ("Will
      // update") rather than merely informational — the dialog closes
      // having written nothing even though there was something on offer.
      File(
        originalPath,
      ).writeAsStringSync(encodeMaskJson(original.copyWith(revision: 1)));
      File(copyPath).writeAsStringSync(encodeMaskJson(original));

      final _ScriptedFilePicker picker = _ScriptedFilePicker(
        openPathToReturn: originalPath,
        directoryToReturn: scanDir.path,
      );

      Future<void> openDialog() async {
        await pickMenuItem(
          tester,
          'Edit',
          'Update other copies of this mask...',
        );
        await waitForRealIo();
        await settle(tester);
        expect(find.text('Will update'), findsOneWidget);
      }

      await tester.runAsync(() async {
        await pumpShell(tester, picker);
        await loadMask(tester);

        await openDialog();
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(find.text('Update other copies of this mask'), findsNothing);
        expect(find.text('No copies were updated'), findsWidgets);

        await openDialog();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(find.text('Update other copies of this mask'), findsNothing);
        expect(find.text('No copies were updated'), findsWidgets);

        await openDialog();
        // The barrier is the full-screen GestureDetector `showDialog` puts
        // behind the dialog, inserted into the root Overlay above the
        // Scaffold — tapping the far corner, well outside the centred
        // dialog, lands on it rather than on the dialog itself.
        await tester.tapAt(const Offset(2, 2));
        await settle(tester);
        expect(find.text('Update other copies of this mask'), findsNothing);
        expect(find.text('No copies were updated'), findsWidgets);
      });
    },
  );
}

LearningMask _mask({required String name}) {
  return LearningMask(
    maskId: 'm_new_shell-fixture',
    name: name,
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: const <CategoryDefinition>[
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
        ],
      ),
    ],
  );
}
