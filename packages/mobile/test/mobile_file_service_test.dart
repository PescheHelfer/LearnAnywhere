import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';

// Plain test(), not testWidgets(): these exercise MobileFileService's real
// dart:io reads/writes against a temp directory standing in for the
// on-device library. flutter_test's fake-clock test binding never drives
// real async I/O, so this file deliberately avoids it.
void main() {
  late Directory library;
  late Directory scratch;
  late Directory documents;
  late MobileFileService service;

  setUp(() {
    library = Directory.systemTemp.createTempSync('la_mobile_library_');
    scratch = Directory.systemTemp.createTempSync('la_mobile_scratch_');
    documents = Directory.systemTemp.createTempSync('la_mobile_documents_');
    service = MobileFileService(
      libraryDirectory: library,
      documentsDirectory: documents,
    );
  });

  tearDown(() {
    library.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
    documents.deleteSync(recursive: true);
  });

  test('importFiles copies picked decks into the library', () async {
    final File fixture = File('${scratch.path}/sample.vok')
      ..writeAsStringSync(encodeDeckJson(_deck()));

    final int count = await service.importFiles(<fs.XFile>[
      fs.XFile(fixture.path),
    ]);

    expect(count, 1);
    expect(File('${library.path}/sample.vok').existsSync(), isTrue);
    final List<LibraryDeckEntry> entries = await service.listDecks();
    expect(entries, hasLength(1));
    expect(entries.single.name, 'Mobile sample');
    expect(entries.single.unitCount, 1);
  });

  test(
    'importFiles on a name collision replaces the deck and realigns statistics',
    () async {
      final LearningDeck original = _deck();
      File(
        '${library.path}/sample.vok',
      ).writeAsStringSync(encodeDeckJson(original));
      final List<UnitStats> recorded = <UnitStats>[
        UnitStats(
          index: 1,
          direction1: recordAttempt(
            const DirectionStats(),
            AttemptRating.correct,
          ),
        ),
      ];
      File('${library.path}/sample.sta').writeAsStringSync(
        encodeStatisticsJson(
          StatisticsFile(
            deckRef: 'sample.vok',
            perUnit: withUnitHashes(original, recorded),
          ),
        ),
      );

      final LearningDeck updated = _deck(
        extraUnits: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{
              0: PlainFieldValue('goodbye'),
              1: PlainFieldValue('au revoir'),
              2: PlainFieldValue('farewell'),
            },
          ),
        ],
      );
      final File fixture = File('${scratch.path}/sample.vok')
        ..writeAsStringSync(encodeDeckJson(updated));

      final int count = await service.importFiles(<fs.XFile>[
        fs.XFile(fixture.path),
      ]);

      expect(count, 1);
      final List<LibraryDeckEntry> entries = await service.listDecks();
      expect(entries.single.unitCount, 2);

      final StatisticsFile realigned = decodeStatisticsJson(
        File('${library.path}/sample.sta').readAsStringSync(),
      );
      // realignStatistics returns one entry per deck unit: the matched unit
      // keeps its counters, the brand-new one starts clean.
      expect(realigned.perUnit, hasLength(2));
      final UnitStats kept = realigned.perUnit[0];
      expect(kept.direction1.attempts + kept.direction2.attempts, 1);
      final UnitStats fresh = realigned.perUnit[1];
      expect(fresh.direction1.attempts + fresh.direction2.attempts, 0);
    },
  );

  test('deleteDeck removes both the deck and its sidecar', () async {
    File(
      '${library.path}/sample.vok',
    ).writeAsStringSync(encodeDeckJson(_deck()));
    File('${library.path}/sample.sta').writeAsStringSync(
      encodeStatisticsJson(
        const StatisticsFile(deckRef: 'sample.vok', perUnit: <UnitStats>[]),
      ),
    );

    await service.deleteDeck('${library.path}/sample.vok');

    expect(File('${library.path}/sample.vok').existsSync(), isFalse);
    expect(File('${library.path}/sample.sta').existsSync(), isFalse);
    expect(await service.listDecks(), isEmpty);
  });

  test('openDeck and saveStatistics round-trip through the sidecar', () async {
    final File deckFile = File('${library.path}/sample.vok')
      ..writeAsStringSync(encodeDeckJson(_deck()));

    final MobileDeckDocument opened = await service.openDeck(deckFile.path);
    expect(opened.statistics, hasLength(1));

    final List<UnitStats> updated = <UnitStats>[
      UnitStats(
        index: 1,
        direction1: recordAttempt(
          const DirectionStats(),
          AttemptRating.correct,
        ),
      ),
    ];
    await service.saveStatistics(opened, updated);

    final File sidecar = File('${library.path}/sample.sta');
    expect(sidecar.existsSync(), isTrue);
    final StatisticsFile saved = decodeStatisticsJson(
      sidecar.readAsStringSync(),
    );
    expect(saved.perUnit.single.hash, isNotNull);
    expect(saved.perUnit.single.direction1.attempts, 1);

    final MobileDeckDocument reopened = await service.openDeck(deckFile.path);
    expect(reopened.statistics.single.direction1.attempts, 1);
  });

  test('loadSettings and saveSettings round-trip, beside the library', () async {
    final LearnAnywhereSettings defaults = await service.loadSettings();
    expect(defaults.minimumAttemptsGuardEnabled, isFalse);

    const LearnAnywhereSettings guardrails = LearnAnywhereSettings(
      minimumAttemptsGuardEnabled: true,
      minAttempts: 3,
      wrongAnswerCeilingEnabled: true,
      wrongAnswerCeiling: 5,
    );
    await service.saveSettings(guardrails);

    final File settingsFile = File(await service.settingsFilePath());
    expect(settingsFile.existsSync(), isTrue);
    expect(settingsFile.parent.path, documents.path);

    final LearnAnywhereSettings reloaded = await service.loadSettings();
    expect(reloaded.minimumAttemptsGuardEnabled, isTrue);
    expect(reloaded.minAttempts, 3);
    expect(reloaded.wrongAnswerCeilingEnabled, isTrue);
    expect(reloaded.wrongAnswerCeiling, 5);
  });
}

LearningDeck _deck({List<LearningUnit> extraUnits = const <LearningUnit>[]}) {
  return LearningDeck(
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
    units: <LearningUnit>[
      const LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: PlainFieldValue('hello'),
          1: PlainFieldValue('bonjour'),
          2: PlainFieldValue('use greeting'),
        },
      ),
      ...extraUnits,
    ],
  );
}
