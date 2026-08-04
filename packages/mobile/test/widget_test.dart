import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/main.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';

void main() {
  testWidgets('mobile app launches into deck-open empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LearnAnywhereMobileApp(fileService: _FakeMobileFileService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn Anywhere'), findsOneWidget);
    expect(find.text('No deck loaded'), findsOneWidget);
    expect(find.text('Open deck'), findsWidgets);
  });

  testWidgets('mobile think-only session reveals rates and persists stats', (
    WidgetTester tester,
  ) async {
    final MobileDeckDocument document = _document();
    final _FakeMobileFileService fileService = _FakeMobileFileService();

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        initialDocument: document,
        fileService: fileService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mobile sample'), findsOneWidget);
    expect(find.text('Units: 1'), findsOneWidget);

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unit 1 of 1'), findsOneWidget);
    expect(find.text('Prompt'), findsOneWidget);
    expect(_hasAnyRichText(tester, <String>['hello', 'bonjour']), isTrue);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Solution'), findsOneWidget);
    expect(find.text('Remarks'), findsOneWidget);
    expect(find.text('use greeting', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('How did it go?'), findsOneWidget);
    expect(find.text('No count'), findsOneWidget);

    await tester.tap(find.text('Knew it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Accuracy: 100%'), findsOneWidget);
    expect(fileService.savedStatistics, isNotEmpty);
    final UnitStats saved = fileService.savedStatistics.single;
    expect(saved.direction1.attempts + saved.direction2.attempts, 1);
    expect(saved.direction1.correct + saved.direction2.correct, 1);
  });
}

bool _hasAnyRichText(WidgetTester tester, List<String> values) {
  return values.any(
    (String value) => tester.any(find.text(value, findRichText: true)),
  );
}

MobileDeckDocument _document() {
  final LearningDeck deck = LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_mobile-fixture',
      name: 'Mobile sample',
      direction1Label: 'Forward',
      direction2Label: 'Backward',
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 1,
          name: 'Words',
          fields: <FieldDefinition>[
            FieldDefinition(
              id: 0,
              name: 'Prompt field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.question,
              role2: FieldRole.answer,
            ),
            FieldDefinition(
              id: 1,
              name: 'Answer field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
            ),
            FieldDefinition(
              id: 2,
              name: 'Remark field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.remark,
              role2: FieldRole.remark,
            ),
          ],
        ),
      ],
    ),
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: PlainFieldValue('hello'), // Prompt field
          1: PlainFieldValue('bonjour'), // Answer field
          2: PlainFieldValue('use greeting'), // Remark field
        },
      ),
    ],
  );
  return MobileDeckDocument(
    deck: deck,
    deckPath: 'sample.vok',
    statistics: clearStatistics(deck),
  );
}

final class _FakeMobileFileService extends MobileFileService {
  List<UnitStats> savedStatistics = const <UnitStats>[];

  @override
  Future<MobileDeckDocument?> openDeck({required String typeLabel}) async =>
      _document();

  @override
  Future<void> saveStatistics(
    MobileDeckDocument document,
    List<UnitStats> statistics,
  ) async {
    savedStatistics = statistics;
  }
}
