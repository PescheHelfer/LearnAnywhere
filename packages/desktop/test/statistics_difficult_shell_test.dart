import 'dart:convert';
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

  /// Opens the app on [deckPath] and goes to the statistics screen, which
  /// opens on its Overview; a save dialog answers with [savePath].
  ///
  /// The surface is the desktop shell tests' own, so a layout overflow on
  /// the way fails the test.
  Future<void> openStatistics(
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
  }

  /// Opens the app on [deckPath] and goes to the statistics unit list; a save
  /// dialog answers with [savePath].
  Future<void> openUnitList(
    WidgetTester tester,
    String deckPath, {
    String? savePath,
  }) async {
    await openStatistics(tester, deckPath, savePath: savePath);
    await tester.tap(find.text('Unit list'));
    await settle(tester);
  }

  /// The Overview's Difficult rows, top to bottom, each as its label, Count
  /// and % of all.
  List<(String, String, String)> difficultRows(WidgetTester tester) {
    final List<String> texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('statisticsOverviewTable')),
            matching: find.byType(Text),
          ),
        )
        .map((Text text) => text.data!)
        .toList();
    // Five text cells a row — label, Range, Count, % of all, % of
    // practiced — and the four Difficult rows come last.
    return <(String, String, String)>[
      for (var start = texts.length - 20; start < texts.length; start += 5)
        (texts[start], texts[start + 2], texts[start + 3]),
    ];
  }

  /// Taps the button or chip labelled [label], scrolling it into view first:
  /// the unit list's actions sit below the table.
  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Switches the statistics View to the one labelled [label].
  Future<void> selectView(WidgetTester tester, String label) async {
    await tester.tap(
      find.byType(DropdownButtonFormField<StatisticsDirectionView>),
    );
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  /// The keys the file at [path] stores for its unit at [index], flags
  /// included: which flag keys were written, not what they decode to.
  Iterable<String> unitKeysOnDisk(String path, int index) {
    final Map<String, Object?> json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    return ((json['units']! as List<Object?>)[index]! as Map<String, Object?>)
        .keys;
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
      // screen, in the View's direction only.
      await press(tester, 'Select visible');
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (none, none),
        (both, none),
        (none, none),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (none, none),
        (both, none),
        (none, none),
      ]);
      expect(find.byTooltip('Manual and automatic flag'), findsOneWidget);

      // Mark house and dog from the full list.
      await press(tester, 'Difficult only');
      await press(tester, 'Clear selection');
      await tick(tester, 0);
      await tick(tester, 2);
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (manual, none),
        (both, none),
        (manual, none),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (manual, none),
        (both, none),
        (manual, none),
      ]);
      expect(find.byTooltip('Manual flag'), findsNWidgets(2));

      // Unmark dog again.
      await press(tester, 'Clear selection');
      await tick(tester, 2);
      await press(tester, 'Unmark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (manual, none),
        (both, none),
        (none, none),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (manual, none),
        (both, none),
        (none, none),
      ]);
      expect(find.byTooltip('Manual flag'), findsOneWidget);
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
        (manual, none),
        (both, none),
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
        (manual, none),
        (both, none),
      ]);
    });
  });

  testWidgets('the unit list follows its View: Difficult only hides a unit '
      'difficult only the other way round, Combined shows it, and Mark and '
      'Unmark selected under Direction 2 write only that direction', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'view.vok');
    // dog is difficult in Direction 2 only.
    final LearningDeck deck = _deck();
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        deck.copyWith(
          units: <LearningUnit>[
            deck.units[0],
            deck.units[1],
            deck.units[2].withFlags(QueryDirection.direction2, manual),
          ],
        ),
      ),
    );
    await tester.runAsync(() async {
      await openUnitList(tester, deckPath);

      // Direction 1, the default View: only cat is difficult this way.
      await press(tester, 'Difficult only');
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsNothing);
      expect(find.text('house'), findsNothing);

      // Combined: either direction, and dog's tooltip names its direction.
      await selectView(tester, 'Combined');
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
      expect(find.text('house'), findsNothing);
      expect(find.byTooltip('Manual flag: Direction 2'), findsOneWidget);
      expect(find.byTooltip('Automatic flag: Direction 1'), findsOneWidget);

      // Direction 2: only dog.
      await selectView(tester, 'Direction 2');
      expect(find.text('cat'), findsNothing);
      expect(find.text('dog'), findsOneWidget);

      // Mark house and cat from the full list: only manualDifficult2 is
      // written, and cat keeps its Direction 1 flag as it was.
      await press(tester, 'Difficult only');
      await tick(tester, 0);
      await tick(tester, 1);
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (none, manual),
        (automatic, manual),
        (none, manual),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (none, manual),
        (automatic, manual),
        (none, manual),
      ]);
      expect(unitKeysOnDisk(deckPath, 0), contains('manualDifficult2'));
      expect(unitKeysOnDisk(deckPath, 0), isNot(contains('manualDifficult1')));

      // Unmark them again: Direction 2 only, cat's automatic flag stays.
      await press(tester, 'Unmark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (none, none),
        (automatic, none),
        (none, manual),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (none, none),
        (automatic, none),
        (none, manual),
      ]);
    });
  });

  testWidgets('the Overview counts the deck file\'s difficult units under '
      'Direction 1 and Combined, and follows a mark made in the unit list', (
    WidgetTester tester,
  ) async {
    final String deckPath = p.join(temp.path, 'overview.vok');
    // house: manual in Direction 1. cat: automatic in Direction 1 and manual
    // in Direction 2, so both flags under Combined. dog: automatic in
    // Direction 2 only.
    final LearningDeck deck = _deck();
    File(deckPath).writeAsStringSync(
      encodeDeckJson(
        deck.copyWith(
          units: <LearningUnit>[
            deck.units[0].withFlags(QueryDirection.direction1, manual),
            deck.units[1].withFlags(QueryDirection.direction2, manual),
            deck.units[2].withFlags(QueryDirection.direction2, automatic),
          ],
        ),
      ),
    );
    await tester.runAsync(() async {
      await openStatistics(tester, deckPath);

      // Direction 1, the default View: house manual, cat automatic.
      expect(difficultRows(tester), <(String, String, String)>[
        ('Difficult', '2', '67%'),
        ('Manual flag only', '1', '33%'),
        ('Automatic flag only', '1', '33%'),
        ('Both flags', '0', '0%'),
      ]);

      // Combined: all three, each once, and cat's two flags from two
      // directions make it "Both flags".
      await selectView(tester, 'Combined');
      expect(difficultRows(tester), <(String, String, String)>[
        ('Difficult', '3', '100%'),
        ('Manual flag only', '1', '33%'),
        ('Automatic flag only', '1', '33%'),
        ('Both flags', '1', '33%'),
      ]);

      // Marking dog under Combined gives it a manual flag in both
      // directions beside its automatic one; once the deck file holds it,
      // the Overview counts it among "Both flags". Sorted by Difficult, dog
      // — automatic only — is the first row.
      await tester.tap(find.text('Unit list'));
      await settle(tester);
      await press(tester, 'Difficult');
      // Bringing the header into view scrolled the table sideways, past its
      // checkbox column.
      await tester.ensureVisible(find.byType(Checkbox).at(0));
      await settle(tester);
      await tick(tester, 0);
      await press(tester, 'Mark selected');
      await untilFlagsOnDisk(tester, deckPath, <_UnitFlags>[
        (manual, none),
        (automatic, manual),
        (manual, both),
      ]);
      expect(flagsOnDisk(deckPath), <_UnitFlags>[
        (manual, none),
        (automatic, manual),
        (manual, both),
      ]);
      await tester.tap(find.text('Overview'));
      await settle(tester);
      expect(difficultRows(tester), <(String, String, String)>[
        ('Difficult', '3', '100%'),
        ('Manual flag only', '1', '33%'),
        ('Automatic flag only', '0', '0%'),
        ('Both flags', '2', '67%'),
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
