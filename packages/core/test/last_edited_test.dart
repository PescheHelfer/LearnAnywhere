import 'dart:convert';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  /// The canonical example deck, which predates `lastEdited`.
  String exampleVok() => File('test/fixtures/example.vok').readAsStringSync();

  /// [exampleVok] with a `lastEdited` value spliced in where the encoder puts
  /// it: right after `version`, so a reader sees it at the top of the file.
  String exampleVokEditedAt(Object? value) {
    return exampleVok().replaceFirst(
      '"version": 1,\n',
      '"version": 1,\n  "lastEdited": ${jsonEncode(value)},\n',
    );
  }

  group('LocalTimestamp', () {
    test('formats local time with its UTC offset at second precision', () {
      final LocalTimestamp stamp = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      expect(stamp.toString(), '2026-09-25T16:32:11+02:00');
      // The instant is the offset-corrected one, not the wall-clock digits.
      expect(stamp.instant, DateTime.utc(2026, 9, 25, 14, 32, 11));
      expect(stamp.offset, const Duration(hours: 2));
    });

    test('keeps a negative, a zero and a part-hour offset exactly', () {
      for (final String text in <String>[
        '2026-01-02T03:04:05-05:30',
        '2026-01-02T03:04:05+00:00',
        '2026-12-31T23:59:59+05:45',
      ]) {
        expect(LocalTimestamp.tryParse(text).toString(), text);
      }
    });

    test('of() drops sub-second precision and keeps the offset of the time', () {
      final DateTime local = DateTime(2026, 9, 25, 16, 32, 11, 987, 654);
      final LocalTimestamp stamp = LocalTimestamp.of(local);
      final Duration offset = local.timeZoneOffset;
      String two(int value) => value.toString().padLeft(2, '0');
      final String sign = offset.isNegative ? '-' : '+';
      final int minutes = offset.inMinutes.abs();
      expect(
        stamp.toString(),
        '2026-09-25T16:32:11$sign${two(minutes ~/ 60)}:${two(minutes % 60)}',
      );
      expect(
        stamp.instant,
        DateTime(2026, 9, 25, 16, 32, 11).toUtc(),
      );
    });

    test('of() a UTC time records a zero offset', () {
      expect(
        LocalTimestamp.of(DateTime.utc(2026, 9, 25, 14, 32, 11)).toString(),
        '2026-09-25T14:32:11+00:00',
      );
    });

    test('refuses anything that is not exactly the stored shape', () {
      for (final String text in <String>[
        '',
        '2026-09-25',
        '2026-09-25T16:32:11',
        '2026-09-25T16:32:11Z',
        '2026-09-25T16:32:11.123+02:00',
        '2026-09-25 16:32:11+02:00',
        '2026-02-30T16:32:11+02:00',
        '2026-09-25T24:00:00+02:00',
        '2026-09-25T16:32:11+0200',
        '2026-09-25T16:32:11+02:60',
      ]) {
        expect(LocalTimestamp.tryParse(text), isNull, reason: text);
      }
    });

    test('two stamps are equal when instant and offset agree', () {
      expect(
        LocalTimestamp.tryParse('2026-09-25T16:32:11+02:00'),
        LocalTimestamp.tryParse('2026-09-25T16:32:11+02:00'),
      );
      // Same instant, different offset: a different record of it.
      expect(
        LocalTimestamp.tryParse('2026-09-25T16:32:11+02:00'),
        isNot(LocalTimestamp.tryParse('2026-09-25T14:32:11+00:00')),
      );
    });
  });

  group('.vok lastEdited', () {
    test('a deck without it decodes to "not recorded" and re-encodes without '
        'it', () {
      final LearningDeck deck = decodeDeckJson(exampleVok());
      expect(deck.lastEdited, isNull);
      expect(encodeDeckJson(deck), exampleVok());
      expect(encodeDeckJson(deck), isNot(contains('lastEdited')));
    });

    test('round-trips byte-for-byte, placed right after the version', () {
      final String source = exampleVokEditedAt('2026-09-25T16:32:11+02:00');
      final LearningDeck deck = decodeDeckJson(source);
      expect(deck.lastEdited.toString(), '2026-09-25T16:32:11+02:00');
      expect(encodeDeckJson(deck), source);
    });

    test('a malformed value reads as not recorded rather than failing the '
        'load', () {
      for (final Object? value in <Object?>[
        '25.09.2026',
        '2026-09-25T16:32:11Z',
        42,
        true,
        null,
        <String, Object?>{},
      ]) {
        final LearningDeck deck = decodeDeckJson(exampleVokEditedAt(value));
        expect(deck.lastEdited, isNull, reason: '$value');
        expect(deck.units, isNotEmpty);
      }
    });

    test('copyWith sets it and keeps the units and the mask', () {
      final LearningDeck deck = decodeDeckJson(exampleVok());
      final LocalTimestamp stamp = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck stamped = deck.copyWith(lastEdited: stamp);
      expect(stamped.lastEdited, stamp);
      expect(stamped.units, same(deck.units));
      expect(stamped.mask, same(deck.mask));
    });

    test('applying a mask to the deck keeps it: propagation is not an edit', () {
      final LearningDeck deck = decodeDeckJson(
        exampleVokEditedAt('2026-09-25T16:32:11+02:00'),
      );
      final LearningDeck propagated = applyMaskToDeck(
        deck,
        deck.mask.copyWith(revision: deck.mask.revision + 1),
      );
      expect(propagated.lastEdited, deck.lastEdited);
    });
  });
}
