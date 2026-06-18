import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/lexicon/lexicon_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  testWidgets('lexicon searches memory and loads file search results', (
    WidgetTester tester,
  ) async {
    LearningDeck? loadedDeck;
    final LearningDeck deck = sampleDeck();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: LexiconPage(
            deck: deck,
            textOptions: const TextMatchOptions(),
            loadDecksByPattern: (String pattern) async {
              return <String, LearningDeck>{'sample.vok': deck};
            },
            onLoadFoundDeck: (LearningDeck deck) {
              loadedDeck = deck;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bonjour');
    await tester.tap(find.text('Search memory'));
    await tester.pumpAndSettle();

    expect(find.text('Results: 1'), findsOneWidget);
    expect(find.textContaining('Matched fields: Answer'), findsOneWidget);

    await tester.tap(find.text('Load found units'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search files'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Source file: sample.vok'), findsOneWidget);

    await tester.tap(find.text('Load results'));
    await tester.pumpAndSettle();
    expect(
      find.text('Load found units? Current in-memory units will be discarded.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(loadedDeck, isNotNull);
    expect(loadedDeck!.units, hasLength(1));
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
            FieldDefinition(
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
        fields: <String, FieldValue>{
          'Question': FieldValue.plain('hello'),
          'Answer': FieldValue.plain('bonjour'),
        },
      ),
      LearningUnit(
        categoryId: 1,
        fields: <String, FieldValue>{
          'Question': FieldValue.plain('bye'),
          'Answer': FieldValue.plain('au revoir'),
        },
      ),
    ],
  );
}
