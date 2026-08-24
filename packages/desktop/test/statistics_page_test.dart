import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/statistics/statistics_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  testWidgets('statistics page summarizes buckets and exports selection', (
    WidgetTester tester,
  ) async {
    // The practice list buttons sit below the default 600px test surface,
    // so give it room to lay out without an off-screen hit-test failure.
    widenSurface(tester);

    List<int> savedSelection = <int>[];
    await tester.pumpWidget(
      buildPage(
        onSaveSelectedUnits: (List<int> unitIndices) async {
          savedSelection = unitIndices;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Unit list'), findsOneWidget);
    expect(find.text('Perfect'), findsWidgets);
    expect(find.text('Not yet practiced'), findsWidgets);

    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save selected units'));
    await tester.pumpAndSettle();
    expect(savedSelection, <int>[1, 2]);

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Total Attempts'), findsOneWidget);
    expect(find.textContaining('Correct Attempts'), findsOneWidget);
    expect(find.textContaining('Practiced units'), findsOneWidget);
  });

  testWidgets(
    'level-zero caption shows on the overall tabs, and "% of practiced" is '
    'blank for the never-practiced row',
    (WidgetTester tester) async {
      widenSurface(tester);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      const String caption = 'Including the last level from Level learning';
      expect(find.text(caption), findsOneWidget);

      // Detailed tab: the "Not yet practiced" row has no meaningful share of
      // the practiced units, so that cell renders empty rather than "0%".
      final DataTable detailed = tester.widget<DataTable>(
        find.byType(DataTable),
      );
      final DataRow notPractised = detailed.rows.singleWhere(
        (DataRow row) => _cellText(row.cells[0]) == 'Not yet practiced',
      );
      expect(_cellText(notPractised.cells[4]), '');
      // The practiced bucket still reports its share.
      final DataRow perfect = detailed.rows.singleWhere(
        (DataRow row) => _cellText(row.cells[0]) == 'Perfect',
      );
      expect(_cellText(perfect.cells[4]), '100%');

      await tester.tap(find.text('Unit list'));
      await tester.pumpAndSettle();
      expect(find.text(caption), findsOneWidget);
    },
  );

  testWidgets('keep practicing sorts by a tapped column header', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    // Defaults to unit order.
    expect(_unitColumn(tester), <String>['1', '2']);

    // Tapping the already-sorted Unit header flips to descending.
    await tester.tap(find.text('Unit'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '1']);

    // Sorting by another column works too: unit 2 has no attempts, so it
    // sorts as the lowest accuracy and comes first ascending.
    await tester.tap(find.text('Accuracy'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '1']);
    await tester.tap(find.text('Accuracy'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '2']);
  });

  testWidgets('the level learning drill-down omits the level-zero caption', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);

    const LevelDirectionStats atLevelZeroPerfect = LevelDirectionStats(
      currentLevel: 0,
      levels: <int, DirectionStats>{0: DirectionStats(attempts: 2, correct: 2)},
    );
    await tester.pumpWidget(
      buildPage(
        levelStatistics: const <LevelUnitStats>[
          LevelUnitStats(
            index: 1,
            dir1: atLevelZeroPerfect,
            dir2: atLevelZeroPerfect,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 (100%)').first);
    await tester.pumpAndSettle();

    // The drill-down lists a single Level-Learning cell, so a caption about
    // including Level learning would be actively wrong there.
    expect(find.text('Champion — Perfect'), findsOneWidget);
    expect(
      find.text('Including the last level from Level learning'),
      findsNothing,
    );
  });

  testWidgets('level learning tab shows the matrix and drills into a cell', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);

    // Unit 1 sits at level 2 (2/1 → Fair) in both directions; unit 2 at level 0
    // (2/2 → Perfect). Combined view counts both directions, so each cell holds
    // two entries and reads "2 (100%)".
    await tester.pumpWidget(
      buildPage(
        statistics: const <UnitStats>[],
        levelStatistics: const <LevelUnitStats>[
          LevelUnitStats(index: 1, dir1: _levelTwoFair, dir2: _levelTwoFair),
          LevelUnitStats(
            index: 2,
            dir1: _levelZeroPerfect,
            dir2: _levelZeroPerfect,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await selectCombined(tester);

    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();

    // Level row headers (custom names) and the Total row/column are present.
    expect(find.text('Beginner'), findsOneWidget); // level 3
    expect(find.text('Learner'), findsOneWidget); // level 2
    expect(find.text('Champion'), findsOneWidget); // level 0
    expect(find.text('Total'), findsWidgets);
    // Two populated cells: (level 2, Fair) and (level 0, Perfect).
    expect(find.text('2 (100%)'), findsNWidgets(2));

    // The first populated cell is (level 2, Fair); drilling in opens its list.
    await tester.tap(find.text('2 (100%)').first);
    await tester.pumpAndSettle();

    expect(find.text('Learner — Fair'), findsOneWidget); // breadcrumb
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Q1'), findsOneWidget); // unit 1 in the drill-down
    expect(find.text('1 (50%)'), findsOneWidget); // that level's accuracy

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('2 (100%)'), findsNWidgets(2)); // back at the matrix
  });

  testWidgets('the scope control swaps the button row', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    // The screen opens on the current statistics, where every file command
    // makes sense — and the everyday clear names the record it clears.
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('All-time'), findsOneWidget);
    expect(find.text('Load stats...'), findsOneWidget);
    expect(find.text('Save stats'), findsOneWidget);
    expect(find.text('Save stats as...'), findsOneWidget);
    expect(find.text('Clear current stats...'), findsOneWidget);

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();

    // None of them acts on the record now on screen, so none of them is
    // offered. Cancel stays — it leaves the screen, not the record.
    expect(find.text('Load stats...'), findsNothing);
    expect(find.text('Save stats'), findsNothing);
    expect(find.text('Save stats as...'), findsNothing);
    expect(find.text('Clear current stats...'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    // What the all-time row does offer is the clear of the record on screen.
    expect(find.text('Clear all-time stats...'), findsOneWidget);

    // Switching back restores them.
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(find.text('Load stats...'), findsOneWidget);
    expect(find.text('Clear current stats...'), findsOneWidget);
    expect(find.text('Clear all-time stats...'), findsNothing);
  });

  testWidgets('the all-time clear is warning-marked and danger-coloured', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    var cleared = 0;
    await tester.pumpWidget(
      buildPage(onClearAllTimeStatistics: () async => cleared += 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();

    // A warning triangle rather than the everyday clear's neutral cross, so
    // the two are told apart before either label is read.
    final Finder button = find.widgetWithText(
      FilledButton,
      'Clear all-time stats...',
    );
    expect(
      find.descendant(
        of: button,
        matching: find.byIcon(Icons.warning_amber_rounded),
      ),
      findsOneWidget,
    );

    final BuildContext context = tester.element(button);
    final Color error = Theme.of(context).colorScheme.error;
    final ButtonStyle? style = tester.widget<FilledButton>(button).style;
    expect(
      style?.backgroundColor?.resolve(<WidgetState>{}),
      error,
    );

    // The screen only asks; confirming is the shell's business.
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(cleared, 1);
  });

  testWidgets('all three tabs follow the selected scope', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);

    // The current record holds one attempt on unit 1; the all-time record
    // holds ten across both units, so no figure can be mistaken for the other.
    await tester.pumpWidget(
      buildPage(
        statistics: const <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 1)),
          UnitStats(index: 2),
        ],
        levelStatistics: const <LevelUnitStats>[
          LevelUnitStats(index: 1, dir1: _levelTwoFair, dir2: _levelTwoFair),
        ],
        allTimeStatistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 6, correct: 6),
          ),
          UnitStats(
            index: 2,
            direction1: DirectionStats(attempts: 4, correct: 4),
          ),
        ],
        allTimeLevelStatistics: const <LevelUnitStats>[
          LevelUnitStats(
            index: 1,
            dir1: _levelZeroPerfect,
            dir2: _levelZeroPerfect,
          ),
          LevelUnitStats(
            index: 2,
            dir1: _levelZeroPerfect,
            dir2: _levelZeroPerfect,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Overview — current: one attempt, one practiced unit of two.
    expect(find.text('Total Attempts: 1'), findsOneWidget);
    expect(find.text('Practiced units: 1 (50%)'), findsOneWidget);

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(find.text('Total Attempts: 10'), findsOneWidget);
    expect(find.text('Practiced units: 2 (100%)'), findsOneWidget);

    // Unit list — the all-time attempts, per unit.
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();
    expect(_column(tester, 5), <String>['6', '4']);

    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(_column(tester, 5), <String>['1', '0']);

    // Level Learning — the current record has unit 1 on the Learner rung and
    // nothing at Champion; the all-time record has both units' last level at
    // Champion and nothing at Learner. Read off the matrix rows rather than by
    // text: the Total row repeats a lone cell's wording verbatim.
    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();
    expect(_matrixRowTotals(tester), <String>['0', '1', '0', '0', '1']);

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(_matrixRowTotals(tester), <String>['0', '0', '0', '2', '2']);
  });

  testWidgets('the all-time level column reads as the last level reached', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    await tester.pumpWidget(
      buildPage(
        levelStatistics: const <LevelUnitStats>[
          LevelUnitStats(index: 1, dir1: _levelTwoFair, dir2: _levelTwoFair),
        ],
        allTimeLevelStatistics: const <LevelUnitStats>[
          LevelUnitStats(
            index: 1,
            dir1: _levelZeroPerfect,
            dir2: _levelZeroPerfect,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();

    // Current scope: the row header names where the ladder stands now.
    expect(_matrixLevelHeader(tester), 'Level');

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();

    // All-time scope: the record carries the level most recently reached, so
    // the column must not read as a live position.
    expect(_matrixLevelHeader(tester), 'Last level');
  });

  testWidgets('the all-time unit list exports a selection like the current '
      'one does', (WidgetTester tester) async {
    widenSurface(tester);

    List<int>? savedSelection;
    await tester.pumpWidget(
      buildPage(
        statistics: const <UnitStats>[],
        allTimeStatistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 3, correct: 1),
          ),
          UnitStats(index: 2),
        ],
        onSaveSelectedUnits: (List<int> unitIndices) async {
          savedSelection = unitIndices;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save selected units'));
    await tester.pumpAndSettle();
    expect(savedSelection, <int>[1, 2]);
  });

  testWidgets('a refused lifetime write is said out loud under the all-time '
      'numbers, and nowhere else', (WidgetTester tester) async {
    widenSurface(tester);
    await tester.pumpWidget(
      buildPage(
        allTimeIsRefused: true,
        allTimeStatistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 3, correct: 1),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The current record still saves exactly as it always did, so the warning
    // has no business in its scope.
    expect(find.textContaining('no longer being saved'), findsNothing);

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no longer being saved'), findsOneWidget);
    // ...and it stays put while the learner moves between the three views:
    // this is a state, not a status line that scrolls away.
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no longer being saved'), findsOneWidget);
  });

  testWidgets('a lifetime record that is reaching its file says nothing at all',
      (WidgetTester tester) async {
    widenSurface(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no longer being saved'), findsNothing);
  });
}

/// Unit at level 2 with a Fair (2 attempts, 1 correct) record on that rung.
const LevelDirectionStats _levelTwoFair = LevelDirectionStats(
  currentLevel: 2,
  levels: <int, DirectionStats>{2: DirectionStats(attempts: 2, correct: 1)},
);

/// Unit at level 0 with a Perfect (2 of 2) record on that rung.
const LevelDirectionStats _levelZeroPerfect = LevelDirectionStats(
  currentLevel: 0,
  levels: <int, DirectionStats>{0: DirectionStats(attempts: 2, correct: 2)},
);

/// Gives the test surface room for both control rows and the tables below.
///
/// The screen is laid out for a desktop window, not for the 800×600 default;
/// widening the view is the honest fix, rather than shrinking the UI to suit
/// the test.
void widenSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Switches the direction selector to Combined, which counts both directions.
Future<void> selectCombined(WidgetTester tester) async {
  await tester.tap(
    find.byType(DropdownButtonFormField<StatisticsDirectionView>),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Combined').last);
  await tester.pumpAndSettle();
}

/// Pumps a statistics page over [sampleDeck].
///
/// Defaults to unit 1 practiced perfectly and unit 2 never practiced in the
/// current record, and an empty all-time record.
Widget buildPage({
  List<UnitStats> statistics = const <UnitStats>[
    UnitStats(index: 1, direction1: DirectionStats(attempts: 2, correct: 2)),
    UnitStats(index: 2),
  ],
  List<LevelUnitStats> levelStatistics = const <LevelUnitStats>[],
  List<UnitStats> allTimeStatistics = const <UnitStats>[],
  List<LevelUnitStats> allTimeLevelStatistics = const <LevelUnitStats>[],
  bool allTimeIsRefused = false,
  SaveSelectedUnitsCallback? onSaveSelectedUnits,
  Future<void> Function()? onClearAllTimeStatistics,
}) {
  return MaterialApp(
    localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
    supportedLocales: LearnAnywhereLocalizations.supportedLocales,
    home: StatisticsPage(
      deck: sampleDeck(),
      statistics: statistics,
      levelStatistics: levelStatistics,
      allTimeStatistics: allTimeStatistics,
      allTimeLevelStatistics: allTimeLevelStatistics,
      allTimeIsRefused: allTimeIsRefused,
      levelNames: kDefaultLevelNamesEn,
      onLoadStatistics: () async {},
      onSaveStatistics: () async {},
      onClearStatistics: () async {},
      onClearAllTimeStatistics:
          onClearAllTimeStatistics ?? () async {},
      onSaveSelectedUnits:
          onSaveSelectedUnits ?? (List<int> unitIndices) async {},
      onSaveStatisticsAs: () async {},
      onClose: () {},
    ),
  );
}

/// The text of a [DataCell], unwrapping the optional hover [Tooltip].
String _cellText(DataCell cell) {
  final Widget child = cell.child;
  return ((child is Tooltip ? child.child! : child) as Text).data!;
}

/// The Unit column of the Keep-practicing table, top to bottom.
///
/// Read off the [DataTable] itself rather than via finders so the assertion is
/// about row *order*, which finders do not preserve.
List<String> _unitColumn(WidgetTester tester) => _column(tester, 1);

/// Column [index] of the visible [DataTable], top to bottom.
List<String> _column(WidgetTester tester, int index) {
  final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
  return table.rows.map((DataRow row) => _cellText(row.cells[index])).toList();
}

/// The right-hand Total column of the Level-Learning matrix, top to bottom:
/// one entry count per level (3, 2, 1, 0) and then the grand total.
List<String> _matrixRowTotals(WidgetTester tester) {
  final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
  return table.rows
      .map((DataRow row) => _cellText(row.cells.last))
      .toList();
}

/// The row-header column label of the Level-Learning matrix.
String _matrixLevelHeader(WidgetTester tester) {
  final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
  return (table.columns.first.label as Text).data!;
}

LearningDeck sampleDeck() {
  return const LearningDeck(
    mask: LearningMask(
      maskId: 'm_new_statistics-fixture',
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
          ],
        ),
      ],
    ),
    units: <LearningUnit>[
      LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{0: FieldValue.plain('Q1')}, // Question
      ),
      LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{0: FieldValue.plain('Q2')}, // Question
      ),
    ],
  );
}
