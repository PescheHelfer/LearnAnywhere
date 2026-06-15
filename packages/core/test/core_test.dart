import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('serialization', () {
    test('round-trips mask, deck, and statistics files', () {
      final LearningMask mask = sampleMask();
      final LearningDeck deck = sampleDeck();
      const StatisticsFile statistics = StatisticsFile(
        deckRef: 'francais1.vok',
        perUnit: <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 5, correct: 4),
            direction2: DirectionStats(attempts: 2, correct: 0),
          ),
          UnitStats(index: 2),
        ],
      );

      expect(decodeMaskJson(encodeMaskJson(mask)).name, mask.name);
      expect(
        decodeDeckJson(encodeDeckJson(deck)).units.length,
        deck.units.length,
      );
      expect(
        decodeStatisticsJson(
          encodeStatisticsJson(statistics),
        ).perUnit.first.direction1.correct,
        4,
      );
    });

    test('validates strict schema rules and ignores unknown future fields', () {
      final Map<String, Object?> json = encodeMask(sampleMask());
      json['future'] = 'ignored';

      expect(decodeMask(json).categories, hasLength(1));

      final Map<String, Object?> invalid = encodeMask(sampleMask());
      final List<Object?> categories = invalid['categories']! as List<Object?>;
      final Map<String, Object?> category =
          categories.first! as Map<String, Object?>;
      final List<Object?> fields = category['fields']! as List<Object?>;
      final Map<String, Object?> firstField = Map<String, Object?>.from(
        fields.first! as Map<String, Object?>,
      );
      firstField['length'] = 81;
      fields[0] = firstField;

      expect(() => decodeMask(invalid), throwsA(isA<ValidationException>()));
    });
  });

  group('i18n', () {
    test('returns English and German framework-independent messages', () {
      expect(
        LearnAnywhereCatalog.message(
          LearnAnywhereMessage.desktopShellReady,
          'en',
        ),
        'Desktop shell ready',
      );
      expect(
        LearnAnywhereCatalog.message(
          LearnAnywhereMessage.desktopShellReady,
          'de',
        ),
        'Desktop-Shell bereit',
      );
      expect(LearnAnywhereCatalog.supportedLanguageCodes, <String>['en', 'de']);
    });
  });

  group('role-driven model helpers', () {
    test('select prompt, answer, and remark fields by direction', () {
      final LearningDeck deck = sampleDeck();
      final LearningUnit unit = deck.units.first;

      expect(
        promptFields(
          deck,
          unit,
          QueryDirection.direction1,
        ).keys.map((FieldDefinition f) => f.name),
        <String>['DE'],
      );
      expect(
        answerFields(
          deck,
          unit,
          QueryDirection.direction1,
        ).keys.map((FieldDefinition f) => f.name),
        <String>['FR1', 'FR2'],
      );
      expect(
        remarkFields(
          deck,
          unit,
          QueryDirection.direction1,
        ).keys.map((FieldDefinition f) => f.name),
        <String>['Note'],
      );
      expect(
        promptFields(
          deck,
          unit,
          QueryDirection.direction2,
        ).keys.map((FieldDefinition f) => f.name),
        <String>['FR1', 'FR2'],
      );
    });
  });

  group('answer evaluation', () {
    test('matches equal-group answers independent of order', () {
      final LearningDeck deck = sampleDeck();
      final AnswerEvaluation result = evaluateAnswer(
        deck: deck,
        unit: deck.units.first,
        direction: QueryDirection.direction1,
        enteredValues: const <String, FieldValue>{
          'FR1': FieldValue.plain('un lapin'),
          'FR2': FieldValue.plain('le lapin'),
        },
      );

      expect(result.correct, isTrue);
    });

    test('normalizes case and accents when options are off', () {
      final LearningDeck deck = sampleDeck();
      final AnswerEvaluation result = evaluateAnswer(
        deck: deck,
        unit: deck.units[1],
        direction: QueryDirection.direction1,
        enteredValues: const <String, FieldValue>{
          'FR1': FieldValue.plain('TRES IMPORTANT'),
        },
      );

      expect(result.correct, isTrue);
    });

    test('can require complete input keyed to non-empty solutions', () {
      final LearningDeck deck = sampleDeck();
      final AnswerEvaluation missingRequired = evaluateAnswer(
        deck: deck,
        unit: deck.units.first,
        direction: QueryDirection.direction1,
        enteredValues: const <String, FieldValue>{
          'FR1': FieldValue.plain('un lapin'),
        },
      );
      final AnswerEvaluation partialAllowed = evaluateAnswer(
        deck: deck,
        unit: deck.units.first,
        direction: QueryDirection.direction1,
        enteredValues: const <String, FieldValue>{
          'FR1': FieldValue.plain('un lapin'),
        },
        options: const AnswerEvaluationOptions(completeInputRequired: false),
      );

      expect(missingRequired.correct, isFalse);
      expect(partialAllowed.correct, isTrue);
    });

    test('scores all-or-nothing for the unit', () {
      final LearningDeck deck = sampleDeck();
      final AnswerEvaluation result = evaluateAnswer(
        deck: deck,
        unit: deck.units.first,
        direction: QueryDirection.direction1,
        enteredValues: const <String, FieldValue>{
          'FR1': FieldValue.plain('un lapin'),
          'FR2': FieldValue.plain('wrong'),
        },
      );

      expect(result.correct, isFalse);
      expect(
        result.fields.any((FieldEvaluation field) => !field.correct),
        isTrue,
      );
    });
  });

  group('rating and super-query', () {
    test('records correct, wrong, no-count, and wrong ceiling rules', () {
      expect(
        recordAttempt(const DirectionStats(), AttemptRating.correct),
        const DirectionStats(attempts: 1, correct: 1),
      );
      expect(
        recordAttempt(const DirectionStats(), AttemptRating.wrong),
        const DirectionStats(attempts: 1),
      );
      expect(
        recordAttempt(const DirectionStats(attempts: 2), AttemptRating.noCount),
        const DirectionStats(attempts: 2),
      );
      expect(
        recordAttempt(
          const DirectionStats(attempts: 10),
          AttemptRating.wrong,
          wrongAnswerCeiling: const WrongAnswerCeiling(
            enabled: true,
            value: 10,
          ),
        ),
        const DirectionStats(attempts: 10),
      );
    });

    test(
      'derives active super-query pool from current stats and parameters',
      () {
        final LearningDeck deck = sampleDeck();
        final SessionParameters noGuard = const SessionParameters(
          directionSelection: DirectionSelection.both,
          mode: SessionMode.superQuery,
        );
        final SessionParameters withGuard = const SessionParameters(
          directionSelection: DirectionSelection.direction1,
          mode: SessionMode.superQuery,
          minimumAttemptsGuardEnabled: true,
          minAttempts: 2,
        );
        const List<UnitStats> stats = <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 1, correct: 1),
            direction2: DirectionStats(attempts: 2, correct: 0),
          ),
          UnitStats(
            index: 2,
            direction1: DirectionStats(attempts: 1, correct: 1),
            direction2: DirectionStats(attempts: 1, correct: 1),
          ),
        ];

        expect(
          activeSuperQueryPool(
            deck: deck,
            statistics: stats,
            parameters: noGuard,
          ),
          const <SessionItem>[
            SessionItem(unitIndex: 1, direction: QueryDirection.direction2),
          ],
        );
        expect(
          activeSuperQueryPool(
            deck: deck,
            statistics: stats,
            parameters: withGuard,
          ),
          const <SessionItem>[
            SessionItem(unitIndex: 1, direction: QueryDirection.direction1),
            SessionItem(unitIndex: 2, direction: QueryDirection.direction1),
          ],
        );
      },
    );
  });

  group('statistics and search', () {
    test('aggregates hit-rate buckets in the required order', () {
      final StatisticsSummary summary = aggregateStatistics(
        unitCount: 7,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 1, correct: 1),
          ),
          UnitStats(
            index: 2,
            direction1: DirectionStats(attempts: 4, correct: 3),
          ),
          UnitStats(
            index: 3,
            direction1: DirectionStats(attempts: 2, correct: 1),
          ),
          UnitStats(
            index: 4,
            direction1: DirectionStats(attempts: 4, correct: 1),
          ),
          UnitStats(
            index: 5,
            direction1: DirectionStats(attempts: 10, correct: 1),
          ),
          UnitStats(index: 6, direction1: DirectionStats(attempts: 2)),
        ],
        view: StatisticsDirectionView.direction1,
      );

      expect(summary.totalUnits, 7);
      expect(summary.queriedUnits, 6);
      expect(
        summary.buckets.map((BucketSummary bucket) => bucket.bucket),
        HitRateBucket.values,
      );
      expect(summary.buckets.map((BucketSummary bucket) => bucket.count), <int>[
        1,
        1,
        1,
        1,
        1,
        1,
        1,
      ]);
    });

    test('searches named fields with case and accent options', () {
      final LearningDeck deck = sampleDeck();

      expect(searchDeck(deck: deck, query: 'LAPIN'), hasLength(1));
      expect(searchDeck(deck: deck, query: 'tres'), hasLength(1));
      expect(
        searchDeck(
          deck: deck,
          query: 'tres',
          options: const TextMatchOptions(accentSensitive: true),
        ),
        isEmpty,
      );
      expect(
        searchDeckFiles(
          decksBySource: <String, LearningDeck>{'sample.vok': deck},
          query: 'lapin',
        ).single.sourceFile,
        'sample.vok',
      );
    });

    test('searches deck files from disk with source paths', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'learn_anywhere_core_test',
      );
      final File deckFile = File(
        '${tempDir.path}${Platform.pathSeparator}sample.vok',
      );
      await deckFile.writeAsString(encodeDeckJson(sampleDeck()));

      final List<SearchResult> results = await searchDeckFilesOnDisk(
        filePaths: <String>[deckFile.path],
        query: 'lapin',
      );

      expect(results, hasLength(1));
      expect(results.single.sourceFile, deckFile.path);
      await tempDir.delete(recursive: true);
    });
  });
}

