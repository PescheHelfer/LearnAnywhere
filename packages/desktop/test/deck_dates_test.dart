import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_document.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';
import 'package:path/path.dart' as p;

/// What a deck file on disk says about its last edit.
LocalTimestamp? lastEditedOnDisk(String path) {
  return decodeDeckJson(File(path).readAsStringSync()).lastEdited;
}

void main() {
  const DesktopFileService service = DesktopFileService();
  final LocalTimestamp earlier = LocalTimestamp.tryParse(
    '2026-01-02T03:04:05+01:00',
  )!;
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('la_deck_dates');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  String inTemp(String name) => p.join(temp.path, name);

  /// [name] in the statistics folder beside the decks, which is created.
  String inStatistics(String name) {
    final Directory folder = Directory(p.join(temp.path, 'statistics'))
      ..createSync(recursive: true);
    return p.join(folder.path, name);
  }

  /// Writes [deck] to [name] in the temp folder and opens it, as File ▸ Load
  /// deck would.
  Future<DesktopDocument> openWritten(String name, LearningDeck deck) async {
    final String path = inTemp(name);
    File(path).writeAsStringSync(encodeDeckJson(deck));
    return service.openDeck(DesktopDocument.empty(deck.mask), path);
  }

  group('last edited', () {
    test('saving after a unit edit records the save time with the local '
        'offset', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']).copyWith(lastEdited: earlier),
      );
      final DesktopDocument edited = opened.copyWith(
        deck: _deck(<String>['one', 'two']).copyWith(lastEdited: earlier),
        unitsEdited: true,
      );

      final DateTime before = DateTime.now();
      final DesktopDocument saved = (await service.saveDeck(edited)).document;
      final DateTime after = DateTime.now();

      final LocalTimestamp written = lastEditedOnDisk(opened.deckPath!)!;
      expect(
        written.instant.isBefore(
          before.toUtc().subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(written.instant.isAfter(after.toUtc()), isFalse);
      expect(written.offset, after.timeZoneOffset);
      // The document now holds what the file holds, and has nothing pending.
      expect(saved.deck.lastEdited, written);
      expect(saved.unitsEdited, isFalse);
    });

    test('a save that changes no unit leaves the date as it was', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']).copyWith(lastEdited: earlier),
      );

      await service.saveDeck(opened);
      expect(lastEditedOnDisk(opened.deckPath!), earlier);

      // Nor does save-as: the copy's units are the same units.
      final String copy = inTemp('copy.vok');
      await service.saveDeck(opened, path: copy);
      expect(lastEditedOnDisk(copy), earlier);
    });

    test('an undated deck first saved without an edit keeps its file time as '
        'the date', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']),
      );
      final DateTime modified = DateTime(2025, 6, 7, 8, 9, 10);
      File(opened.deckPath!).setLastModifiedSync(modified);

      final DesktopDocument saved = await service.writeDeck(
        opened.copyWith(
          deck: opened.deck.copyWith(
            units: <LearningUnit>[
              opened.deck.units.single.copyWith(
                direction1Flags: const DifficultFlags(manual: true),
              ),
            ],
          ),
        ),
        opened.deckPath!,
      );

      expect(lastEditedOnDisk(opened.deckPath!), LocalTimestamp.of(modified));
      expect(saved.deck.lastEdited, LocalTimestamp.of(modified));

      // Later writes keep it: the file's time is now the write's own.
      await service.writeDeck(saved, opened.deckPath!);
      expect(lastEditedOnDisk(opened.deckPath!), LocalTimestamp.of(modified));
    });

    test('an undated deck whose file already carries a flag stays undated',
        () async {
      for (final String key in <String>[
        'manualDifficult1',
        'autoDifficult2',
        'manualDifficult',
        'autoDifficult',
      ]) {
        final String path = inTemp('$key.vok');
        final Map<String, Object?> json =
            jsonDecode(encodeDeckJson(_deck(<String>['one'])))
                as Map<String, Object?>;
        ((json['units']! as List<Object?>).single! as Map<String, Object?>)[key] =
            true;
        File(path)
          ..writeAsStringSync(jsonEncode(json))
          ..setLastModifiedSync(DateTime(2025, 6, 7, 8, 9, 10));
        final DesktopDocument opened = await service.openDeck(
          DesktopDocument.empty(_mask()),
          path,
        );

        await service.writeDeck(opened, path);
        expect(lastEditedOnDisk(path), isNull, reason: key);
      }
    });

    test('a write to a path with no file yet seeds nothing', () async {
      final DesktopDocument unsaved = DesktopDocument.empty(_mask()).copyWith(
        deck: _deck(<String>['one']),
      );
      final String path = inTemp('new.vok');
      await service.writeDeck(unsaved, path);
      expect(lastEditedOnDisk(path), isNull);
    });

    test('a content write dates the deck now, not by its file time', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']),
      );
      File(opened.deckPath!).setLastModifiedSync(DateTime(2025, 6, 7, 8, 9, 10));

      final DateTime before = DateTime.now();
      await service.writeDeck(
        opened.copyWith(unitsEdited: true),
        opened.deckPath!,
      );
      expect(
        lastEditedOnDisk(opened.deckPath!)!.instant.isBefore(
          before.toUtc().subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('mask propagation and sync seed an undated, unflagged deck from its '
        'file time and leave a flagged one undated', () async {
      final DateTime modified = DateTime(2025, 6, 7, 8, 9, 10);
      final String plain = inTemp('plain.vok');
      final String flagged = inTemp('flagged.vok');
      File(plain)
        ..writeAsStringSync(encodeDeckJson(_deck(<String>['one'])))
        ..setLastModifiedSync(modified);
      File(flagged)
        ..writeAsStringSync(
          encodeDeckJson(
            LearningDeck(
              mask: _mask(),
              units: <LearningUnit>[
                LearningUnit(
                  categoryId: 1,
                  fields: <int, FieldValue>{0: FieldValue.plain('one')},
                  direction2Flags: const DifficultFlags(automatic: true),
                ),
              ],
            ),
          ),
        )
        ..setLastModifiedSync(modified);

      await service.applyMaskPropagation(
        newMask: _mask().copyWith(revision: 7),
        deckPaths: <String>[plain, flagged],
      );
      expect(lastEditedOnDisk(plain), LocalTimestamp.of(modified));
      expect(lastEditedOnDisk(flagged), isNull);

      final String viaSync = inTemp('sync.vok');
      File(viaSync)
        ..writeAsStringSync(encodeDeckJson(_deck(<String>['one'])))
        ..setLastModifiedSync(modified);
      await service.applyMaskSync(
        reference: _mask().copyWith(revision: 8),
        paths: <String>[viaSync],
      );
      expect(lastEditedOnDisk(viaSync), LocalTimestamp.of(modified));
    });

    test('opening a deck starts with no pending unit edit', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']),
      );
      expect(opened.unitsEdited, isFalse);
    });

    test('merging in another deck is a unit edit', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']).copyWith(lastEdited: earlier),
      );
      final String other = inTemp('other.vok');
      File(other).writeAsStringSync(encodeDeckJson(_deck(<String>['two'])));

      final DesktopDocument merged = await service.mergeDeck(opened, other);
      expect(merged.unitsEdited, isTrue);

      await service.saveDeck(merged);
      expect(lastEditedOnDisk(opened.deckPath!), isNot(earlier));
    });

    test('writing the open deck back after a mask change keeps the date, but '
        'still stamps unit edits that were pending', () async {
      final DesktopDocument opened = await openWritten(
        'deck.vok',
        _deck(<String>['one']).copyWith(lastEdited: earlier),
      );
      final LearningMask revised = opened.mask.copyWith(
        revision: opened.mask.revision + 1,
      );

      final DesktopDocument written = await service.writeDeck(
        opened.copyWith(deck: applyMaskToDeck(opened.deck, revised)),
        opened.deckPath!,
      );
      expect(lastEditedOnDisk(opened.deckPath!), earlier);
      expect(written.deck.mask.revision, revised.revision);

      // The write is whole-file, so an edit made before it lands with it —
      // and is dated like any other.
      final DesktopDocument afterEdit = await service.writeDeck(
        written.copyWith(
          deck: applyMaskToDeck(_deck(<String>['changed']), revised),
          unitsEdited: true,
        ),
        opened.deckPath!,
      );
      expect(lastEditedOnDisk(opened.deckPath!), isNot(earlier));
      expect(afterEdit.unitsEdited, isFalse);
    });

    test('propagating a mask to sibling decks leaves their dates alone',
        () async {
      final String sibling = inTemp('sibling.vok');
      File(sibling).writeAsStringSync(
        encodeDeckJson(_deck(<String>['one']).copyWith(lastEdited: earlier)),
      );
      final LearningMask revised = _mask().copyWith(revision: 7);

      await service.applyMaskPropagation(
        newMask: revised,
        deckPaths: <String>[sibling],
      );

      expect(
        decodeDeckJson(File(sibling).readAsStringSync()).mask.revision,
        7,
      );
      expect(lastEditedOnDisk(sibling), earlier);
    });
  });

  group('deckDates', () {
    test('reads last edited from the deck and last learned from the newest '
        'of its files in the statistics folder', () async {
      final String deck = inTemp('Foo.vok');
      File(deck).writeAsStringSync(
        encodeDeckJson(_deck(<String>['one']).copyWith(lastEdited: earlier)),
      );
      final DateTime sidecar = DateTime(2026, 3, 1, 10);
      final DateTime session = DateTime(2026, 5, 1, 10);
      final DateTime allTime = DateTime(2026, 4, 1, 10);
      File(inStatistics('Foo.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(sidecar);
      File(inStatistics('Foo_20260501_100000.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(session);
      File(inStatistics('Foo_alltime.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(allTime);
      // A neighbouring deck's newer file must not count for this one.
      File(inStatistics('Foo2.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(DateTime(2026, 9, 1, 10));
      // Nor does this deck's own file left beside it: only the statistics
      // folder is read.
      File(inTemp('Foo_20260801_100000.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(DateTime(2026, 8, 1, 10));

      final DeckDates dates = await service.deckDates(deck);
      expect(dates.lastEdited, earlier);
      expect(dates.lastLearned, session);
    });

    test('a deck with neither reads as not recorded and not learned', () async {
      final String deck = inTemp('Foo.vok');
      File(deck).writeAsStringSync(encodeDeckJson(_deck(<String>['one'])));

      final DeckDates dates = await service.deckDates(deck);
      expect(dates.lastEdited, isNull);
      expect(dates.lastLearned, isNull);
    });

    test('a deck that will not decode still reports when it was learned',
        () async {
      final String deck = inTemp('Foo.vok');
      File(deck).writeAsStringSync('not json');
      final DateTime learned = DateTime(2026, 3, 1, 10);
      File(inStatistics('Foo_alltime.sta'))
        ..writeAsStringSync('{}')
        ..setLastModifiedSync(learned);

      final DeckDates dates = await service.deckDates(deck);
      expect(dates.lastEdited, isNull);
      expect(dates.lastLearned, learned);
    });

    test('a deck that is gone reports nothing rather than failing', () async {
      final DeckDates dates = await service.deckDates(
        p.join(temp.path, 'missing', 'Foo.vok'),
      );
      expect(dates.lastEdited, isNull);
      expect(dates.lastLearned, isNull);
    });
  });
}

LearningDeck _deck(List<String> terms) {
  return LearningDeck(
    mask: _mask(),
    units: <LearningUnit>[
      for (final String term in terms)
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{0: FieldValue.plain(term)},
        ),
    ],
  );
}

LearningMask _mask() {
  return const LearningMask(
    maskId: 'm_new_deck-dates-fixture',
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
        ],
      ),
    ],
  );
}
