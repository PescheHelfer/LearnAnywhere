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
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<int> savedSelection = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: StatisticsPage(
          deck: sampleDeck(),
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction1: DirectionStats(attempts: 2, correct: 2),
            ),
            UnitStats(index: 2),
          ],
          levelStatistics: const <LevelUnitStats>[],
          levelNames: kDefaultLevelNamesEn,
          onLoadStatistics: () async {},
          onSaveStatistics: () async {},
          onClearStatistics: () async {},
          onSaveSelectedUnits: (List<int> unitIndices) async {
            savedSelection = unitIndices;
          },
          onSaveStatisticsAs: () async {},
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Keep practicing'), findsOneWidget);
    expect(find.text('Perfect'), findsWidgets);
    expect(find.text('Not yet practiced'), findsWidgets);

    await tester.tap(find.text('Keep practicing'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save selected units'));
    await tester.pumpAndSettle();
    expect(savedSelection, <int>[1, 2]);

    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('level learning tab shows the matrix and drills into a cell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Unit 1 sits at level 2 (2/1 → Fair) in both directions; unit 2 at level 0
    // (2/2 → Perfect). Combined view counts both directions, so each cell holds
    // two entries and reads "2 (100%)".
    const LevelDirectionStats atLevelTwoFair = LevelDirectionStats(
      currentLevel: 2,
      levels: <int, DirectionStats>{2: DirectionStats(attempts: 2, correct: 1)},
    );
    const LevelDirectionStats atLevelZeroPerfect = LevelDirectionStats(
      currentLevel: 0,
      levels: <int, DirectionStats>{0: DirectionStats(attempts: 2, correct: 2)},
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: StatisticsPage(
          deck: sampleDeck(),
          statistics: const <UnitStats>[],
          levelStatistics: const <LevelUnitStats>[
            LevelUnitStats(
              index: 1,
              dir1: atLevelTwoFair,
              dir2: atLevelTwoFair,
            ),
            LevelUnitStats(
              index: 2,
              dir1: atLevelZeroPerfect,
              dir2: atLevelZeroPerfect,
            ),
          ],
          levelNames: kDefaultLevelNamesEn,
          onLoadStatistics: () async {},
          onSaveStatistics: () async {},
          onClearStatistics: () async {},
          onSaveSelectedUnits: (List<int> unitIndices) async {},
          onSaveStatisticsAs: () async {},
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The view defaults to Direction 1; switch to Combined so both
    // directions are counted together, as this test expects.
    await tester.tap(
      find.byType(DropdownButtonFormField<StatisticsDirectionView>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Combined').last);
    await tester.pumpAndSettle();

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
