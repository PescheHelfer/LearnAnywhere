import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  /// The canonical example deck, which predates the difficulty flags.
  String exampleVok() => File('test/fixtures/example.vok').readAsStringSync();

  const LearningMask mask = LearningMask(
    maskId: 'm_new_difficult-units',
    name: 'Sample',
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
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
  );

  LearningUnit unit({bool manual = false, bool automatic = false}) {
    return LearningUnit(
      categoryId: 0,
      fields: const <int, FieldValue>{
        0: FieldValue.plain('house'),
        1: FieldValue.plain('Haus'),
      },
      manualDifficult: manual,
      autoDifficult: automatic,
    );
  }

  group('.vok difficulty flags', () {
    test('a deck without them decodes to unflagged units and re-encodes '
        'byte-for-byte', () {
      final LearningDeck deck = decodeDeckJson(exampleVok());
      for (final LearningUnit unit in deck.units) {
        expect(unit.manualDifficult, isFalse);
        expect(unit.autoDifficult, isFalse);
        expect(unit.isDifficult, isFalse);
      }
      expect(encodeDeckJson(deck), exampleVok());
      expect(encodeDeckJson(deck), isNot(contains('Difficult')));
    });

    test('each flag round-trips, and only a true flag is written', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(),
          unit(manual: true),
          unit(automatic: true),
          unit(manual: true, automatic: true),
        ],
      );
      final String json = encodeDeckJson(deck);
      expect('"manualDifficult": true'.allMatches(json).length, 2);
      expect('"autoDifficult": true'.allMatches(json).length, 2);
      expect(json, isNot(contains('false')));

      final LearningDeck decoded = decodeDeckJson(json);
      expect(
        <(bool, bool)>[
          for (final LearningUnit unit in decoded.units)
            (unit.manualDifficult, unit.autoDifficult),
        ],
        <(bool, bool)>[
          (false, false),
          (true, false),
          (false, true),
          (true, true),
        ],
      );
      expect(encodeDeckJson(decoded), json);
    });

    test('a value that is not a boolean reads as unflagged rather than '
        'failing the load', () {
      for (final Object? value in <Object?>['true', 1, null, <Object?>[]]) {
        final String source = exampleVok().replaceFirst(
          '"categoryId": ',
          '"manualDifficult": ${value is String ? '"$value"' : value},\n'
              '      "categoryId": ',
        );
        final LearningDeck deck = decodeDeckJson(source);
        expect(deck.units.first.manualDifficult, isFalse, reason: '$value');
      }
    });

    test('the identity hash is blind to both flags, so flagging never resets '
        'statistics', () {
      final String plain = unitIdentityHash(mask, unit());
      expect(unitIdentityHash(mask, unit(manual: true)), plain);
      expect(unitIdentityHash(mask, unit(automatic: true)), plain);
      expect(unitIdentityHash(mask, unit(manual: true, automatic: true)), plain);
    });

    test('applying a mask keeps both flags', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(manual: true), unit(automatic: true)],
      );
      final LearningDeck propagated = applyMaskToDeck(
        deck,
        mask.copyWith(revision: mask.revision + 1),
      );
      expect(propagated.units[0].manualDifficult, isTrue);
      expect(propagated.units[1].autoDifficult, isTrue);
    });
  });

  group('toggleDifficult', () {
    test('an unflagged unit gains the manual flag', () {
      final LearningUnit toggled = toggleDifficult(unit());
      expect(toggled.manualDifficult, isTrue);
      expect(toggled.autoDifficult, isFalse);
    });

    test('a manually flagged unit loses its flag', () {
      final LearningUnit toggled = toggleDifficult(unit(manual: true));
      expect(toggled.isDifficult, isFalse);
    });

    test('an automatically flagged unit loses its flag: "not difficult" means '
        'not difficult', () {
      final LearningUnit toggled = toggleDifficult(unit(automatic: true));
      expect(toggled.manualDifficult, isFalse);
      expect(toggled.autoDifficult, isFalse);
    });

    test('a unit carrying both flags loses both', () {
      final LearningUnit toggled = toggleDifficult(
        unit(manual: true, automatic: true),
      );
      expect(toggled.manualDifficult, isFalse);
      expect(toggled.autoDifficult, isFalse);
    });

    test('the unit content is untouched', () {
      final LearningUnit before = unit();
      final LearningUnit toggled = toggleDifficult(before);
      expect(toggled.categoryId, before.categoryId);
      expect(toggled.fields, same(before.fields));
    });

    test('on a deck it changes only the unit at the one-based index and keeps '
        'the last-edited date', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(), unit(), unit(automatic: true)],
        lastEdited: edited,
      );
      final LearningDeck toggled = toggleDifficultAt(deck, 2);
      expect(
        <bool>[for (final LearningUnit u in toggled.units) u.isDifficult],
        <bool>[false, true, true],
      );
      expect(toggled.units[1].manualDifficult, isTrue);
      expect(toggled.lastEdited, edited);
      expect(toggled.mask, same(deck.mask));
    });
  });
}
