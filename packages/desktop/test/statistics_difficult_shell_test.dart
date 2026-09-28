import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_picker.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// A [DesktopFilePicker] whose open and save dialogs answer with whatever
/// [nextOpenPath] and [nextSavePath] hold at the time.
final class _ScriptedFilePicker extends DesktopFilePicker {
  String? nextOpenPath;
  String? nextSavePath;

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
  }) async => nextSavePath;

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
    temp = Directory.systemTemp.createTempSync('la_statistics_difficult_');
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

  /// Each unit's (Direction 1, Direction 2) flags exactly as the file at
  /// [path] holds them.
  List<_UnitFlags> flagsOnDisk(String path) {
    return <_UnitFlags>[
      for (final LearningUnit unit in decodeDeckJson(
        File(path).readAsStringSync(),
      ).units)
        (unit.direction1Flags, unit.direction2Flags),
    ];
  }

  /// Waits until the file at [path] holds [expected] — polled, not a fixed
  /// sleep, so a slow host only takes longer — then settles, so the screen
  /// reflects the write too. Gives up after five seconds and lets the
  /// caller's expectation report what the file holds.
  Future<void> untilFlagsOnDisk(
    WidgetTester tester,
    String path,
    List<_UnitFlags> expected,
  ) async {
    bool landed() {
      try {
        return listEquals(flagsOnDisk(path), expected);
      } on FileSystemException {
        return false;
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

  /// Opens the app on [deckPath] and goes to the statistics unit list; a save
  /// dialog answers with [savePath].
  ///
  /// The surface is the desktop shell tests' own, so a layout overflow on
  /// the way fails the test.
  Future<void> openUnitList(
    WidgetTester tester,
    String deckPath, {
    String? savePath,
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _ScriptedFilePicker picker = _ScriptedFilePicker()
      ..nextOpenPath = deckPath
      ..nextSavePath = savePath;
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: prefs,
        filePicker: picker,
        settingsPath: p.join(temp.path, 'settings.json'),
      ),
    );
    await settleAfterIo(tester);
    await tester.tap(find.text('File').first);
    await settle(tester);
    await tester.tap(find.text('Load deck...').last);
    await settleAfterIo(tester);
    await tester.tap(find.text('Statistics').first);
    await settle(tester);
    await tester.tap(find.text('Show statistics').last);
    await settle(tester);
    await tester.tap(find.text('Unit list'));
    await settle(tester);
  }

  /// Taps the button or chip labelled [label], scrolling it into view first:
  /// the unit list's actions sit below the table.
  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Ticks the selection checkbox of the list's [row]-th visible row.
  Future<void> tick(WidgetTester tester, int row) async {
    await tester.tap(find.byType(Checkbox).at(row));
    await settle(tester);
  }

  testWidgets('the unit list filters to difficult units, marks and unmarks a '
      'selection in the deck file, and saves the difficult units as a new '
      'deck that keeps their flags', (WidgetTester tester) async {
    final String deckPath = p.join(temp.path, 'deck.vok');
    final String savedPath = p.join(temp.path, 'hard.vok');
    File(deckPath).writeAsStringSync(
      encodeDeckJson(_deck().copyWith(lastEdited: edited)),
    );
    await tester.runAsync(() async {
      await openUnitList(tester, deckPath, savePath: savedPath);
      expect(find.text('house'), findsOneWidget);
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);

      // Filter: only the automatically flagged cat is left.
      await press(tester, 'Difficult only');
      expect(find.text('house'), findsNothing);
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsNothing);

      // Mark it: the manual flag joins the automatic one, on disk and on
      // screen. Until the list follows its View, marking acts on both
      // directions.
      await press(tester, 'Select visible');
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (none, none),
        (both, manual),
        (none, none),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (none, none),
        (both, manual),
        (none, none),
      ]);
      expect(
        find.byTooltip('Difficult (manual and automatic flag)'),
        findsOneWidget,
      );

      // Mark house and dog from the full list.
      await press(tester, 'Difficult only');
      await press(tester, 'Clear selection');
      await tick(tester, 0);
      await tick(tester, 2);
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (manual, manual),
        (both, manual),
        (manual, manual),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (manual, manual),
        (both, manual),
        (manual, manual),
      ]);
      expect(find.byTooltip('Difficult (manual flag)'), findsNWidgets(2));

      // Unmark dog again.
      await press(tester, 'Clear selection');
      await tick(tester, 2);
      await press(tester, 'Unmark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (manual, manual),
        (both, manual),
        (none, none),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (manual, manual),
        (both, manual),
        (none, none),
      ]);
      expect(find.byTooltip('Difficult (manual flag)'), findsOneWidget);
      // Marking is not editing: the deck keeps the date it had.
      expect(
        decodeDeckJson(File(deckPath).readAsStringSync()).lastEdited,
        edited,
      );

      // Save the difficult units out: a new deck of house and cat, each
      // with the flags it carries.
      await press(tester, 'Difficult only');
      expect(find.text('dog'), findsNothing);
      await press(tester, 'Clear selection');
      await press(tester, 'Select visible');
      await press(tester, 'Save selected units');
      await untilFlagsOnDisk(tester, savedPath, <_UnitFlags>[
        (manual, manual),
        (both, manual),
      ]);
      final LearningDeck saved = decodeDeckJson(
        File(savedPath).readAsStringSync(),
      );
      expect(
        <String>[
          for (final LearningUnit unit in saved.units)
            unit.valueForFieldId(0).plainText,
        ],
        <String>['house', 'cat'],
      );
      expect(flagsOnDisk(savedPath), <_UnitFlags>[
        (manual, manual),
        (both, manual),
      ]);
    });
  });

  testWidgets('marking with nothing selected says so and writes nothing', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'none.vok');
    File(deckPath).writeAsStringSync(encodeDeckJson(_deck()));
    final String before = File(deckPath).readAsStringSync();
    await tester.runAsync(() async {
      await openUnitList(tester, deckPath);

      await press(tester, 'Mark selected');
      // Snack bars queue: this one shows once "Deck loaded." has gone.
      final Finder message = find.text('No units selected.');
      for (var i = 0; i < 100 && message.evaluate().isEmpty; i += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(message, findsOneWidget);
      expect(File(deckPath).readAsStringSync(), before);
    });
  });
}

/// One unit's (Direction 1, Direction 2) flags.
typedef _UnitFlags = (DifficultFlags, DifficultFlags);

const DifficultFlags none = DifficultFlags.none;
const DifficultFlags manual = DifficultFlags(manual: true);
const DifficultFlags automatic = DifficultFlags(automatic: true);
const DifficultFlags both = DifficultFlags(manual: true, automatic: true);

/// Three units: house (unflagged), cat (automatically flagged in
/// Direction 1), dog (unflagged).
LearningDeck _deck() {
  LearningUnit unit(
    String question,
    String answer, {
    DifficultFlags direction1 = none,
  }) {
    return LearningUnit(
      categoryId: 1,
      fields: <int, FieldValue>{
        0: FieldValue.plain(question),
        1: FieldValue.plain(answer),
      },
      direction1Flags: direction1,
    );
  }

  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_statistics-difficult-shell',
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
      unit('house', 'Haus'),
      unit('cat', 'Katze', direction1: automatic),
      unit('dog', 'Hund'),
    ],
  );
}
