import 'dart:convert';
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
      // These files under test/fixtures/ are the format contract handed to the
      // Converter, documented in docs/file-formats.md. They must always
      // re-encode byte-for-byte through the real serializers (regenerate via
      // tool/generate_format_examples.dart).
      final String infSource = File(
        'test/fixtures/example.inf',
      ).readAsStringSync();
      final String vokSource = File(
        'test/fixtures/example.vok',
      ).readAsStringSync();

      final LearningMask mask = decodeMaskJson(infSource);
      final LearningDeck deck = decodeDeckJson(vokSource);

      // Identity survived the round trip exactly (maskId never recomputed).
      expect(mask.maskId, 'm_new_example-french-0001');
      expect(mask.revision, 3);
      expect(deck.mask.maskId, mask.maskId);
      // Field ids form one 0-based space across both categories.
      expect(
        deck.mask.categories
            .expand((CategoryDefinition c) => c.fields)
            .map((FieldDefinition f) => f.id),
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

    test(
      'rename mask, direction labels, category and fields are compatible',
      () {
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
      },
    );

    test(
      'adding a category or field and increasing a length is compatible',
      () {
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
      },
    );

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
          const CategoryDefinition(
            id: 7,
            name: 'Unused',
            fields: <FieldDefinition>[],
          ),
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
      expect(
        tooShort.reasons.single.kind,
        MaskBreakingKind.fieldLengthTooShort,
      );
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
        LearnAnywhereCatalog.message(LearnAnywhereMessage.learnPrompt, 'en'),
        'Prompt',
      );
      expect(
        LearnAnywhereCatalog.message(LearnAnywhereMessage.learnPrompt, 'de'),
        'Frage',
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
      expect(summary.totalAttempts, 1 + 4 + 2 + 4 + 10 + 2);
      expect(summary.totalCorrect, 1 + 3 + 1 + 1 + 1);
      expect(summary.attemptsHitRate, closeTo(7 / 23, 1e-9));
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
  });

  group('statistics remapping', () {
    List<UnitStats> seed() => <UnitStats>[
      const UnitStats(
        index: 1,
        direction1: DirectionStats(attempts: 1, correct: 1),
      ),
      const UnitStats(
        index: 2,
        direction1: DirectionStats(attempts: 2, correct: 2),
      ),
      const UnitStats(
        index: 3,
        direction1: DirectionStats(attempts: 3, correct: 3),
      ),
    ];

    test('resizeUnitStats keeps indices, pads growth, trims shrink', () {
      expect(resizeUnitStats(seed(), 5), hasLength(5));
      expect(resizeUnitStats(seed(), 5)[2].direction1.attempts, 3);
      expect(resizeUnitStats(seed(), 5)[3].direction1.attempts, 0);
      expect(resizeUnitStats(seed(), 2), hasLength(2));
      expect(resizeUnitStats(seed(), 2)[1].direction1.correct, 2);
    });

    test('statsAfterInsert shifts later units and zeroes the new slot', () {
      final List<UnitStats> result = statsAfterInsert(seed(), 2, 4);
      expect(result, hasLength(4));
      // Unit 1 unchanged; new empty at index 2; old 2 and 3 shifted to 3 and 4.
      expect(result[0].direction1.attempts, 1);
      expect(result[1].direction1.attempts, 0);
      expect(result[2].direction1.attempts, 2);
      expect(result[3].direction1.attempts, 3);
    });

    test('statsAfterInsert at the end preserves all and appends empty', () {
      final List<UnitStats> result = statsAfterInsert(seed(), 4, 4);
      expect(result.take(3).map((UnitStats s) => s.direction1.attempts), <int>[
        1,
        2,
        3,
      ]);
      expect(result[3].direction1.attempts, 0);
    });

    test('statsAfterDelete drops the removed unit and shifts later down', () {
      final List<UnitStats> result = statsAfterDelete(seed(), 2, 2);
      expect(result, hasLength(2));
      // Unit 1 kept; old unit 3 shifts down into index 2.
      expect(result[0].direction1.attempts, 1);
      expect(result[1].direction1.attempts, 3);
    });
  });

  group('unit identity hashes', () {
    LearningUnit unitOf(
      String de,
      String fr, {
      String note = '',
      int categoryId = 1,
    }) {
      return LearningUnit(
        categoryId: categoryId,
        fields: <int, FieldValue>{
          0: FieldValue.plain(de), // DE — Q in dir 1, A in dir 2
          1: FieldValue.plain(fr), // FR1 — A in dir 1, Q in dir 2
          3: FieldValue.plain(note), // Note — remark in both directions
        },
      );
    }

    test('is stable across repeated computations', () {
      final LearningMask mask = sampleMask();
      final LearningUnit unit = unitOf('Haus', 'maison');
      expect(unitIdentityHash(mask, unit), unitIdentityHash(mask, unit));
      expect(unitIdentityHash(mask, unit), matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('ignores remark fields', () {
      final LearningMask mask = sampleMask();
      expect(
        unitIdentityHash(mask, unitOf('Haus', 'maison', note: 'noun')),
        unitIdentityHash(mask, unitOf('Haus', 'maison', note: 'rewritten')),
      );
    });

    test('changes when a question or answer value changes', () {
      final LearningMask mask = sampleMask();
      final String base = unitIdentityHash(mask, unitOf('Haus', 'maison'));
      expect(unitIdentityHash(mask, unitOf('Hause', 'maison')), isNot(base));
      expect(unitIdentityHash(mask, unitOf('Haus', 'maisons')), isNot(base));
    });

    test('ignores rich-text formatting, tracking plain text only', () {
      final LearningMask mask = sampleMask();
      final LearningUnit plain = unitOf('Haus', 'maison');
      final LearningUnit formatted = LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: const FieldValue.plain('Haus'),
          1: FieldValue.rich(<RichTextRun>[
            const RichTextRun(text: 'maison', bold: true, color: '#CC0000'),
          ]),
          3: const FieldValue.plain(''),
        },
      );
      expect(unitIdentityHash(mask, formatted), unitIdentityHash(mask, plain));
    });

    test('changes when a field role changes', () {
      final LearningMask mask = sampleMask();
      final CategoryDefinition category = mask.categories.single;
      final LearningMask rerolled = mask.copyWith(
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: category.id,
            name: category.name,
            fields: <FieldDefinition>[
              for (final FieldDefinition field in category.fields)
                if (field.id == 1)
                  FieldDefinition(
                    id: field.id,
                    name: field.name,
                    length: field.length,
                    equalGroup: field.equalGroup,
                    role1: FieldRole.remark,
                    role2: FieldRole.remark,
                  )
                else
                  field,
            ],
          ),
        ],
      );
      expect(
        unitIdentityHash(rerolled, unitOf('Haus', 'maison')),
        isNot(unitIdentityHash(mask, unitOf('Haus', 'maison'))),
      );
    });

    test('round-trips through the .sta file byte-for-byte', () {
      final LearningDeck deck = sampleDeck();
      final StatisticsFile file = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: withUnitHashes(deck, <UnitStats>[
          const UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 2, correct: 1),
          ),
          const UnitStats(index: 2),
        ]),
      );

      final String encoded = encodeStatisticsJson(file);
      final StatisticsFile restored = decodeStatisticsJson(encoded);
      expect(restored.perUnit.first.hash, deckUnitHashes(deck).first);
      expect(encodeStatisticsJson(restored), encoded);
    });

    test('omits the hash key entirely when no hash is known', () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
      );
      final Map<String, Object?> raw =
          jsonDecode(encodeStatisticsJson(file)) as Map<String, Object?>;
      final Map<String, Object?> entry =
          (raw['perUnit']! as List<Object?>).single as Map<String, Object?>;
      expect(entry.containsKey('hash'), isFalse);
      expect(raw['version'], currentStatisticsVersion);
    });
  });

  group('statistics realignment', () {
    LearningUnit unitOf(String de, String fr, {String note = ''}) {
      return LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: FieldValue.plain(de),
          1: FieldValue.plain(fr),
          3: FieldValue.plain(note),
        },
      );
    }

    final LearningUnit a = unitOf('eins', 'un', note: 'first');
    final LearningUnit b = unitOf('zwei', 'deux');
    final LearningUnit c = unitOf('drei', 'trois');

    LearningDeck deckOf(List<LearningUnit> units) =>
        LearningDeck(mask: sampleMask(), units: units);

    /// Stats carrying `attempts` attempts (all correct) per unit, hashed
    /// against [deck] exactly as a `.sta` written for that deck would be.
    List<UnitStats> hashedStats(LearningDeck deck, List<int> attempts) {
      return withUnitHashes(deck, <UnitStats>[
        for (var i = 0; i < attempts.length; i += 1)
          UnitStats(
            index: i + 1,
            direction1: DirectionStats(
              attempts: attempts[i],
              correct: attempts[i],
            ),
          ),
      ]);
    }

    List<int> attemptsOf(List<UnitStats> stats) => <int>[
      for (final UnitStats entry in stats) entry.direction1.attempts,
    ];

    final LearningDeck original = deckOf(<LearningUnit>[a, b, c]);

    test('an unchanged deck keeps every unit in place', () {
      final StatisticsRealignment result = realignStatistics(
        deck: original,
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 2, 3]);
      expect(result.resetUnits, 0);
    });

    test('appended units start clean without reporting a reset', () {
      final LearningDeck grown = deckOf(<LearningUnit>[
        a,
        b,
        c,
        unitOf('vier', 'quatre'),
      ]);
      final StatisticsRealignment result = realignStatistics(
        deck: grown,
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 2, 3, 0]);
      expect(result.resetUnits, 0);
    });

    test('a trailing deletion keeps the survivors and reports the loss', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[a, b]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 2]);
      expect(result.resetUnits, 1);
    });

    test('a mid-insertion shifts later units without losing anything', () {
      final LearningDeck inserted = deckOf(<LearningUnit>[
        a,
        unitOf('neu', 'nouveau'),
        b,
        c,
      ]);
      final StatisticsRealignment result = realignStatistics(
        deck: inserted,
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 0, 2, 3]);
      expect(result.resetUnits, 0);
    });

    test('a mid-deletion pulls later units down', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[a, c]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 3]);
      expect(result.resetUnits, 1);
    });

    test('a reorder carries statistics to the new positions', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[c, a, b]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[3, 1, 2]);
      expect(result.resetUnits, 0);
    });

    test('a remark-only edit keeps the unit\'s statistics', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[
          unitOf('eins', 'un', note: 'rewritten remark'),
          b,
          c,
        ]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 2, 3]);
      expect(result.resetUnits, 0);
    });

    test('a question or answer edit resets only that unit', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[a, unitOf('zwei', 'deux!'), c]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 0, 3]);
      expect(result.resetUnits, 1);
    });

    test('an untouched unit that was never queried is not counted', () {
      // Unit 2 is deleted but had no recorded attempts: nothing was lost.
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[a, c]),
        statistics: hashedStats(original, <int>[1, 0, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 3]);
      expect(result.resetUnits, 0);
    });

    test('duplicate units keep their own counters in stored order', () {
      final LearningDeck twins = deckOf(<LearningUnit>[a, b, a]);
      final StatisticsRealignment result = realignStatistics(
        deck: twins,
        statistics: hashedStats(twins, <int>[1, 2, 3]),
      );
      expect(attemptsOf(result.statistics), <int>[1, 2, 3]);
      expect(result.resetUnits, 0);
    });

    test('a legacy .sta without hashes still loads by index', () {
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[c, a, b, unitOf('vier', 'quatre')]),
        statistics: const <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 1, correct: 1)),
          UnitStats(index: 2, direction1: DirectionStats(attempts: 2, correct: 2)),
          UnitStats(index: 3, direction1: DirectionStats(attempts: 3, correct: 3)),
        ],
      );
      expect(attemptsOf(result.statistics), <int>[1, 2, 3, 0]);
      expect(result.resetUnits, 0);
    });

    test('the realigned statistics carry the deck\'s current hashes', () {
      final LearningDeck moved = deckOf(<LearningUnit>[b, a, c]);
      final StatisticsRealignment result = realignStatistics(
        deck: moved,
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(
        result.statistics.map((UnitStats s) => s.hash),
        deckUnitHashes(moved),
      );
    });

    test('Level-Learning statistics follow the same mapping', () {
      const LevelDirectionStats fresh = LevelDirectionStats(
        currentLevel: 3,
        levels: <int, DirectionStats>{
          3: DirectionStats(),
          2: DirectionStats(),
          1: DirectionStats(),
          0: DirectionStats(),
        },
      );
      LevelUnitStats levelAt(int index, int level) => LevelUnitStats(
        index: index,
        dir1: LevelDirectionStats(
          currentLevel: level,
          levels: const <int, DirectionStats>{
            3: DirectionStats(attempts: 1, correct: 1),
            2: DirectionStats(),
            1: DirectionStats(),
            0: DirectionStats(),
          },
        ),
        dir2: fresh,
      );

      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[c, a, b]),
        statistics: hashedStats(original, <int>[1, 2, 3]),
        levelStatistics: <LevelUnitStats>[levelAt(1, 2), levelAt(3, 1)],
      );

      expect(result.levelStatistics, hasLength(2));
      // Unit 1 moved to position 2, unit 3 to position 1.
      expect(
        <int, int>{
          for (final LevelUnitStats stats in result.levelStatistics)
            stats.index: stats.dir1.currentLevel,
        },
        <int, int>{2: 2, 1: 1},
      );
    });

    test('a lost unit with only ladder history still counts as reset', () {
      // The engine materializes a ladder entry as soon as a unit is practised
      // in Level Learning, which can happen before any drill attempt exists.
      final StatisticsRealignment result = realignStatistics(
        deck: deckOf(<LearningUnit>[a, c]),
        statistics: hashedStats(original, <int>[0, 0, 0]),
        levelStatistics: <LevelUnitStats>[
          LevelUnitStats(
            index: 2,
            dir1: LevelDirectionStats.fresh(kMaxSupportLevel),
            dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
          ),
        ],
      );
      expect(result.levelStatistics, isEmpty);
      expect(result.resetUnits, 1);
    });

    test('empty Level-Learning statistics stay empty', () {
      final StatisticsRealignment result = realignStatistics(
        deck: original,
        statistics: hashedStats(original, <int>[1, 2, 3]),
      );
      expect(result.levelStatistics, isEmpty);
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
        applyFormatToRange(
          source,
          3,
          3,
          (RunFormat f) => f.copyWith(bold: true),
        ),
        source,
      );
    });

    test(
      'formatAt inherits the preceding character, or the first when at 0',
      () {
        final List<RichTextRun> runs = <RichTextRun>[
          const RichTextRun(text: 'ab'),
          const RichTextRun(text: 'cd', bold: true),
        ];
        expect(formatAt(runs, 0).bold, isFalse);
        expect(formatAt(runs, 2).bold, isFalse);
        expect(formatAt(runs, 3).bold, isTrue);
        expect(formatAt(runs, 4).bold, isTrue);
        expect(formatAt(const <RichTextRun>[], 0), RunFormat.none);
      },
    );

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
      final FieldValue value = FieldValue.rich(
        applyFormatToRange(
          applyFormatToRange(
            <RichTextRun>[const RichTextRun(text: 'mixed format')],
            0,
            5,
            (RunFormat f) => f.copyWith(bold: true).withColor('#B00020'),
          ),
          6,
          12,
          (RunFormat f) => f.withHighlight('#FFE066'),
        ),
      );

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

    test('strikethrough survives a serialization round-trip', () {
      final FieldValue value = FieldValue.rich(<RichTextRun>[
        const RichTextRun(text: 'kept'),
        const RichTextRun(
          text: 'struck',
          strikethrough: true,
          underline: true,
          color: '#D32F2F',
        ),
      ]);
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: <LearningUnit>[
          LearningUnit(categoryId: 1, fields: <int, FieldValue>{0: value}),
        ],
      );

      // Only the true attribute is emitted, and it decodes back intact.
      final String json = encodeDeckJson(deck);
      expect(json.contains('"strikethrough": true'), isTrue);
      final LearningDeck restored = decodeDeckJson(json);
      expect(restored.units.single.fields[0], value);
    });

    test('a decoded run without strikethrough defaults to false', () {
      const RichTextRun run = RichTextRun(text: 'plain');
      expect(run.strikethrough, isFalse);
    });
  });

  group('answer similarity and Almost classification', () {
    test('levenshteinDistance on known pairs', () {
      expect(levenshteinDistance('kitten', 'kitten'), 0);
      expect(levenshteinDistance('kitten', 'sitten'), 1); // substitution
      expect(levenshteinDistance('kitten', 'kittens'), 1); // insertion
      expect(levenshteinDistance('kitten', 'itten'), 1); // deletion
      expect(levenshteinDistance('kitten', 'sitting'), 3);
      expect(levenshteinDistance('', 'abc'), 3);
    });

    test('normalizedSimilarity in 0..1 with empty-string edge', () {
      expect(normalizedSimilarity('', ''), 1.0);
      expect(normalizedSimilarity('house', 'house'), 1.0);
      // One substitution in five characters → 0.8.
      expect(normalizedSimilarity('house', 'mouse'), closeTo(0.8, 1e-9));
      expect(normalizedSimilarity('abc', 'xyz'), 0.0);
    });

    AnswerEvaluation evalOf(String expected, String entered) {
      return AnswerEvaluation(
        correct: expected == entered,
        fields: <FieldEvaluation>[
          FieldEvaluation(
            fieldName: 'A',
            expected: expected,
            entered: entered,
            correct: expected == entered,
          ),
        ],
      );
    }

    test('classifyOutcome: exact is always correct', () {
      expect(
        classifyOutcome(evalOf('haus', 'haus'), similarityEnabled: true),
        AnswerOutcome.correct,
      );
    });

    test('classifyOutcome: near-miss is Almost only when enabled', () {
      final AnswerEvaluation nearMiss = evalOf('mouse', 'house'); // sim 0.8
      expect(classifyOutcome(nearMiss), AnswerOutcome.wrong);
      expect(
        classifyOutcome(nearMiss, similarityEnabled: true),
        AnswerOutcome.almost,
      );
    });

    test('classifyOutcome: below threshold is plain wrong', () {
      expect(
        classifyOutcome(evalOf('elephant', 'ant'), similarityEnabled: true),
        AnswerOutcome.wrong,
      );
    });

    test('Close enough rating records like Actually correct', () {
      const DirectionStats before = DirectionStats(attempts: 2, correct: 1);
      // "Close enough" is the relabeled AttemptRating.correct.
      final DirectionStats after = recordAttempt(before, AttemptRating.correct);
      expect(after.attempts, 3);
      expect(after.correct, 2);
    });
  });

  group('diff alignment and overlay', () {
    test('alignTexts yields substitution/deletion/insertion ops', () {
      expect(
        alignTexts('cat', 'cot').map((DiffOp o) => o.kind).toList(),
        <DiffOpKind>[DiffOpKind.match, DiffOpKind.substitute, DiffOpKind.match],
      );
      // "hello" vs "helo": the second 'l' is missing from the entry.
      expect(
        alignTexts(
          'hello',
          'helo',
        ).where((DiffOp o) => o.kind == DiffOpKind.delete),
        hasLength(1),
      );
      // "cat" vs "cats": trailing 's' is extra in the entry.
      final List<DiffOp> extra = alignTexts(
        'cat',
        'cats',
      ).where((DiffOp o) => o.kind == DiffOpKind.insert).toList();
      expect(extra, hasLength(1));
      expect(extra.single.enteredIndex, 3);
    });

    test('buildDiffRuns paints only the substituted character red', () {
      final List<RichTextRun> runs = buildDiffRuns(
        expectedRuns: <RichTextRun>[
          const RichTextRun(text: 'ca', bold: true),
          const RichTextRun(text: 't', bold: true, italic: true),
        ],
        enteredPlain: 'cot',
      );
      // Expected plain stays "cat"; the 'a'→'o' substitution reddens only 'a'.
      expect(runsText(runs), 'cat');
      RunFormat formatAtChar(int index) => formatsFromRuns(runs)[index];
      expect(formatAtChar(0).color, isNull); // 'c' untouched
      expect(formatAtChar(0).bold, isTrue); // original bold kept
      expect(formatAtChar(1).color, kDiffMarkColor); // 'a' reddened
      expect(formatAtChar(1).bold, isTrue); // formatting otherwise preserved
      expect(formatAtChar(2).color, isNull); // 't' untouched
      expect(formatAtChar(2).italic, isTrue);
    });

    test('buildDiffRuns shows a missing character in red and underlined', () {
      final List<RichTextRun> runs = buildDiffRuns(
        expectedRuns: <RichTextRun>[const RichTextRun(text: 'hello')],
        enteredPlain: 'helo',
      );
      final String text = runsText(runs);
      // The omitted character stays visible as its real letter, so the complete
      // solution is shown; it is marked in the diff colour and underlined to
      // signal it was missed. Either identical 'l' is a valid deletion site.
      expect(text, 'hello');
      final List<RunFormat> formats = formatsFromRuns(runs);
      final Iterable<int> marked = <int>[
        for (int i = 0; i < formats.length; i++)
          if (formats[i].color == kDiffMarkColor) i,
      ];
      expect(marked, hasLength(1));
      final int missing = marked.single;
      expect(formats[missing].underline, isTrue);
      expect(text[missing], 'l');
    });

    test('buildDiffRuns marks a trailing extra as red strikethrough', () {
      final List<RichTextRun> runs = buildDiffRuns(
        expectedRuns: <RichTextRun>[const RichTextRun(text: 'cat')],
        enteredPlain: 'cats',
      );
      expect(runsText(runs), 'cats');
      final RichTextRun extra = runs.last;
      expect(extra.text, 's');
      expect(extra.strikethrough, isTrue);
      expect(extra.color, kDiffMarkColor);
    });

    test('buildDiffRuns keeps an extra character in place, not at the end', () {
      // "sausage" vs "saussage": the extra 's' must be struck through where it
      // was typed (after "saus"), not appended to the end.
      final List<RichTextRun> runs = buildDiffRuns(
        expectedRuns: <RichTextRun>[const RichTextRun(text: 'sausage')],
        enteredPlain: 'saussage',
      );
      final String text = runsText(runs);
      expect(text, 'saussage');
      final List<RunFormat> formats = formatsFromRuns(runs);
      final Iterable<int> struck = <int>[
        for (int i = 0; i < formats.length; i++)
          if (formats[i].strikethrough) i,
      ];
      // Exactly one struck-through character, and it sits mid-word (not last).
      expect(struck, hasLength(1));
      final int extra = struck.single;
      expect(text[extra], 's');
      expect(extra, lessThan(text.length - 1));
      expect(formats[extra].color, kDiffMarkColor);
    });

    test(
      'buildDiffRuns paints nothing for normalization-ignored differences',
      () {
        // Case- and accent-only differences with both options off must not be
        // painted: the diff must equal the untouched expected runs.
        const List<RichTextRun> expected = <RichTextRun>[
          RichTextRun(text: 'Café', bold: true),
        ];
        final List<RichTextRun> runs = buildDiffRuns(
          expectedRuns: expected,
          enteredPlain: 'cafe',
        );
        expect(runs, expected);
        expect(runs.every((RichTextRun r) => r.color == null), isTrue);
      },
    );

    test('a fully correct answer diffs to the unchanged solution', () {
      const List<RichTextRun> expected = <RichTextRun>[
        RichTextRun(text: 'right', italic: true),
      ];
      expect(
        buildDiffRuns(expectedRuns: expected, enteredPlain: 'right'),
        expected,
      );
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

    test('never serves the same item twice in a row from a 2-item pool', () {
      const List<SessionItem> pool = <SessionItem>[
        SessionItem(unitIndex: 1, direction: QueryDirection.direction1),
        SessionItem(unitIndex: 2, direction: QueryDirection.direction1),
      ];
      final Random random = Random(7);
      SessionItem last = pool.first;
      for (var i = 0; i < 100; i += 1) {
        final SessionItem? next = pickAvoidingRepeat(
          pool,
          random,
          lastItem: last,
        );
        expect(next, isNotNull);
        expect(next, isNot(last));
        last = next!;
      }
    });

    test('repeats the only item in a 1-item pool', () {
      const SessionItem only = SessionItem(
        unitIndex: 1,
        direction: QueryDirection.direction1,
      );
      expect(
        pickAvoidingRepeat(
          const <SessionItem>[only],
          Random(7),
          lastItem: only,
        ),
        only,
      );
    });

    test('returns null for an empty pool', () {
      expect(
        pickAvoidingRepeat(const <SessionItem>[], Random(7)),
        isNull,
      );
    });

    test('pickPracticeItem honours the no-immediate-repeat guard', () {
      final LearningDeck deck = sampleDeck();
      const SessionParameters parameters = SessionParameters(
        directionSelection: DirectionSelection.direction1,
      );
      final Random random = Random(11);
      SessionItem last = itemsInScope(deck, parameters).first;
      for (var i = 0; i < 100; i += 1) {
        final SessionItem? next = pickPracticeItem(
          deck: deck,
          parameters: parameters,
          random: random,
          lastItem: last,
        );
        expect(next, isNot(last));
        last = next!;
      }
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
        masteryThreshold: 0.6,
        keepStatisticsVersions: 5,
        lastDeckPath: '/decks/french1.vok',
        lastMaskPath: '/masks/french.inf',
      );

      final LearnAnywhereSettings restored = decodeSettingsJson(
        encodeSettingsJson(settings),
      );
      expect(restored, settings);
    });

    test('keepStatisticsVersions defaults to 3 and round-trips 0 (keep all)',
        () {
      expect(const LearnAnywhereSettings().keepStatisticsVersions, 3);
      const LearnAnywhereSettings keepAll = LearnAnywhereSettings(
        keepStatisticsVersions: 0,
      );
      expect(
        decodeSettingsJson(encodeSettingsJson(keepAll)).keepStatisticsVersions,
        0,
      );
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

    test('round-trips entryLevelCap and level names', () {
      const LearnAnywhereSettings settings = LearnAnywhereSettings(
        entryLevelCap: 2,
        levelNamesEn: <String>['A', 'B', 'C', 'D'],
        levelNamesDe: <String>['E', 'F', 'G', 'H'],
      );
      final LearnAnywhereSettings restored = decodeSettingsJson(
        encodeSettingsJson(settings),
      );
      expect(restored.entryLevelCap, 2);
      expect(restored.levelNamesEn, <String>['A', 'B', 'C', 'D']);
      expect(restored.levelNamesDe, <String>['E', 'F', 'G', 'H']);
      expect(restored, settings);
    });

    test('level-learning settings fall back to defaults when invalid', () {
      const LearnAnywhereSettings defaults = LearnAnywhereSettings();
      // Missing keys use defaults.
      final LearnAnywhereSettings empty = decodeSettings(<String, Object?>{});
      expect(empty.entryLevelCap, kMaxSupportLevel);
      expect(empty.levelNamesEn, kDefaultLevelNamesEn);
      expect(empty.levelNamesDe, kDefaultLevelNamesDe);
      // Out-of-range cap and wrong-length / wrong-typed name lists fall back.
      final LearnAnywhereSettings broken = decodeSettings(<String, Object?>{
        'entryLevelCap': 9,
        'levelNamesEn': <Object?>['only', 'three', 'names'],
        'levelNamesDe': <Object?>[1, 2, 3, 4],
      });
      expect(broken.entryLevelCap, defaults.entryLevelCap);
      expect(broken.levelNamesEn, kDefaultLevelNamesEn);
      expect(broken.levelNamesDe, kDefaultLevelNamesDe);
    });
  });

  group('level-learning masking', () {
    // Renders a mask template compactly: blanks become '_', every other cell
    // keeps its source character (shown structural chars and revealed letters).
    String render(String text, int level) => maskFieldValue(text, level)
        .map(
          (MaskCell cell) => cell.kind == MaskCellKind.blank ? '_' : cell.char,
        )
        .join();

    test('applies each level to a single word', () {
      expect(render('CHOCOLAT', 3), 'CHOCOLAT');
      expect(render('CHOCOLAT', 2), 'C_O_O_A_');
      expect(render('CHOCOLAT', 1), 'C______T');
      expect(render('CHOCOLAT', 0), '________');
    });

    test('restarts the pattern per word and always shows whitespace', () {
      final List<MaskCell> cells = maskFieldValue('le petit chat', 1);
      expect(render('le petit chat', 1), 'le p___t c__t');
      // The two spaces are shown verbatim, never blanks.
      final Iterable<MaskCell> spaces = cells.where(
        (MaskCell cell) => cell.char == ' ',
      );
      expect(spaces.length, 2);
      expect(
        spaces.every((MaskCell cell) => cell.kind == MaskCellKind.shown),
        isTrue,
      );
    });

    test('shows punctuation without counting it as a candidate', () {
      // Apostrophe is shown; candidates are l,e,a,u → level 2 reveals l,a.
      expect(render("l'eau", 2), "l'_a_");
      final List<MaskCell> cells = maskFieldValue("l'eau", 2);
      expect(cells[1].char, "'");
      expect(cells[1].kind, MaskCellKind.shown);
    });

    test('fully reveals 1- and 2-candidate words at level 1', () {
      expect(render('an', 1), 'an');
      expect(render('a', 1), 'a');
      expect(
        maskFieldValue(
          'an',
          1,
        ).every((MaskCell cell) => cell.kind == MaskCellKind.revealed),
        isTrue,
      );
    });

    test('rejects an out-of-range level', () {
      expect(() => maskFieldValue('word', 4), throwsArgumentError);
      expect(() => maskFieldValue('word', -1), throwsArgumentError);
    });
  });

  group('level-learning engine', () {
    const SessionParameters params = SessionParameters(
      mode: SessionMode.levelLearning,
      masteryThreshold: 0.5,
    );

    test('maps prior buckets to start levels', () {
      expect(levelForBucket(HitRateBucket.perfect), 0);
      expect(levelForBucket(HitRateBucket.good), 0);
      expect(levelForBucket(HitRateBucket.fair), 1);
      expect(levelForBucket(HitRateBucket.unsure), 2);
      expect(levelForBucket(HitRateBucket.veryUnsure), 3);
      expect(levelForBucket(HitRateBucket.neverKnown), 3);
      expect(levelForBucket(HitRateBucket.notYetQueried), 3);
    });

    test('seeds from prior bucket and applies the entry-level cap', () {
      expect(
        seedLevelLearningStats(
          const DirectionStats(attempts: 2, correct: 2),
        ).currentLevel,
        0,
      );
      expect(
        seedLevelLearningStats(
          const DirectionStats(attempts: 2, correct: 1),
        ).currentLevel,
        1,
      );
      expect(
        seedLevelLearningStats(
          const DirectionStats(attempts: 4, correct: 1),
        ).currentLevel,
        2,
      );
      expect(seedLevelLearningStats(const DirectionStats()).currentLevel, 3);
      // The cap lowers the *maximum* support (min), but never raises it.
      expect(
        seedLevelLearningStats(
          const DirectionStats(),
          entryLevelCap: 2,
        ).currentLevel,
        2,
      );
      expect(
        seedLevelLearningStats(
          const DirectionStats(attempts: 2, correct: 2),
          entryLevelCap: 2,
        ).currentLevel,
        0,
      );
      // Every seeded level starts with a fresh 0/0 track record.
      final LevelDirectionStats seeded = seedLevelLearningStats(
        const DirectionStats(attempts: 2, correct: 2),
      );
      expect(
        seeded.levels.values.every(
          (DirectionStats s) => s == const DirectionStats(),
        ),
        isTrue,
      );
    });

    test('promotes on reaching the threshold with a fresh lower level', () {
      final LevelDirectionStats start = LevelDirectionStats.fresh(3);
      final LevelDirectionStats afterOne = recordLevelLearningAttempt(
        start,
        AttemptRating.correct,
        parameters: params,
      );
      // 1/1 at level 3 meets the 0.5 threshold → promote to level 2.
      expect(afterOne.currentLevel, 2);
      expect(afterOne.levels[3], const DirectionStats(attempts: 1, correct: 1));
      expect(afterOne.levels[2], const DirectionStats());

      // Cascade continues down to level 0.
      var s = afterOne;
      for (var i = 0; i < 3; i += 1) {
        s = recordLevelLearningAttempt(
          s,
          AttemptRating.correct,
          parameters: params,
        );
      }
      expect(s.currentLevel, 0);
    });

    test('does not demote on a wrong answer', () {
      final LevelDirectionStats start = LevelDirectionStats.fresh(2);
      final LevelDirectionStats afterWrong = recordLevelLearningAttempt(
        start,
        AttemptRating.wrong,
        parameters: params,
      );
      expect(afterWrong.currentLevel, 2);
      expect(afterWrong.levels[2], const DirectionStats(attempts: 1));
    });

    test('level-0 single correct answer is mastered', () {
      final LevelDirectionStats start = LevelDirectionStats.fresh(0);
      expect(isLevelLearningMastered(start, parameters: params), isFalse);
      final LevelDirectionStats mastered = recordLevelLearningAttempt(
        start,
        AttemptRating.correct,
        parameters: params,
      );
      expect(mastered.currentLevel, 0);
      expect(isLevelLearningMastered(mastered, parameters: params), isTrue);
    });

    test('manual override moves the level and resets that level to 0/0', () {
      final LevelDirectionStats start = LevelDirectionStats.fresh(
        3,
      ).withLevelStats(3, const DirectionStats(attempts: 5, correct: 5));
      final LevelDirectionStats moved = setLevelLearningLevel(start, 1);
      expect(moved.currentLevel, 1);
      expect(moved.levels[1], const DirectionStats());
      // The other levels are untouched.
      expect(moved.levels[3], const DirectionStats(attempts: 5, correct: 5));
      expect(() => setLevelLearningLevel(start, 4), throwsArgumentError);
    });

    test('derives the active pool and needs both directions when both', () {
      final LearningDeck deck = sampleDeck();
      // Unit 1: dir1 mastered at level 0, dir2 still at level 2.
      final LevelDirectionStats masteredDir = LevelDirectionStats.fresh(
        0,
      ).withLevelStats(0, const DirectionStats(attempts: 1, correct: 1));
      final List<LevelUnitStats> levelStats = <LevelUnitStats>[
        LevelUnitStats(
          index: 1,
          dir1: masteredDir,
          dir2: LevelDirectionStats.fresh(2),
        ),
      ];
      // Unit 2 has no entry yet → seeded (not-yet-queried → level 3, active).
      final List<SessionItem> pool = activeLevelLearningPool(
        deck: deck,
        statistics: const <UnitStats>[],
        levelStatistics: levelStats,
        parameters: params,
      );
      expect(pool, const <SessionItem>[
        SessionItem(unitIndex: 1, direction: QueryDirection.direction2),
        SessionItem(unitIndex: 2, direction: QueryDirection.direction1),
        SessionItem(unitIndex: 2, direction: QueryDirection.direction2),
      ]);
    });
  });

  group('hasRecordedStatistics', () {
    test('is false for empty stores and for attempt-free unit stats', () {
      expect(
        hasRecordedStatistics(
          statistics: const <UnitStats>[],
          levelStatistics: const <LevelUnitStats>[],
        ),
        isFalse,
      );
      expect(
        hasRecordedStatistics(
          statistics: const <UnitStats>[UnitStats(index: 1)],
          levelStatistics: const <LevelUnitStats>[],
        ),
        isFalse,
      );
    });

    test('is true once a drill attempt exists in either direction', () {
      expect(
        hasRecordedStatistics(
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction2: DirectionStats(attempts: 1, correct: 0),
            ),
          ],
          levelStatistics: const <LevelUnitStats>[],
        ),
        isTrue,
      );
    });

    test('is true when the level ladder has any entry at all', () {
      expect(
        hasRecordedStatistics(
          statistics: const <UnitStats>[],
          levelStatistics: <LevelUnitStats>[
            LevelUnitStats(
              index: 1,
              dir1: LevelDirectionStats.fresh(kMaxSupportLevel),
              dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
            ),
          ],
        ),
        isTrue,
      );
    });
  });

  group('level-learning statistics matrix', () {
    // Unit 1: dir1 sits at level 2 (4/2 → fair), dir2 at level 0 (2/2 →
    // perfect). Unit 2: dir1 at level 3 fresh (0/0 → not yet practiced), dir2
    // at level 3 with 1/0 (→ never known). Unit 3 has no entry (excluded).
    const List<LevelUnitStats> levelStats = <LevelUnitStats>[
      LevelUnitStats(
        index: 1,
        dir1: LevelDirectionStats(
          currentLevel: 2,
          levels: <int, DirectionStats>{
            2: DirectionStats(attempts: 4, correct: 2),
          },
        ),
        dir2: LevelDirectionStats(
          currentLevel: 0,
          levels: <int, DirectionStats>{
            0: DirectionStats(attempts: 2, correct: 2),
          },
        ),
      ),
      LevelUnitStats(
        index: 2,
        dir1: LevelDirectionStats(
          currentLevel: 3,
          levels: <int, DirectionStats>{3: DirectionStats()},
        ),
        dir2: LevelDirectionStats(
          currentLevel: 3,
          levels: <int, DirectionStats>{3: DirectionStats(attempts: 1)},
        ),
      ),
    ];
    const List<int> scope = <int>[1, 2, 3];

    test('single-direction view places each unit by its current level', () {
      final LevelBucketMatrix matrix = levelBucketMatrix(
        levelStatistics: levelStats,
        unitIndices: scope,
        view: StatisticsDirectionView.direction1,
      );
      expect(matrix.grandTotal, 2);
      expect(matrix.rowTotals[2], 1);
      expect(matrix.rowTotals[3], 1);
      expect(matrix.rowTotals[0], 0);
      expect(matrix.columnTotals[HitRateBucket.fair], 1);
      expect(matrix.columnTotals[HitRateBucket.notYetQueried], 1);

      final List<LevelMatrixEntry> fairAtTwo = matrix.entriesAt(
        2,
        HitRateBucket.fair,
      );
      expect(fairAtTwo, hasLength(1));
      expect(fairAtTwo.single.unitIndex, 1);
      expect(fairAtTwo.single.direction, QueryDirection.direction1);
      // The drill-down carries that level's own counters, not other-mode ones.
      expect(
        fairAtTwo.single.stats,
        const DirectionStats(attempts: 4, correct: 2),
      );
    });

    test('combined view counts both directions independently', () {
      final LevelBucketMatrix matrix = levelBucketMatrix(
        levelStatistics: levelStats,
        unitIndices: scope,
        view: StatisticsDirectionView.combined,
      );
      // Unit 3 has no entry, so only 2 units × 2 directions = 4 entries.
      expect(matrix.grandTotal, 4);
      expect(matrix.rowTotals[3], 2);
      expect(matrix.rowTotals[2], 1);
      expect(matrix.rowTotals[0], 1);
      expect(matrix.countAt(0, HitRateBucket.perfect), 1);
      expect(matrix.countAt(3, HitRateBucket.notYetQueried), 1);
      expect(matrix.countAt(3, HitRateBucket.neverKnown), 1);
      // Column totals sum to the grand total.
      expect(
        matrix.columnTotals.values.reduce((int a, int b) => a + b),
        matrix.grandTotal,
      );
    });

    test('excludes out-of-scope and entry-less units', () {
      final LevelBucketMatrix matrix = levelBucketMatrix(
        levelStatistics: levelStats,
        unitIndices: const <int>[1],
        view: StatisticsDirectionView.combined,
      );
      expect(matrix.grandTotal, 2);
      expect(matrix.rowTotals[3], 0);
      // Every level/bucket cell is present even when empty.
      expect(matrix.entriesAt(1, HitRateBucket.good), isEmpty);
    });
  });

  group('level-learning ladder attempt totals', () {
    // Unit 1 climbed 3 -> 2 -> 1 in direction 1 (2 + 3 + 1 attempts, 4 correct)
    // and has one direction-2 attempt at level 3. Unit 2 sits untouched at
    // level 3. Unit 3 has no ladder entry at all.
    const List<LevelUnitStats> levelStats = <LevelUnitStats>[
      LevelUnitStats(
        index: 1,
        dir1: LevelDirectionStats(
          currentLevel: 1,
          levels: <int, DirectionStats>{
            3: DirectionStats(attempts: 2, correct: 2),
            2: DirectionStats(attempts: 3, correct: 1),
            1: DirectionStats(attempts: 1, correct: 1),
            0: DirectionStats(),
          },
        ),
        dir2: LevelDirectionStats(
          currentLevel: 3,
          levels: <int, DirectionStats>{3: DirectionStats(attempts: 1)},
        ),
      ),
      LevelUnitStats(
        index: 2,
        dir1: LevelDirectionStats(
          currentLevel: 3,
          levels: <int, DirectionStats>{3: DirectionStats()},
        ),
        dir2: LevelDirectionStats(
          currentLevel: 3,
          levels: <int, DirectionStats>{3: DirectionStats()},
        ),
      ),
    ];

    test('sums every level and both directions across the whole deck', () {
      final LadderAttemptTotals totals = aggregateLadderAttempts(
        levelStatistics: levelStats,
      );
      // 2 + 3 + 1 (unit 1, direction 1) + 1 (unit 1, direction 2); unit 2 is
      // untouched and unit 3 has no entry.
      expect(totals.attempts, 7);
      expect(totals.correct, 4);
    });

    test('counts levels a unit has left, not only its current one', () {
      final LadderAttemptTotals totals = aggregateLadderAttempts(
        levelStatistics: levelStats,
      );
      // Unit 1 sits at level 1, whose own counters hold a single attempt. The
      // deck-wide figure is larger because the climb below it is included.
      expect(levelStats.first.dir1.currentLevelStats.attempts, 1);
      expect(totals.attempts, 7);
    });

    test('an empty ladder totals zero', () {
      final LadderAttemptTotals totals = aggregateLadderAttempts(
        levelStatistics: const <LevelUnitStats>[],
      );
      expect(totals.attempts, 0);
      expect(totals.correct, 0);
    });
  });

  group('level-learning statistics serialization', () {
    LevelLearningStats sampleLevelStats() => const LevelLearningStats(
      perUnit: <LevelUnitStats>[
        LevelUnitStats(
          index: 1,
          dir1: LevelDirectionStats(
            currentLevel: 1,
            levels: <int, DirectionStats>{
              3: DirectionStats(attempts: 1, correct: 1),
              2: DirectionStats(attempts: 2, correct: 1),
              1: DirectionStats(),
              0: DirectionStats(),
            },
          ),
          dir2: LevelDirectionStats(
            currentLevel: 3,
            levels: <int, DirectionStats>{
              3: DirectionStats(),
              2: DirectionStats(),
              1: DirectionStats(),
              0: DirectionStats(),
            },
          ),
        ),
      ],
    );

    test('round-trips a v2 file with a levelLearning section', () {
      final StatisticsFile file = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: const <UnitStats>[UnitStats(index: 1)],
        levelLearning: sampleLevelStats(),
      );
      final String encoded = encodeStatisticsJson(file);
      final Map<String, Object?> raw =
          jsonDecode(encoded) as Map<String, Object?>;
      expect(raw['version'], currentStatisticsVersion);

      final StatisticsFile restored = decodeStatisticsJson(encoded);
      expect(restored.levelLearning, isNotNull);
      final LevelDirectionStats dir1 =
          restored.levelLearning!.perUnit.single.dir1;
      expect(dir1.currentLevel, 1);
      expect(dir1.levels[2], const DirectionStats(attempts: 2, correct: 1));
      expect(restored.levelLearning!.perUnit.single.dir2.currentLevel, 3);
    });

    test('round-trips a v2 file without a levelLearning section', () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
      );
      final StatisticsFile restored = decodeStatisticsJson(
        encodeStatisticsJson(file),
      );
      expect(restored.levelLearning, isNull);
    });

    test('round-trips lastSessionMode, and omits it when unknown', () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
        lastSessionMode: SessionMode.levelLearning,
      );
      final String encoded = encodeStatisticsJson(file);
      expect(
        decodeStatisticsJson(encoded).lastSessionMode,
        SessionMode.levelLearning,
      );

      const StatisticsFile unknown = StatisticsFile(
        deckRef: 'french1.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
      );
      final Map<String, Object?> raw =
          jsonDecode(encodeStatisticsJson(unknown)) as Map<String, Object?>;
      expect(raw.containsKey('lastSessionMode'), isFalse);
      expect(
        decodeStatisticsJson(encodeStatisticsJson(unknown)).lastSessionMode,
        isNull,
      );
    });

    test('decodes an unrecognised lastSessionMode as unknown', () {
      final StatisticsFile restored = decodeStatistics(<String, Object?>{
        'format': statisticsFormat,
        'version': currentStatisticsVersion,
        'deckRef': 'french1.vok',
        'perUnit': <Object?>[],
        'lastSessionMode': 'someModeFromTheFuture',
      });
      expect(restored.lastSessionMode, isNull);
    });

    test('accepts a legacy v1 file as an empty level-learning section', () {
      final StatisticsFile restored = decodeStatistics(<String, Object?>{
        'format': statisticsFormat,
        'version': 1,
        'deckRef': 'french1.vok',
        'perUnit': <Object?>[
          <String, Object?>{
            'index': 1,
            'dir1': <String, Object?>{'attempts': 0, 'correct': 0},
            'dir2': <String, Object?>{'attempts': 0, 'correct': 0},
          },
        ],
      });
      expect(restored.levelLearning, isNull);
    });

    test('rejects an invalid currentLevel or missing level key', () {
      Map<String, Object?> withDir1(Object? dir1) => <String, Object?>{
        'format': statisticsFormat,
        'version': currentStatisticsVersion,
        'deckRef': 'd.vok',
        'perUnit': <Object?>[],
        'levelLearning': <String, Object?>{
          'perUnit': <Object?>[
            <String, Object?>{
              'index': 1,
              'dir1': dir1,
              'dir2': <String, Object?>{
                'currentLevel': 0,
                'levels': <String, Object?>{
                  '3': <String, Object?>{'attempts': 0, 'correct': 0},
                  '2': <String, Object?>{'attempts': 0, 'correct': 0},
                  '1': <String, Object?>{'attempts': 0, 'correct': 0},
                  '0': <String, Object?>{'attempts': 0, 'correct': 0},
                },
              },
            },
          ],
        },
      };
      // currentLevel out of range.
      expect(
        () => decodeStatistics(
          withDir1(<String, Object?>{
            'currentLevel': 4,
            'levels': <String, Object?>{
              '3': <String, Object?>{'attempts': 0, 'correct': 0},
              '2': <String, Object?>{'attempts': 0, 'correct': 0},
              '1': <String, Object?>{'attempts': 0, 'correct': 0},
              '0': <String, Object?>{'attempts': 0, 'correct': 0},
            },
          }),
        ),
        throwsA(isA<ValidationException>()),
      );
      // Missing the "0" level key.
      expect(
        () => decodeStatistics(
          withDir1(<String, Object?>{
            'currentLevel': 1,
            'levels': <String, Object?>{
              '3': <String, Object?>{'attempts': 0, 'correct': 0},
              '2': <String, Object?>{'attempts': 0, 'correct': 0},
              '1': <String, Object?>{'attempts': 0, 'correct': 0},
            },
          }),
        ),
        throwsA(isA<ValidationException>()),
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