LearningMask sampleMask() {
  return const LearningMask(
    name: 'French 1',
    direction1Label: 'DE-FR',
    direction2Label: 'FR-DE',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
        name: 'Noun',
        fields: <FieldDefinition>[
          FieldDefinition(
            name: 'DE',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            name: 'FR1',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            name: 'FR2',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            name: 'Note',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
          FieldDefinition(
            name: '',
            length: 10,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
        ],
      ),
    ],
  );
}

LearningDeck sampleDeck() {
  return LearningDeck(
    mask: sampleMask(),
    units: <LearningUnit>[
      const LearningUnit(
        categoryId: 1,
        fields: <String, FieldValue>{
          'DE': FieldValue.plain('ein Kaninchen'),
          'FR1': FieldValue.plain('le lapin'),
          'FR2': FieldValue.plain('un lapin'),
          'Note': FieldValue.plain('animal'),
        },
      ),
      LearningUnit(
        categoryId: 1,
        fields: <String, FieldValue>{
          'DE': const FieldValue.plain('wichtig'),
          'FR1': FieldValue.rich(<RichTextRun>[
            const RichTextRun(
              text: 'tr\u00E8s important',
              bold: true,
              color: '#CC0000',
            ),
          ]),
          'FR2': const FieldValue.plain(''),
          'Note': const FieldValue.plain('adjective'),
        },
      ),
    ],
  );
}
