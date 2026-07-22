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
            onPickFolderDecks: () async {
              return <String, LearningDeck>{'sample.vok': deck};
            },
            onLoadFoundDeck: (LearningDeck deck) {
              loadedDeck = deck;
            },
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bonjour');
    await tester.tap(find.text('Search memory'));
    await tester.pumpAndSettle();

    expect(find.text('Results: 1'), findsOneWidget);
    // The result table shows the matched unit's Question/Answer previews; the
    // Question preview ('hello') is unique (the query field holds 'bonjour').
    expect(find.text('hello'), findsOneWidget);

    await tester.tap(find.text('Load found units'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search files'));
    await tester.pumpAndSettle();
    // A file search adds a Source file column carrying each hit's path.
    expect(find.text('sample.vok'), findsOneWidget);

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
      maskId: 'm_new_lexicon-fixture',
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
          0: FieldValue.plain('hello'), // Question
          1: FieldValue.plain('bonjour'), // Answer
        },
      ),
      LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: FieldValue.plain('bye'), // Question
          1: FieldValue.plain('au revoir'), // Answer
        },
      ),
    ],
  );
}
