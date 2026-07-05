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

    test('canonical format examples load and re-encode losslessly', () {
      // These files under docs/format-examples/ are the format contract handed
      // to the Converter. They must always re-encode byte-for-byte through the
      // real serializers (regenerate via tool/generate_format_examples.dart).
      final String infSource = File(
        '../../docs/format-examples/example.inf',
      ).readAsStringSync();
      final String vokSource = File(
        '../../docs/format-examples/example.vok',
      ).readAsStringSync();

      final LearningMask mask = decodeMaskJson(infSource);
      final LearningDeck deck = decodeDeckJson(vokSource);

      // Identity survived the round trip exactly (maskId never recomputed).
      expect(mask.maskId, 'm_new_example-french-0001');
      expect(mask.revision, 3);
      expect(deck.mask.maskId, mask.maskId);
      // Field ids form one 0-based space across both categories.
      expect(
        deck.mask.categories.expand((CategoryDefinition c) => c.fields).map(
          (FieldDefinition f) => f.id,
        ),
        <int>[0, 1, 2, 3, 4, 5],
      );
      // A unit in the second category references its own (mask-wide) field ids.
      expect(deck.units.last.categoryId, 1);
      expect(deck.units.last.valueForFieldId(4).plainText, 'aller');

      expect(encodeMaskJson(mask), infSource);
      expect(encodeDeckJson(deck), vokSource);
    });

    test('self-heals a legacy deck lacking ids and keyed by field name', () {
      // An older/hand-edited APP deck: no maskId, no category/field ids, unit
      // values keyed by field NAME. It must load without crashing, minting a
      // fresh app maskId and assigning 0-based ids in array order, with the
      // name-keyed values migrated onto the healed field ids.
      const String legacy = '''
{
  "format": "learn-anywhere/lessons",
  "version": 1,
  "mask": {
    "name": "Legacy",
    "direction1Label": "A",
    "direction2Label": "B",
    "categories": [
      { "name": "Words", "fields": [
        {"name":"Q","length":40,"equalGroup":0,"role1":"Q","role2":"A"},
        {"name":"A","length":40,"equalGroup":0,"role1":"A","role2":"Q"}
      ]}
    ]
  },
  "units": [
    { "categoryId": 0, "fields": {"Q":"hello","A":"bonjour"} }
  ]
}
''';
      final LearningDeck deck = decodeDeckJson(legacy);

      expect(deck.mask.maskId, startsWith(appMaskIdPrefix));
      expect(deck.mask.maskId, isNot(startsWith(legacyMaskIdPrefix)));
      expect(deck.mask.revision, 0);
      expect(deck.mask.categories.single.id, 0);
      expect(
        deck.mask.categories.single.fields.map((FieldDefinition f) => f.id),
        <int>[0, 1],
      );
      final LearningUnit unit = deck.units.single;
      expect(unit.valueForFieldId(0).plainText, 'hello'); // healed from "Q"
      expect(unit.valueForFieldId(1).plainText, 'bonjour'); // healed from "A"

      // Re-encoding lifts it to the authoritative new format (id-keyed).
      final LearningDeck reloaded = decodeDeckJson(encodeDeckJson(deck));
      expect(reloaded.units.single.valueForFieldId(0).plainText, 'hello');
      expect(reloaded.mask.maskId, deck.mask.maskId);
    });

    test('still rejects genuinely malformed masks while self-healing ids', () {
      const String badRole = '''
{
  "format": "learn-anywhere/mask",
  "version": 1,
  "name": "Bad",
  "direction1Label": "A",
  "direction2Label": "B",
  "categories": [
    { "name": "C", "fields": [
      {"name":"F","length":40,"equalGroup":0,"role1":"X","role2":"A"}
    ]}
  ]
}
''';
      expect(
        () => decodeMaskJson(badRole),
        throwsA(isA<ValidationException>()),
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

  group('mask compatibility', () {
    MaskCompatibilityResult check(LearningMask newMask) {
      return checkMaskCompatibility(
        oldMask: compatMask(),
        newMask: newMask,
        units: compatUnits(),
      );
    }

    test('rename mask, direction labels, category and fields are compatible', () {
      final LearningMask renamed = compatMask().copyWith(
        name: 'Renamed',
        direction1Label: 'X',
        direction2Label: 'Y',
        categories: <CategoryDefinition>[
          const CategoryDefinition(
            id: 0,
            name: 'Renamed Noun',
            fields: <FieldDefinition>[
              // Same ids, different names/roles/equalGroup: all non-breaking.
              FieldDefinition(
                id: 0,
                name: 'German word',
                length: 40,
                equalGroup: 3,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
              FieldDefinition(
                id: 1,
                name: 'French word',
                length: 40,
                equalGroup: 3,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
            ],
          ),
          compatVerbCategory(),
        ],
      );
      expect(check(renamed).isCompatible, isTrue);
    });

    test('adding a category or field and increasing a length is compatible', () {
      final CategoryDefinition noun = CategoryDefinition(
        id: 0,
        name: 'Noun',
        fields: <FieldDefinition>[
          // id 0 length increased 40 -> 80.
          const FieldDefinition(
            id: 0,
            name: 'DE',
            length: 80,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          compatFrField(),
          // New field id 9 added.
          const FieldDefinition(
            id: 9,
            name: 'Extra',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
        ],
      );
      final LearningMask expanded = compatMask().copyWith(
        categories: <CategoryDefinition>[
          noun,
          compatVerbCategory(),
          // New category id 5 added.
          const CategoryDefinition(
            id: 5,
            name: 'Adjective',
            fields: <FieldDefinition>[],
          ),
        ],
      );
      expect(check(expanded).isCompatible, isTrue);
    });

    test('reordering categories and fields is compatible', () {
      final LearningMask reordered = compatMask().copyWith(
        categories: <CategoryDefinition>[
          // Verb before Noun; Noun's fields swapped. Ids unchanged.
          compatVerbCategory(),
          CategoryDefinition(
            id: 0,
            name: 'Noun',
            fields: <FieldDefinition>[compatFrField(), compatDeField()],
          ),
        ],
      );
      expect(check(reordered).isCompatible, isTrue);
    });

    test('deleting a category referenced by a unit is breaking', () {
      // Drop the Verb category (id 1); a unit references it.
      final LearningMask dropped = compatMask().copyWith(
        categories: <CategoryDefinition>[compatNounCategory()],
      );
      final MaskCompatibilityResult result = check(dropped);
      expect(result.isCompatible, isFalse);
      expect(result.reasons.single.kind, MaskBreakingKind.categoryDeleted);
      expect(result.reasons.single.categoryId, 1);
      expect(result.reasons.single.affectedUnits, 1);
    });

    test('deleting an empty (unreferenced) category is compatible', () {
      // The Verb category is referenced, but add then delete an empty category.
      final LearningMask withEmpty = compatMask().copyWith(
        categories: <CategoryDefinition>[
          compatNounCategory(),
          compatVerbCategory(),
          const CategoryDefinition(id: 7, name: 'Unused', fields: <FieldDefinition>[]),
        ],
      );
      // Deleting id 7 (no units) from that mask is compatible.
      final MaskCompatibilityResult result = checkMaskCompatibility(
        oldMask: withEmpty,
        newMask: compatMask(),
        units: compatUnits(),
      );
      expect(result.isCompatible, isTrue);
    });

    test('deleting a field with stored data is breaking, blank is not', () {
      // Remove FR field (id 1) from Noun; a unit stores "maison" there.
      final LearningMask dropFr = compatMask().copyWith(
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'Noun',
            fields: <FieldDefinition>[compatDeField()],
          ),
          compatVerbCategory(),
        ],
      );
      final MaskCompatibilityResult breaking = check(dropFr);
      expect(breaking.isCompatible, isFalse);
      expect(breaking.reasons.single.kind, MaskBreakingKind.fieldDeleted);
      expect(breaking.reasons.single.fieldId, 1);

      // Deleting a field that is blank in every unit is compatible.
      final LearningMask dropBlank = compatMask().copyWith(
        categories: <CategoryDefinition>[
          compatNounCategory(),
          const CategoryDefinition(
            id: 1,
            name: 'Verb',
            // Drop the always-blank remark field id 3, keep infinitive id 2.
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 2,
                name: 'Infinitive',
                length: 40,
                equalGroup: 0,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
            ],
          ),
        ],
      );
      expect(check(dropBlank).isCompatible, isTrue);
    });

    test('shrinking a field below stored data is breaking, above is not', () {
      // "maison" is 6 chars. Shrink FR (id 1) to 5 -> breaking; to 6 -> ok.
      LearningMask shrinkTo(int length) => compatMask().copyWith(
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'Noun',
            fields: <FieldDefinition>[
              compatDeField(),
              FieldDefinition(
                id: 1,
                name: 'FR',
                length: length,
                equalGroup: 0,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
          compatVerbCategory(),
        ],
      );
      final MaskCompatibilityResult tooShort = check(shrinkTo(5));
      expect(tooShort.isCompatible, isFalse);
      expect(tooShort.reasons.single.kind, MaskBreakingKind.fieldLengthTooShort);
      expect(tooShort.reasons.single.newLength, 5);
      expect(check(shrinkTo(6)).isCompatible, isTrue);
    });

    test('renaming a field (same id) is compatible and loses no data', () {
      // New mask renames FR (id 1) to "French" and reorders the two fields.
      final LearningMask renamed = compatMask().copyWith(
        categories: <CategoryDefinition>[
          const CategoryDefinition(
            id: 0,
            name: 'Noun',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 1,
                name: 'French',
                length: 40,
                equalGroup: 0,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
              FieldDefinition(
                id: 0,
                name: 'German',
                length: 40,
                equalGroup: 0,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
            ],
          ),
          compatVerbCategory(),
        ],
      );
      expect(check(renamed).isCompatible, isTrue);
      // Applying keeps every value on its id despite the rename + reorder.
      final LearningDeck deck = LearningDeck(
        mask: compatMask(),
        units: compatUnits(),
      );
      final LearningDeck updated = applyMaskToDeck(deck, renamed);
      final LearningUnit noun = updated.units.first;
      expect(noun.valueForFieldId(0).plainText, 'Haus'); // German
      expect(noun.valueForFieldId(1).plainText, 'maison'); // French (renamed)
    });

    test('applyMaskToDeck prunes dropped categories/fields and truncates', () {
      final LearningDeck deck = LearningDeck(
        mask: compatMask(),
        units: compatUnits(),
      );
      // New mask: drop the Verb category (id 1) entirely and, in Noun, drop the
      // DE field (id 0) and shrink FR (id 1) from 40 to 3 characters.
      final LearningMask pruned = compatMask().copyWith(
        categories: <CategoryDefinition>[
          const CategoryDefinition(
            id: 0,
            name: 'Noun',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 1,
                name: 'FR',
                length: 3,
                equalGroup: 0,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
        ],
      );
      final LearningDeck result = applyMaskToDeck(deck, pruned);

      // The verb unit (category id 1) is gone; only the noun unit remains.
      expect(result.units, hasLength(1));
      final LearningUnit unit = result.units.single;
      expect(unit.categoryId, 0);
      // DE (id 0) dropped; FR (id 1) kept but truncated "maison" -> "mai".
      expect(unit.fields.containsKey(0), isFalse);
      expect(unit.valueForFieldId(1).plainText, 'mai');
      // The result re-encodes and reloads cleanly under the new schema.
      final LearningDeck reloaded = decodeDeckJson(encodeDeckJson(result));
      expect(reloaded.units.single.valueForFieldId(1).plainText, 'mai');
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
        enteredValues: const <int, FieldValue>{
          1: FieldValue.plain('un lapin'), // FR1
          2: FieldValue.plain('le lapin'), // FR2
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
        enteredValues: const <int, FieldValue>{
          1: FieldValue.plain('TRES IMPORTANT'), // FR1
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
        enteredValues: const <int, FieldValue>{
          1: FieldValue.plain('un lapin'), // FR1
        },
      );
      final AnswerEvaluation partialAllowed = evaluateAnswer(
        deck: deck,
        unit: deck.units.first,
        direction: QueryDirection.direction1,
        enteredValues: const <int, FieldValue>{
          1: FieldValue.plain('un lapin'), // FR1
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
        enteredValues: const <int, FieldValue>{
          1: FieldValue.plain('un lapin'), // FR1
          2: FieldValue.plain('wrong'), // FR2
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
            fields: <int, FieldValue>{0: value}, // DE
          ),
        ],
      );

      final LearningDeck restored = decodeDeckJson(encodeDeckJson(deck));
      expect(restored.units.single.fields[0], value); // DE
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

// --- Fixtures for the mask-compatibility tests ----------------------------

FieldDefinition compatDeField() => const FieldDefinition(
  id: 0,
  name: 'DE',
  length: 40,
  equalGroup: 0,
  role1: FieldRole.question,
  role2: FieldRole.answer,
);

FieldDefinition compatFrField() => const FieldDefinition(
  id: 1,
  name: 'FR',
  length: 40,
  equalGroup: 0,
  role1: FieldRole.answer,
  role2: FieldRole.question,
);

CategoryDefinition compatNounCategory() => CategoryDefinition(
  id: 0,
  name: 'Noun',
  fields: <FieldDefinition>[compatDeField(), compatFrField()],
);

CategoryDefinition compatVerbCategory() => const CategoryDefinition(
  id: 1,
  name: 'Verb',
  fields: <FieldDefinition>[
    FieldDefinition(
      id: 2,
      name: 'Infinitive',
      length: 40,
      equalGroup: 0,
      role1: FieldRole.question,
      role2: FieldRole.answer,
    ),
    // Field id 3 is always blank in the fixture units (used to prove that
    // deleting an empty field is compatible).
    FieldDefinition(
      id: 3,
      name: 'Remark',
      length: 40,
      equalGroup: 0,
      role1: FieldRole.remark,
      role2: FieldRole.remark,
    ),
  ],
);

LearningMask compatMask() => LearningMask(
  maskId: 'm_new_compat-fixture',
  name: 'Compat',
  direction1Label: 'A',
  direction2Label: 'B',
  categories: <CategoryDefinition>[compatNounCategory(), compatVerbCategory()],
);

List<LearningUnit> compatUnits() => const <LearningUnit>[
  LearningUnit(
    categoryId: 0,
    fields: <int, FieldValue>{
      0: FieldValue.plain('Haus'),
      1: FieldValue.plain('maison'), // 6 chars — drives the length tests
    },
  ),
  LearningUnit(
    categoryId: 1,
    fields: <int, FieldValue>{
      2: FieldValue.plain('gehen'),
      // id 3 left blank on purpose
    },
  ),
];

LearningMask sampleMask() {
  return const LearningMask(
    maskId: 'm_new_sample-fixture',
    name: 'French 1',
    direction1Label: 'DE-FR',
    direction2Label: 'FR-DE',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
        name: 'Noun',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'DE',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'FR1',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 2,
            name: 'FR2',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 3,
            name: 'Note',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
          FieldDefinition(
            id: 4,
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
        fields: <int, FieldValue>{
          0: FieldValue.plain('ein Kaninchen'), // DE
          1: FieldValue.plain('le lapin'), // FR1
          2: FieldValue.plain('un lapin'), // FR2
          3: FieldValue.plain('animal'), // Note
        },
      ),
      LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: const FieldValue.plain('wichtig'), // DE
          1: FieldValue.rich(<RichTextRun>[
            const RichTextRun(
              text: 'tr\u00E8s important',
              bold: true,
              color: '#CC0000',
            ),
          ]), // FR1
          2: const FieldValue.plain(''), // FR2
          3: const FieldValue.plain('adjective'), // Note
        },
      ),
    ],
  );
}
