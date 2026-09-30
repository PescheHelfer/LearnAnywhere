import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  FieldDefinition field(int id, String name, {int length = 40}) {
    return FieldDefinition(
      id: id,
      name: name,
      length: length,
      equalGroup: 0,
      role1: id == 0 ? FieldRole.question : FieldRole.answer,
      role2: id == 0 ? FieldRole.answer : FieldRole.question,
    );
  }

  LearningMask maskAt(
    int revision, {
    String maskId = 'm_new_shared-deck',
    int answerLength = 40,
  }) {
    return LearningMask(
      maskId: maskId,
      name: 'Shared',
      direction1Label: 'Direction 1',
      direction2Label: 'Direction 2',
      revision: revision,
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 0,
          name: 'Words',
          fields: <FieldDefinition>[
            field(0, 'Question'),
            field(1, 'Answer', length: answerLength),
          ],
        ),
        CategoryDefinition(
          id: 1,
          name: 'Phrases',
          fields: <FieldDefinition>[
            field(0, 'Question'),
            field(1, 'Answer', length: answerLength),
          ],
        ),
      ],
    );
  }

  final LearningMask mask = maskAt(1);

  const DifficultFlags manualFlag = DifficultFlags(manual: true);
  const DifficultFlags autoFlag = DifficultFlags(automatic: true);
  const DifficultFlags bothFlags = DifficultFlags(
    manual: true,
    automatic: true,
  );

  LearningUnit word(
    String question,
    String answer, {
    int categoryId = 0,
    DifficultFlags d1 = DifficultFlags.none,
    DifficultFlags d2 = DifficultFlags.none,
  }) {
    return LearningUnit(
      categoryId: categoryId,
      fields: <int, FieldValue>{
        0: FieldValue.plain(question),
        1: FieldValue.plain(answer),
      },
      direction1Flags: d1,
      direction2Flags: d2,
    );
  }

  LearningDeck deck(List<LearningUnit> units, {LearningMask? on}) {
    return LearningDeck(mask: on ?? mask, units: units);
  }

  NewVersionTaken taken(LearningDeck open, LearningDeck incoming) {
    final NewVersionOutcome outcome = takeNewVersion(
      open: open,
      incoming: incoming,
    );
    expect(outcome, isA<NewVersionTaken>());
    return outcome as NewVersionTaken;
  }

  /// Each unit's flags as `question:d1/d2`, for compact assertions.
  List<String> flagsOf(LearningDeck deck) {
    String code(DifficultFlags flags) =>
        '${flags.manual ? 'M' : '-'}${flags.automatic ? 'A' : '-'}';
    String line(LearningUnit unit) =>
        '${unit.valueForFieldId(0).plainText}:'
        '${code(unit.direction1Flags)}/${code(unit.direction2Flags)}';
    return <String>[for (final LearningUnit unit in deck.units) line(unit)];
  }

  test('a flag follows a unit that only moved', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus', d1: manualFlag),
        word('tree', 'Baum'),
        word('dog', 'Hund', d2: autoFlag),
      ]),
      deck(<LearningUnit>[
        word('dog', 'Hund'),
        word('tree', 'Baum'),
        word('house', 'Haus'),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'dog:--/-A',
      'tree:--/--',
      'house:M-/--',
    ]);
    expect(result.carried, 2);
    expect(result.dropped, 0);
  });

  test('the result is the incoming content, units new in it unflagged', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[word('house', 'Haus', d1: bothFlags)]),
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('cat', 'Katze'),
      ]),
    );

    expect(flagsOf(result.deck), <String>['house:MA/--', 'cat:--/--']);
    expect(result.carried, 2, reason: 'counted in flags, not units');
  });

  test('a typo-fixed unit keeps its flags with an insert before it', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('neighbour', 'Nachbarr', d1: manualFlag, d2: autoFlag),
      ]),
      deck(<LearningUnit>[
        word('garden', 'Garten'),
        word('house', 'Haus'),
        word('neighbour', 'Nachbar'),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'garden:--/--',
      'house:--/--',
      'neighbour:M-/-A',
    ]);
    expect(result.carried, 2);
    expect(result.dropped, 0);
  });

  test('a typo-fixed unit keeps its flags with an insert at its position', () {
    // The statistics' hash-then-position rule would hand the typo's history to
    // "window", which now sits where "neighbour" used to.
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('neighbour', 'Nachbarr', d1: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('window', 'Fenster'),
        word('neighbour', 'Nachbar'),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'house:--/--',
      'window:--/--',
      'neighbour:M-/--',
    ]);
  });

  test("a removed unit's flags are dropped and counted", () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus', d1: manualFlag),
        word('dog', 'Hund', d1: bothFlags, d2: autoFlag),
      ]),
      deck(<LearningUnit>[word('house', 'Haus')]),
    );

    expect(flagsOf(result.deck), <String>['house:M-/--']);
    expect(result.carried, 1);
    expect(result.dropped, 3);
  });

  test("the incoming deck's own flags are cleared", () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('tree', 'Baum', d2: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('house', 'Haus', d1: bothFlags, d2: manualFlag),
        word('tree', 'Baum', d1: autoFlag),
        word('cat', 'Katze', d1: manualFlag),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'house:--/--',
      'tree:--/M-',
      'cat:--/--',
    ]);
    expect(result.carried, 1);
  });

  test('directions are carried independently', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('house', 'Haus', d1: manualFlag),
        word('tree', 'Baum', d2: autoFlag),
        word('dog', 'Hund', d1: autoFlag, d2: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('house', 'Haus'),
        word('tree', 'Baum'),
        word('dog', 'Hund'),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'house:M-/--',
      'tree:--/-A',
      'dog:-A/M-',
    ]);
  });

  test('identical units are matched in order, each keeping its own flags', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('bank', 'Bank', d1: manualFlag),
        word('bank', 'Bank', d2: autoFlag),
      ]),
      deck(<LearningUnit>[
        word('river', 'Fluss'),
        word('bank', 'Bank'),
        word('bank', 'Bank'),
      ]),
    );

    expect(flagsOf(result.deck), <String>[
      'river:--/--',
      'bank:M-/--',
      'bank:--/-A',
    ]);
  });

  test('different categories are never paired', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[
        word('good morning', 'guten Morgen', d1: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('good morning', 'guten Morgen', categoryId: 1),
      ]),
    );

    expect(flagsOf(result.deck), <String>['good morning:--/--']);
    expect(result.carried, 0);
    expect(result.dropped, 1);
  });

  test('pairs below the similarity threshold are not matched', () {
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[word('house', 'Haus', d1: manualFlag)]),
      deck(<LearningUnit>[word('horse', 'Pferd')]),
    );

    expect(flagsOf(result.deck), <String>['horse:--/--']);
    expect(result.dropped, 1);
  });

  test('the closest candidate wins, and a tie goes to the nearer position', () {
    final NewVersionTaken closest = taken(
      deck(<LearningUnit>[
        word('neighbour', 'Nachbarr', d1: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('neighbours', 'Nachbarn'),
        word('neighbour', 'Nachbar'),
      ]),
    );
    expect(flagsOf(closest.deck), <String>[
      'neighbours:--/--',
      'neighbour:M-/--',
    ]);

    // "Farbee" is exactly as close to "Farbe!" as to "Farbe?"; the flagged
    // unit sat at position 3, nearer to position 4 than to position 1.
    final NewVersionTaken nearer = taken(
      deck(<LearningUnit>[
        word('cat', 'Katze'),
        word('dog', 'Hund'),
        word('colour', 'Farbee', d1: manualFlag),
      ]),
      deck(<LearningUnit>[
        word('colour', 'Farbe!'),
        word('cat', 'Katze'),
        word('dog', 'Hund'),
        word('colour', 'Farbe?'),
      ]),
    );
    expect(flagsOf(nearer.deck), <String>[
      'colour:--/--',
      'cat:--/--',
      'dog:--/--',
      'colour:M-/--',
    ]);
  });

  test('a file on a different mask is refused', () {
    final NewVersionOutcome outcome = takeNewVersion(
      open: deck(<LearningUnit>[word('house', 'Haus', d1: manualFlag)]),
      incoming: deck(<LearningUnit>[
        word('house', 'Haus'),
      ], on: maskAt(1, maskId: 'm_new_another-deck')),
    );

    expect(outcome, isA<NewVersionRefused>());
    expect(
      (outcome as NewVersionRefused).reason,
      NewVersionRefusal.differentMask,
    );
  });

  test('the result is on the newer of the two mask revisions', () {
    final LearningMask newer = maskAt(3, answerLength: 60);

    final NewVersionTaken olderIncoming = taken(
      deck(<LearningUnit>[word('house', 'Haus', d1: manualFlag)], on: newer),
      deck(<LearningUnit>[word('house', 'Haus')]),
    );
    expect(olderIncoming.deck.mask.revision, 3);
    expect(flagsOf(olderIncoming.deck), <String>['house:M-/--']);

    final NewVersionTaken newerIncoming = taken(
      deck(<LearningUnit>[word('house', 'Haus', d1: manualFlag)]),
      deck(<LearningUnit>[word('house', 'Haus')], on: newer),
    );
    expect(newerIncoming.deck.mask.revision, 3);
    expect(flagsOf(newerIncoming.deck), <String>['house:M-/--']);
  });

  test('a re-key that would lose data is refused', () {
    // The open deck's newer revision shortened the answer below what the
    // older incoming file stores.
    final NewVersionOutcome outcome = takeNewVersion(
      open: deck(<LearningUnit>[
        word('house', 'Haus'),
      ], on: maskAt(2, answerLength: 4)),
      incoming: deck(<LearningUnit>[word('house', 'Hausmeister')]),
    );

    expect(outcome, isA<NewVersionRefused>());
    final NewVersionRefused refused = outcome as NewVersionRefused;
    expect(refused.reason, NewVersionRefusal.wouldLoseData);
    expect(refused.reasons.single.kind, MaskBreakingKind.fieldLengthTooShort);
  });

  test("the result keeps the incoming deck's last-edited date", () {
    final LocalTimestamp edited = LocalTimestamp.tryParse(
      '2026-09-25T16:32:11+02:00',
    )!;
    final NewVersionTaken result = taken(
      deck(<LearningUnit>[word('house', 'Haus')]),
      LearningDeck(
        mask: mask,
        units: <LearningUnit>[word('house', 'Haus')],
        lastEdited: edited,
      ),
    );

    expect(result.deck.lastEdited, edited);
  });
}
