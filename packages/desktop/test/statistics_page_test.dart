import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('the Statistics time follows Correct Attempts in the Current '
      'scope, whatever the View', (WidgetTester tester) async {
    widenSurface(tester);
    await tester.pumpWidget(buildPage(statisticsSeconds: 3725));
    await tester.pumpAndSettle();

    final Finder pill = find.text('Statistics time: 1:02:05');
    expect(pill, findsOneWidget);
    expect(
      find.byTooltip(
        'The learning time held by the current statistics since they were '
        'last cleared: the time of every unit you rated, each counted at '
        'most five minutes.',
      ),
      findsOneWidget,
    );
    // Directly after Correct Attempts in the summary row.
    final List<String> row = tester
        .widgetList<Text>(
          find.descendant(
            of: find.ancestor(of: pill, matching: find.byType(Wrap)).first,
            matching: find.byType(Text),
          ),
        )
        .map((Text text) => text.data!)
        .toList();
    expect(row.last, 'Statistics time: 1:02:05');
    expect(row[row.length - 2], startsWith('Correct Attempts: '));

    // Learning time belongs to the deck, not to a direction.
    await selectView(tester, 'Direction 2');
    expect(pill, findsOneWidget);
    await selectCombined(tester);
    expect(pill, findsOneWidget);

    // The lifetime record shows no statistics time.
    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Statistics time'), findsNothing);

    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(pill, findsOneWidget);
  });

  testWidgets('cleared statistics show no time, not a missing pill', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    expect(find.text('Statistics time: 0:00'), findsOneWidget);
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
      expect(_overviewRow(tester, 'Not yet practiced')[4], '');
      // The practiced bucket still reports its share.
      expect(_overviewRow(tester, 'Perfect')[4], '100%');

      await tester.tap(find.text('Unit list'));
      await tester.pumpAndSettle();
      expect(find.text(caption), findsOneWidget);
    },
  );

  testWidgets('the Overview counts the difficult units below the buckets, '
      'following the View but not the Scope', (WidgetTester tester) async {
    widenSurface(tester);
    await tester.pumpWidget(
      buildPage(deck: twoWayFlaggedDeck(), statistics: const <UnitStats>[]),
    );
    await tester.pumpAndSettle();

    // Below the last bucket, and outside it: nothing is practised, so all
    // four units still sit in "Not yet practiced".
    final List<String> labels = <String>[
      for (final List<String> row in _overviewRows(tester)) row.first,
    ];
    expect(labels.sublist(labels.indexOf('Not yet practiced')), <String>[
      'Not yet practiced',
      'Difficult',
      'Manual flag only',
      'Automatic flag only',
      'Both flags',
    ]);
    expect(_overviewRow(tester, 'Not yet practiced')[2], '4');

    // A stronger line than the buckets' sets them apart, and the three flag
    // rows carry the badge's icons: a flag on "Manual flag only" and "Both
    // flags", a sparkle on "Automatic flag only" and "Both flags".
    final Finder table = find.byKey(const Key('statisticsOverviewTable'));
    final List<TableRow> tableRows = tester.widget<Table>(table).children;
    double lineAbove(int row) =>
        (tableRows[row].decoration! as BoxDecoration).border!.top.width;
    final int difficultRow = labels.indexOf('Difficult') + 1; // + heading
    expect(lineAbove(difficultRow), greaterThan(lineAbove(difficultRow - 1)));
    expect(lineAbove(difficultRow + 1), lineAbove(difficultRow - 1));
    Finder icon(IconData data) =>
        find.descendant(of: table, matching: find.byIcon(data));
    expect(icon(Icons.flag), findsNWidgets(2));
    expect(icon(Icons.auto_awesome), findsNWidgets(2));

    // Direction 1, the default View: the manual flags of units 2 and 4.
    // Range and "% of practiced" stay blank.
    void expectDifficultRows(List<String> counts, List<String> shares) {
      expect(<List<String>>[
        _overviewRow(tester, 'Difficult'),
        _overviewRow(tester, 'Manual flag only'),
        _overviewRow(tester, 'Automatic flag only'),
        _overviewRow(tester, 'Both flags'),
      ], <List<String>>[
        <String>['Difficult', '', counts[0], shares[0], ''],
        <String>['Manual flag only', '', counts[1], shares[1], ''],
        <String>['Automatic flag only', '', counts[2], shares[2], ''],
        <String>['Both flags', '', counts[3], shares[3], ''],
      ]);
    }

    expectDifficultRows(
      <String>['2', '2', '0', '0'],
      <String>['50%', '50%', '0%', '0%'],
    );

    // The Scope does not change them: flags live on the deck.
    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expectDifficultRows(
      <String>['2', '2', '0', '0'],
      <String>['50%', '50%', '0%', '0%'],
    );

    // Combined: unit 2 manual, unit 3 automatic, unit 4 both — each once.
    await selectCombined(tester);
    expectDifficultRows(
      <String>['3', '1', '1', '1'],
      <String>['75%', '25%', '25%', '25%'],
    );

    // Direction 2: unit 3's automatic flag and unit 4's two.
    await selectView(tester, 'Direction 2');
    expectDifficultRows(
      <String>['2', '0', '1', '1'],
      <String>['50%', '0%', '25%', '25%'],
    );
  });

  testWidgets('a full Overview bar is the whole deck, not the largest row', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    // One of four units practised: no row holds the whole deck, so a bar
    // scaled to the largest row would fill "Not yet practiced" completely.
    await tester.pumpWidget(
      buildPage(
        deck: twoWayFlaggedDeck(),
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 2, correct: 2),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final List<String> labels = <String>[
      for (final List<String> row in _overviewRows(tester)) row.first,
    ];
    final List<double> bars = tester
        .widgetList<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(const Key('statisticsOverviewTable')),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .map((FractionallySizedBox bar) => bar.widthFactor!)
        .toList();
    expect(Map<String, double>.fromIterables(labels, bars), <String, double>{
      'Perfect': 0.25,
      'Good': 0,
      'Fair': 0,
      'Unsure': 0,
      'Very unsure': 0,
      'Never known': 0,
      'Not yet practiced': 0.75,
      'Difficult': 0.5,
      'Manual flag only': 0.5,
      'Automatic flag only': 0,
      'Both flags': 0,
    });
  });

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

  testWidgets('the unit list shows which flag makes a unit difficult, and '
      'sorts by it', (WidgetTester tester) async {
    widenSurface(tester);
    await tester.pumpWidget(
      buildPage(deck: flaggedDeck(), statistics: flaggedStatistics),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    // One indicator per flagged unit, named as the session badge names it;
    // unit 1 carries no flag and shows none.
    expect(find.byTooltip('Manual flag'), findsOneWidget);
    expect(find.byTooltip('Automatic flag'), findsOneWidget);
    expect(find.byTooltip('Manual and automatic flag'), findsOneWidget);

    // Unflagged first, then automatic, manual, both.
    await tester.tap(find.text('Difficult'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '3', '2', '4']);
  });

  testWidgets('the Difficult column, its sort, Difficult only and Mark / '
      'Unmark selected follow the View\'s direction, and Combined names the '
      'directions', (WidgetTester tester) async {
    widenSurface(tester);
    final List<Set<QueryDirection>> marked = <Set<QueryDirection>>[];
    final List<Set<QueryDirection>> unmarked = <Set<QueryDirection>>[];
    await tester.pumpWidget(
      buildPage(
        deck: twoWayFlaggedDeck(),
        statistics: const <UnitStats>[],
        onMarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              marked.add(directions);
            },
        onUnmarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              unmarked.add(directions);
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    Future<void> tapAndSettle(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    // Direction 1, the default View: only the manual flags of units 2 and 4.
    expect(find.byTooltip('Manual flag'), findsNWidgets(2));
    expect(find.byTooltip('Automatic flag'), findsNothing);
    expect(find.byTooltip('Manual and automatic flag'), findsNothing);
    await tapAndSettle('Difficult');
    expect(_unitColumn(tester), <String>['1', '3', '2', '4']);
    await tapAndSettle('Difficult only');
    expect(_unitColumn(tester), <String>['2', '4']);
    await tapAndSettle('Mark selected');
    await tapAndSettle('Unmark selected');
    expect(marked.last, <QueryDirection>{QueryDirection.direction1});
    expect(unmarked.last, <QueryDirection>{QueryDirection.direction1});

    // Direction 2: unit 3's automatic flag and unit 4's two; unit 2 is not
    // difficult this way round, and the sort ranks by this direction too.
    await selectView(tester, 'Direction 2');
    expect(find.byTooltip('Manual flag'), findsNothing);
    expect(find.byTooltip('Automatic flag'), findsOneWidget);
    expect(find.byTooltip('Manual and automatic flag'), findsOneWidget);
    expect(_unitColumn(tester), <String>['3', '4']);
    await tapAndSettle('Difficult only');
    expect(_unitColumn(tester), <String>['1', '2', '3', '4']);
    await tapAndSettle('Mark selected');
    await tapAndSettle('Unmark selected');
    expect(marked.last, <QueryDirection>{QueryDirection.direction2});
    expect(unmarked.last, <QueryDirection>{QueryDirection.direction2});

    // Combined: either direction, and each tooltip says which.
    await selectCombined(tester);
    expect(find.byTooltip('Manual flag: Direction 1'), findsOneWidget);
    expect(find.byTooltip('Automatic flag: Direction 2'), findsOneWidget);
    expect(
      find.byTooltip(
        'Manual flag: Direction 1 and 2 · Automatic flag: Direction 2',
      ),
      findsOneWidget,
    );
    // Still sorted by Difficult, now on the merged flags: automatic (3),
    // manual (2), both (4).
    await tapAndSettle('Difficult only');
    expect(_unitColumn(tester), <String>['3', '2', '4']);
    await tapAndSettle('Mark selected');
    await tapAndSettle('Unmark selected');
    expect(marked.last, QueryDirection.values.toSet());
    expect(unmarked.last, QueryDirection.values.toSet());
  });

  testWidgets('Difficult only narrows the list together with the bucket chips '
      'and Min %, and Select visible then takes only what it shows', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    List<int> marked = <int>[];
    List<int> unmarked = <int>[];
    await tester.pumpWidget(
      buildPage(
        deck: flaggedDeck(),
        statistics: flaggedStatistics,
        onMarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              marked = unitIndices;
            },
        onUnmarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              unmarked = unitIndices;
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '2', '3', '4']);

    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '3', '4']);

    // Hiding the Perfect bucket drops unit 4 (both flags, 100 %).
    await tester.tap(find.widgetWithText(FilterChip, 'Perfect'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '3']);

    // A minimum drops unit 2, which has never been practised.
    await tester.enterText(find.widgetWithText(TextField, 'Min %'), '40');
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['3']);

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark selected'));
    await tester.pumpAndSettle();
    expect(marked, <int>[3]);

    // Clearing the other filters and switching the toggle off shows every
    // unit again: off is no difficulty filter, not "not difficult".
    await tester.enterText(find.widgetWithText(TextField, 'Min %'), '');
    await tester.tap(find.widgetWithText(FilterChip, 'Perfect'));
    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '2', '3', '4']);

    // Ctrl+click is an ordinary click here: it switches the toggle on and
    // isolates nothing, so every bucket still shows.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Difficult only'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '3', '4']);

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unmark selected'));
    await tester.pumpAndSettle();
    expect(unmarked, <int>[2, 3, 4]);
  });

  testWidgets('the selection actions leave out selected units a filter hides',
      (WidgetTester tester) async {
    widenSurface(tester);
    List<int> saved = <int>[];
    List<int> marked = <int>[];
    List<int> unmarked = <int>[];
    await tester.pumpWidget(
      buildPage(
        deck: flaggedDeck(),
        statistics: flaggedStatistics,
        onSaveSelectedUnits: (List<int> unitIndices) async {
          saved = unitIndices;
        },
        onMarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              marked = unitIndices;
            },
        onUnmarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              unmarked = unitIndices;
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit list'));
    await tester.pumpAndSettle();

    // All four selected, then the filter hides unit 1: it stays ticked, but
    // no action may touch it.
    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2', '3', '4']);

    await tester.tap(find.text('Unmark selected'));
    await tester.tap(find.text('Mark selected'));
    await tester.tap(find.text('Save selected units'));
    await tester.pumpAndSettle();
    expect(unmarked, <int>[2, 3, 4]);
    expect(marked, <int>[2, 3, 4]);
    expect(saved, <int>[2, 3, 4]);

    // A row counts as shown when it is in the list, not when it is on
    // screen: on a short surface the later rows are scrolled out of view
    // and are still acted on.
    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '2', '3', '4']);
    tester.view.physicalSize = const Size(1400, 420);
    await tester.pumpAndSettle();
    expect(find.text('Q4').hitTestable(), findsNothing);
    await tester.dragUntilVisible(
      find.text('Mark selected'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -100),
    );
    await tester.tap(find.text('Mark selected'));
    await tester.pumpAndSettle();
    expect(marked, <int>[1, 2, 3, 4]);
  });

  testWidgets('the Level x Bucket drill-down offers Difficult only and the '
      'marking actions too', (WidgetTester tester) async {
    widenSurface(tester);
    List<int> marked = <int>[];
    Set<QueryDirection> markedDirections = <QueryDirection>{};
    await tester.pumpWidget(
      buildPage(
        deck: flaggedDeck(),
        levelStatistics: const <LevelUnitStats>[
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
        onMarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              marked = unitIndices;
              markedDirections = directions;
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 (100%)').first);
    await tester.pumpAndSettle();
    expect(find.text('Champion — Perfect'), findsOneWidget);
    expect(_unitColumn(tester), <String>['1', '2']);

    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['2']);

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark selected'));
    await tester.pumpAndSettle();
    expect(marked, <int>[2]);
    // The drill-down follows the View as the unit list does.
    expect(markedDirections, <QueryDirection>{QueryDirection.direction1});
  });

  testWidgets('the Level x Bucket drill-down follows the View too', (
    WidgetTester tester,
  ) async {
    widenSurface(tester);
    List<int> marked = <int>[];
    Set<QueryDirection> markedDirections = <QueryDirection>{};
    await tester.pumpWidget(
      buildPage(
        // Unit 2's manual flag sits in Direction 1 only.
        deck: flaggedDeck(),
        levelStatistics: const <LevelUnitStats>[
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
        onMarkSelectedUnits:
            (List<int> unitIndices, Set<QueryDirection> directions) async {
              marked = unitIndices;
              markedDirections = directions;
            },
      ),
    );
    await tester.pumpAndSettle();
    await selectView(tester, 'Direction 2');
    await tester.tap(find.text('Level Learning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 (100%)').first);
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), <String>['1', '2']);
    expect(find.byTooltip('Manual flag'), findsNothing);

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark selected'));
    await tester.pumpAndSettle();
    expect(marked, <int>[1, 2]);
    expect(markedDirections, <QueryDirection>{QueryDirection.direction2});

    // Nothing is difficult this way round.
    await tester.tap(find.text('Difficult only'));
    await tester.pumpAndSettle();
    expect(_unitColumn(tester), isEmpty);
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
    // The all-time scope offers no button that changes anything: its one
    // command lives behind the overflow control beside the scope selector.
    expect(find.text('Clear all-time stats...'), findsNothing);
    expect(find.byTooltip('All-time actions'), findsOneWidget);

    // Switching back restores them.
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(find.text('Load stats...'), findsOneWidget);
    expect(find.text('Clear current stats...'), findsOneWidget);
    expect(find.byTooltip('All-time actions'), findsNothing);
  });

  testWidgets('the all-time clear is reachable only through the overflow '
      'menu', (WidgetTester tester) async {
    widenSurface(tester);
    var cleared = 0;
    await tester.pumpWidget(
      buildPage(onClearAllTimeStatistics: () async => cleared += 1),
    );
    await tester.pumpAndSettle();

    // Not in the current scope at all — neither the command nor its control.
    expect(find.byTooltip('All-time actions'), findsNothing);

    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();

    // In the all-time scope the control is there but the command is not: the
    // learner has to open for it, so nothing destructive can be pressed by
    // mistake on the way past.
    expect(find.text('Clear all-time stats...'), findsNothing);
    await tester.tap(find.byTooltip('All-time actions'));
    await tester.pumpAndSettle();

    // Opened, it shows the single command, marked as the destructive one.
    final Finder item = find.widgetWithText(
      MenuItemButton,
      'Clear all-time stats...',
    );
    expect(item, findsOneWidget);
    final BuildContext context = tester.element(item);
    final Color error = Theme.of(context).colorScheme.error;
    expect(
      tester
          .widget<MenuItemButton>(item)
          .style
          ?.foregroundColor
          ?.resolve(<WidgetState>{}),
      error,
    );

    // The screen only asks; confirming is the shell's business.
    await tester.tap(item);
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
    expect(_columnNamed(tester, 'Attempts'), <String>['6', '4']);

    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(_columnNamed(tester, 'Attempts'), <String>['1', '0']);

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
Future<void> selectCombined(WidgetTester tester) =>
    selectView(tester, 'Combined');

/// Switches the direction selector to the View labelled [label].
Future<void> selectView(WidgetTester tester, String label) async {
  await tester.tap(
    find.byType(DropdownButtonFormField<StatisticsDirectionView>),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
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
  int statisticsSeconds = 0,
  List<UnitStats> allTimeStatistics = const <UnitStats>[],
  List<LevelUnitStats> allTimeLevelStatistics = const <LevelUnitStats>[],
  bool allTimeIsRefused = false,
  SelectedUnitsCallback? onSaveSelectedUnits,
  FlagSelectedUnitsCallback? onMarkSelectedUnits,
  FlagSelectedUnitsCallback? onUnmarkSelectedUnits,
  Future<void> Function()? onClearAllTimeStatistics,
  LearningDeck? deck,
}) {
  return MaterialApp(
    localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
    supportedLocales: LearnAnywhereLocalizations.supportedLocales,
    home: StatisticsPage(
      deck: deck ?? sampleDeck(),
      statistics: statistics,
      levelStatistics: levelStatistics,
      statisticsSeconds: statisticsSeconds,
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
      onMarkSelectedUnits:
          onMarkSelectedUnits ??
          (List<int> unitIndices, Set<QueryDirection> directions) async {},
      onUnmarkSelectedUnits:
          onUnmarkSelectedUnits ??
          (List<int> unitIndices, Set<QueryDirection> directions) async {},
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

/// The Overview table's rows below its heading, top to bottom, each as its
/// five text cells: label, Range, Count, % of all, % of practiced.
List<List<String>> _overviewRows(WidgetTester tester) {
  final List<String> texts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('statisticsOverviewTable')),
          matching: find.byType(Text),
        ),
      )
      .map((Text text) => text.data!)
      .toList();
  return <List<String>>[
    for (var start = 5; start < texts.length; start += 5)
      texts.sublist(start, start + 5),
  ];
}

/// The Overview row labelled [label], as [_overviewRows] gives it.
List<String> _overviewRow(WidgetTester tester, String label) =>
    _overviewRows(tester).singleWhere((List<String> row) => row.first == label);

/// The Unit column of the Keep-practicing table, top to bottom.
///
/// Read off the [DataTable] itself rather than via finders so the assertion is
/// about row *order*, which finders do not preserve.
List<String> _unitColumn(WidgetTester tester) => _column(tester, 1);

/// The column headed [label] in the visible [DataTable], top to bottom.
List<String> _columnNamed(WidgetTester tester, String label) {
  final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
  final int index = table.columns.indexWhere(
    (DataColumn column) =>
        column.label is Text && (column.label as Text).data == label,
  );
  expect(index, isNonNegative, reason: 'no column headed "$label"');
  return _column(tester, index);
}

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

/// [sampleDeck]'s mask with four units: 1 unflagged, 2 manually flagged,
/// 3 automatically flagged, 4 carrying both flags, all in Direction 1.
LearningDeck flaggedDeck() {
  final LearningUnit template = sampleDeck().units.first;
  LearningUnit unit(String question, {bool manual = false, bool auto = false}) {
    return template.copyWith(
      fields: <int, FieldValue>{0: FieldValue.plain(question)},
      direction1Flags: DifficultFlags(manual: manual, automatic: auto),
    );
  }

  return sampleDeck().copyWith(
    units: <LearningUnit>[
      unit('Q1'),
      unit('Q2', manual: true),
      unit('Q3', auto: true),
      unit('Q4', manual: true, auto: true),
    ],
  );
}

/// [sampleDeck]'s mask with four units flagged per direction: 1 unflagged,
/// 2 manual in Direction 1, 3 automatic in Direction 2, and 4 manual in
/// Direction 1 and both flags in Direction 2.
LearningDeck twoWayFlaggedDeck() {
  final LearningUnit template = sampleDeck().units.first;
  const DifficultFlags manual = DifficultFlags(manual: true);
  LearningUnit unit(
    String question, {
    DifficultFlags d1 = DifficultFlags.none,
    DifficultFlags d2 = DifficultFlags.none,
  }) {
    return template.copyWith(
      fields: <int, FieldValue>{0: FieldValue.plain(question)},
      direction1Flags: d1,
      direction2Flags: d2,
    );
  }

  return sampleDeck().copyWith(
    units: <LearningUnit>[
      unit('Q1'),
      unit('Q2', d1: manual),
      unit('Q3', d2: const DifficultFlags(automatic: true)),
      unit(
        'Q4',
        d1: manual,
        d2: const DifficultFlags(manual: true, automatic: true),
      ),
    ],
  );
}

/// [flaggedDeck]'s current record: unit 1 Perfect, unit 2 never practised,
/// unit 3 Fair (50 %), unit 4 Perfect.
const List<UnitStats> flaggedStatistics = <UnitStats>[
  UnitStats(index: 1, direction1: DirectionStats(attempts: 2, correct: 2)),
  UnitStats(index: 3, direction1: DirectionStats(attempts: 2, correct: 1)),
  UnitStats(index: 4, direction1: DirectionStats(attempts: 2, correct: 2)),
];

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
