import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/statistics/statistics_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  testWidgets('statistics page summarizes buckets and exports selection', (
    WidgetTester tester,
  ) async {
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
          onLoadStatistics: () async {},
          onSaveStatistics: () async {},
          onClearStatistics: () async {},
          onSaveSelectedUnits: (List<int> unitIndices) async {
            savedSelection = unitIndices;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Keep practicing'), findsOneWidget);
    expect(find.text('Perfect'), findsWidgets);
    expect(find.text('Not yet queried'), findsWidgets);

    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save selected units'));
    await tester.pumpAndSettle();
    expect(savedSelection, <int>[1, 2]);

    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}

LearningDeck sampleDeck() {
  return const LearningDeck(
    mask: LearningMask(
      name: 'Sample',
      direction1Label: 'Direction 1',
      direction2Label: 'Direction 2',
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 1,
          name: 'Default',
          fields: <FieldDefinition>[
            FieldDefinition(
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
        fields: <String, FieldValue>{'Question': FieldValue.plain('Q1')},
      ),
      LearningUnit(
        categoryId: 1,
        fields: <String, FieldValue>{'Question': FieldValue.plain('Q2')},
      ),
    ],
  );
}
