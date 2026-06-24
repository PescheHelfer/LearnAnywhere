import 'dart:io';
import 'dart:math';

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

  group('rich text ops', () {
    test('normalizeRuns merges adjacent equal runs and drops empties', () {
      final List<RichTextRun> runs = normalizeRuns(<RichTextRun>[
        const RichTextRun(text: 'foo', bold: true),
        const RichTextRun(text: '', bold: true),
        const RichTextRun(text: 'bar', bold: true),
        const RichTextRun(text: 'baz'),
      ]);

      expect(runs, hasLength(2));
      expect(runs[0], const RichTextRun(text: 'foobar', bold: true));
      expect(runs[1], const RichTextRun(text: 'baz'));
    });

    test('splitRunsAt creates a boundary at the requested offset', () {
      final List<RichTextRun> runs = splitRunsAt(<RichTextRun>[
        const RichTextRun(text: 'abcdef', bold: true),
      ], 2);

      expect(runs, hasLength(2));
      expect(runs[0].text, 'ab');
      expect(runs[1].text, 'cdef');
      expect(runs.every((RichTextRun r) => r.bold), isTrue);
    });

    test('splitRunsAt is a no-op on an existing boundary or the ends', () {
      const List<RichTextRun> source = <RichTextRun>[
        RichTextRun(text: 'ab'),
        RichTextRun(text: 'cd', italic: true),
      ];
      expect(normalizeRuns(splitRunsAt(source, 2)), source);
      expect(normalizeRuns(splitRunsAt(source, 0)), source);
      expect(normalizeRuns(splitRunsAt(source, 4)), source);
    });

    test('applyFormatToRange only formats the selected characters', () {
      final List<RichTextRun> runs = applyFormatToRange(
        <RichTextRun>[const RichTextRun(text: 'abcdef')],
        2,
        4,
        (RunFormat f) => f.copyWith(bold: true),
      );

      expect(runs, <RichTextRun>[
        const RichTextRun(text: 'ab'),
        const RichTextRun(text: 'cd', bold: true),
        const RichTextRun(text: 'ef'),
      ]);
    });

    test('applyFormatToRange can set and clear nullable colors per range', () {
      final List<RichTextRun> colored = applyFormatToRange(
        <RichTextRun>[const RichTextRun(text: 'hello')],
        0,
        3,
        (RunFormat f) => f.withColor('#1565C0'),
      );
      expect(colored.first, const RichTextRun(text: 'hel', color: '#1565C0'));

      final List<RichTextRun> cleared = applyFormatToRange(
        colored,
        1,
        2,
        (RunFormat f) => f.withColor(null),
      );
      expect(runsText(cleared), 'hello');
      expect(formatAt(cleared, 2).color, isNull);
      expect(formatAt(cleared, 1).color, '#1565C0');
    });

    test('applyFormatToRange returns a normalized copy for empty ranges', () {
      const List<RichTextRun> source = <RichTextRun>[
        RichTextRun(text: 'abc', italic: true),
      ];
      expect(
        applyFormatToRange(source, 3, 3, (RunFormat f) => f.copyWith(bold: true)),
        source,
      );
    });

    test('formatAt inherits the preceding character, or the first when at 0', () {
      final List<RichTextRun> runs = <RichTextRun>[
        const RichTextRun(text: 'ab'),
        const RichTextRun(text: 'cd', bold: true),
      ];
      expect(formatAt(runs, 0).bold, isFalse);
      expect(formatAt(runs, 2).bold, isFalse);
      expect(formatAt(runs, 3).bold, isTrue);
      expect(formatAt(runs, 4).bold, isTrue);
      expect(formatAt(const <RichTextRun>[], 0), RunFormat.none);
    });

    test('reconcileRuns keeps surrounding formatting on insertion', () {
      final List<RichTextRun> runs = <RichTextRun>[
        const RichTextRun(text: 'ab', bold: true),
        const RichTextRun(text: 'cd'),
      ];
      // Insert "XY" between "ab" and "cd" with no active formatting.
      final List<RichTextRun> result = reconcileRuns(
        runs: runs,
        oldText: 'abcd',
        newText: 'abXYcd',
        insertedFormat: RunFormat.none,
      );

      expect(runsText(result), 'abXYcd');
      expect(result, <RichTextRun>[
        const RichTextRun(text: 'ab', bold: true),
        const RichTextRun(text: 'XYcd'),
      ]);
    });

    test('reconcileRuns applies the active format to typed characters', () {
      final List<RichTextRun> result = reconcileRuns(
        runs: <RichTextRun>[const RichTextRun(text: 'ab')],
        oldText: 'ab',
        newText: 'abc',
        insertedFormat: const RunFormat(italic: true),
      );

      expect(result, <RichTextRun>[
        const RichTextRun(text: 'ab'),
        const RichTextRun(text: 'c', italic: true),
      ]);
    });

    test('reconcileRuns preserves formatting across deletions', () {
      final List<RichTextRun> runs = <RichTextRun>[
        const RichTextRun(text: 'ab', bold: true),
        const RichTextRun(text: 'cd', italic: true),
      ];
      // Delete "bc" from the middle.
      final List<RichTextRun> result = reconcileRuns(
        runs: runs,
        oldText: 'abcd',
        newText: 'ad',
        insertedFormat: RunFormat.none,
      );

      expect(result, <RichTextRun>[
        const RichTextRun(text: 'a', bold: true),
        const RichTextRun(text: 'd', italic: true),
      ]);
    });

    test('rich text survives a serialization round-trip with mixed runs', () {
      final FieldValue value = FieldValue.rich(applyFormatToRange(
        applyFormatToRange(
          <RichTextRun>[const RichTextRun(text: 'mixed format')],
          0,
          5,
          (RunFormat f) => f.copyWith(bold: true).withColor('#B00020'),
        ),
        6,
        12,
        (RunFormat f) => f.withHighlight('#FFE066'),
      ));

      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <String, FieldValue>{'DE': value},
          ),
        ],
      );

      final LearningDeck restored = decodeDeckJson(encodeDeckJson(deck));
      expect(restored.units.single.fields['DE'], value);
    });
  });

  group('session item ordering', () {
    test('returns in-scope items in file order when shuffle is off', () {
      final LearningDeck deck = sampleDeck();
      const SessionParameters parameters = SessionParameters(
        directionSelection: DirectionSelection.direction1,
      );
      final List<SessionItem> order = sessionItemOrder(
        deck: deck,
        parameters: parameters,
        random: Random(0),
      );
      expect(order, itemsInScope(deck, parameters));
    });

    test('shuffle keeps the same items but can reorder them', () {
      final LearningDeck deck = sampleDeck();
      const SessionParameters parameters = SessionParameters(
        directionSelection: DirectionSelection.both,
        shuffle: true,
      );
      final List<SessionItem> ordered = itemsInScope(deck, parameters);
      final List<SessionItem> shuffled = sessionItemOrder(
        deck: deck,
        parameters: parameters,
        random: Random(1),
      );
      expect(shuffled.toSet(), ordered.toSet());
      expect(shuffled, hasLength(ordered.length));
    });

    test('once-through serves every item once, then stops', () {
      final LearningDeck deck = sampleDeck();
      const SessionParameters parameters = SessionParameters(
        directionSelection: DirectionSelection.direction1,
        mode: SessionMode.onceThrough,
      );
      final Random random = Random(3);
      final Set<SessionItem> seen = <SessionItem>{};
      SessionItem? next;
      while ((next = pickPracticeItem(
            deck: deck,
            parameters: parameters,
            random: random,
            seenItems: seen,
          )) !=
          null) {
        expect(seen.add(next!), isTrue);
      }
      expect(seen, itemsInScope(deck, parameters).toSet());
    });
  });

  group('settings and unit range', () {
    test('round-trips settings through JSON serialization', () {
      const LearnAnywhereSettings settings = LearnAnywhereSettings(
        wrongInputCorrectable: false,
        completeInputRequired: false,
        caseSensitive: true,
        accentSensitive: true,
        showClock: true,
        timeLimitSeconds: 90,
        minimumAttemptsGuardEnabled: true,
        minAttempts: 4,
        wrongAnswerCeilingEnabled: true,
        wrongAnswerCeiling: 7,
        mode: SessionMode.onceThrough,
        direction: DirectionSelection.direction2,
        shuffle: true,
        requireTypedAnswers: false,
        superStatusThreshold: 0.6,
        lastDeckPath: '/decks/french1.vok',
        lastMaskPath: '/masks/french.inf',
      );

      final LearnAnywhereSettings restored = decodeSettingsJson(
        encodeSettingsJson(settings),
      );
      expect(restored, settings);
    });

    test('decodes partial settings with defaults and ignores corruption', () {
      const LearnAnywhereSettings defaults = LearnAnywhereSettings();
      final LearnAnywhereSettings partial = decodeSettings(<String, Object?>{
        'shuffle': true,
        'mode': 'practice',
      });
      expect(partial.shuffle, isTrue);
      expect(partial.mode, SessionMode.practice);
      expect(partial.direction, defaults.direction);
      expect(partial.minAttempts, defaults.minAttempts);

      // Unknown enum names and wrong types fall back to defaults.
      final LearnAnywhereSettings broken = decodeSettings(<String, Object?>{
        'mode': 'bogus',
        'minAttempts': 'not-an-int',
      });
      expect(broken.mode, defaults.mode);
      expect(broken.minAttempts, defaults.minAttempts);
    });

    test('resets the unit range when a file is loaded', () {
      final UnitRangeSelection range = resetUnitRange(12);
      expect(range.startUnit, 1);
      expect(range.endUnit, 12);
      expect(range.endManuallySet, isFalse);
      // Empty decks still produce a usable 1..1 range.
      expect(resetUnitRange(0).endUnit, 1);
    });

    test('auto-expands the end unit only without a manual override', () {
      const UnitRangeSelection full = UnitRangeSelection(
        startUnit: 1,
        endUnit: 10,
      );
      expect(
        autoExpandEndUnit(full, previousCount: 10, newCount: 15).endUnit,
        15,
      );

      const UnitRangeSelection restricted = UnitRangeSelection(
        startUnit: 1,
        endUnit: 6,
        endManuallySet: true,
      );
      expect(
        autoExpandEndUnit(restricted, previousCount: 10, newCount: 15).endUnit,
        6,
      );

      // A user who left the range full but typed the same value is respected.
      const UnitRangeSelection manualFull = UnitRangeSelection(
        startUnit: 1,
        endUnit: 10,
        endManuallySet: true,
      );
      expect(
        autoExpandEndUnit(manualFull, previousCount: 10, newCount: 15).endUnit,
        10,
      );
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
