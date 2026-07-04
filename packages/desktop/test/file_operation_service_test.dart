import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_document.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';

void main() {
  group('DesktopFileService', () {
    test('saves and opens decks with statistics sidecars', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_file_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String deckPath = '${temp.path}${Platform.pathSeparator}sample.vok';

      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final DesktopDocument document = DesktopDocument(
        deck: deck,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 1, correct: 1),
          ),
        ],
      );

      final DesktopDocument saved = await service.saveDeck(
        document,
        path: deckPath,
      );
      expect(await File(deckPath).exists(), isTrue);
      expect(
        await File(service.statisticsSidecarPath(deckPath)).exists(),
        isTrue,
      );

      final DesktopDocument opened = await service.openDeck(saved, deckPath);
      expect(opened.deck.units, hasLength(1));
      expect(opened.statistics.single.direction1.correct, 1);

      await temp.delete(recursive: true);
    });

    test('loads masks by clearing units and keeping the new schema', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_mask_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String maskPath = '${temp.path}${Platform.pathSeparator}mask.inf';
      await File(
        maskPath,
      ).writeAsString(encodeMaskJson(sampleMask(name: 'Loaded')));

      final DesktopDocument loaded = await service.loadMask(
        DesktopDocument.empty(sampleMask()),
        maskPath,
      );

      expect(loaded.mask.name, 'Loaded');
      expect(loaded.deck.units, isEmpty);

      await temp.delete(recursive: true);
    });

    test('merges decks with matching masks only', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_merge_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String incomingPath =
          '${temp.path}${Platform.pathSeparator}incoming.vok';
      final LearningDeck incoming = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(categoryId: 1, fields: <int, FieldValue>{}),
        ],
      );
      await File(incomingPath).writeAsString(encodeDeckJson(incoming));

      final DesktopDocument merged = await service.mergeDeck(
        DesktopDocument.empty(sampleMask()),
        incomingPath,
      );

      expect(merged.deck.units, hasLength(1));
      await temp.delete(recursive: true);
    });

    test('loads saves clears and exports statistics-related files', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String statsPath = '${temp.path}${Platform.pathSeparator}deck.sta';
      final String selectedPath =
          '${temp.path}${Platform.pathSeparator}selected.vok';
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final DesktopDocument document = DesktopDocument(
        deck: deck,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 3, correct: 2),
          ),
        ],
      );

      final DesktopDocument saved = await service.saveStatistics(
        document,
        statsPath,
      );
      expect(await File(statsPath).exists(), isTrue);
      expect(saved.statisticsPath, statsPath);

      final DesktopDocument cleared = service.clearStatisticsInMemory(saved);
      expect(cleared.statistics.single.direction1.attempts, 0);

      final DesktopDocument loaded = await service.loadStatistics(
        cleared,
        statsPath,
      );
      expect(loaded.statistics.single.direction1.correct, 2);

      await service.saveDeckSnapshot(deck, selectedPath);
      expect(
        decodeDeckJson(await File(selectedPath).readAsString()).units,
        hasLength(1),
      );

      await temp.delete(recursive: true);
    });

    test('loads decks matching a file mask pattern', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_pattern_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final String deckPath = '${temp.path}${Platform.pathSeparator}one.vok';
      final String ignoredPath = '${temp.path}${Platform.pathSeparator}one.txt';
      await File(deckPath).writeAsString(encodeDeckJson(deck));
      await File(ignoredPath).writeAsString('ignored');

      final Map<String, LearningDeck> loaded = await service.loadDecksByPattern(
        '${temp.path}${Platform.pathSeparator}*.vok',
      );

      expect(loaded.keys, contains(deckPath));
      expect(loaded[deckPath]!.units, hasLength(1));
      await temp.delete(recursive: true);
    });

    test('resolves the linked .inf for a deck by matching maskId', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_linked_mask',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      // A sibling .inf with the SAME maskId is the link; a decoy with a
      // different maskId in the same directory must be ignored.
      await service.saveMask(sampleMask(), '${temp.path}${sep}french.inf');
      await File(
        '${temp.path}${sep}other.inf',
      ).writeAsString(encodeMaskJson(sampleMask().copyWith(maskId: 'm_new_x')));

      final String? linked = await service.findLinkedMaskPath(
        deckPath,
        'm_new_fileop-fixture',
      );
      expect(linked, '${temp.path}${sep}french.inf');

      final String? none = await service.findLinkedMaskPath(
        deckPath,
        'm_new_absent',
      );
      expect(none, isNull);
      await temp.delete(recursive: true);
    });

    test('creates a linked .inf reusing the mask id, never minting', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_create_mask',
      );
      final DesktopFileService service = const DesktopFileService();
      final String deckPath =
          '${temp.path}${Platform.pathSeparator}french.vok';

      final LearningMask embedded = sampleMask();
      final String infPath = await service.createLinkedMask(deckPath, embedded);

      expect(infPath, endsWith('french.inf'));
      final LearningMask reloaded = await service.readMask(infPath);
      // The created file REUSES the embedded maskId (identity is preserved).
      expect(reloaded.maskId, embedded.maskId);
      // And it is now resolvable as the deck's link.
      expect(
        await service.findLinkedMaskPath(deckPath, embedded.maskId),
        infPath,
      );
      await temp.delete(recursive: true);
    });

    test('plans and applies tier-1 propagation to sibling decks', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_propagation',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String okPath = '${temp.path}${sep}short.vok';
      final String breakPath = '${temp.path}${sep}long.vok';

      // Two decks share the fixture maskId. "short" holds a 1-char value;
      // "long" holds a 6-char value in field id 0.
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: sampleMask(),
          units: const <LearningUnit>[
            LearningUnit(categoryId: 1, fields: <int, FieldValue>{0: FieldValue.plain('Q')}),
          ],
        ),
        okPath,
      );
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: sampleMask(),
          units: const <LearningUnit>[
            LearningUnit(
              categoryId: 1,
              fields: <int, FieldValue>{0: FieldValue.plain('sixchr')},
            ),
          ],
        ),
        breakPath,
      );

      // New mask shrinks field id 0 from 40 to 3: "short" is fine, "long" breaks.
      final LearningMask shrunk = _withFirstFieldLength(sampleMask(), 3);
      final MaskPropagationPlan plan = await service.planMaskPropagation(
        maskDirectory: temp.path,
        newMask: shrunk,
      );
      expect(plan.compatible, <String>[okPath]);
      expect(plan.breaking, hasLength(1));
      expect(plan.breaking.single.deckPath, breakPath);

      // Auto-apply to the compatible deck only.
      await service.applyMaskPropagation(
        newMask: shrunk,
        deckPaths: plan.compatible,
      );
      final LearningDeck updatedOk = decodeDeckJson(
        await File(okPath).readAsString(),
      );
      expect(updatedOk.mask.categories.single.fields.single.length, 3);
      expect(updatedOk.units.single.valueForFieldId(0).plainText, 'Q');
      // The breaking deck was left untouched (still length 40).
      final LearningDeck untouched = decodeDeckJson(
        await File(breakPath).readAsString(),
      );
      expect(untouched.mask.categories.single.fields.single.length, 40);

      // Forcing applies to the breaking deck too, truncating its data.
      await service.applyMaskPropagation(
        newMask: shrunk,
        deckPaths: <String>[breakPath],
      );
      final LearningDeck forced = decodeDeckJson(
        await File(breakPath).readAsString(),
      );
      expect(forced.mask.categories.single.fields.single.length, 3);
      expect(forced.units.single.valueForFieldId(0).plainText, 'six');
      await temp.delete(recursive: true);
    });
  });
}

LearningMask _withFirstFieldLength(LearningMask mask, int length) {
  final CategoryDefinition category = mask.categories.single;
  final FieldDefinition field = category.fields.single;
  return mask.copyWith(
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: category.id,
        name: category.name,
        fields: <FieldDefinition>[
          FieldDefinition(
            id: field.id,
            name: field.name,
            length: length,
            equalGroup: field.equalGroup,
            role1: field.role1,
            role2: field.role2,
          ),
        ],
      ),
    ],
  );
}

LearningMask sampleMask({String name = 'Sample'}) {
  return LearningMask(
    maskId: 'm_new_fileop-fixture',
    name: name,
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: const <CategoryDefinition>[
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
  );
}
