import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('unitLearningSeconds', () {
    test('the cap is five minutes', () {
      expect(kUnitLearningSecondsCap, 300);
    });

    test('passes a unit time below the cap through unchanged', () {
      expect(unitLearningSeconds(0), 0);
      expect(unitLearningSeconds(42), 42);
      expect(unitLearningSeconds(299), 299);
    });

    test('counts a unit time at or beyond the cap as the cap', () {
      expect(unitLearningSeconds(300), 300);
      expect(unitLearningSeconds(360), 300);
      expect(unitLearningSeconds(3 * 60 * 60), 300);
    });
  });

  group('learning time in a .sta', () {
    test('round-trips in the working and the all-time scope', () {
      for (final StatisticsScope scope in StatisticsScope.values) {
        final StatisticsFile file = StatisticsFile(
          deckRef: 'french.vok',
          scope: scope,
          perUnit: const <UnitStats>[UnitStats(index: 1)],
          learningSeconds: 4321,
        );
        final Map<String, Object?> json = encodeStatistics(file);
        expect(json['learningSeconds'], 4321, reason: scope.name);
        // Additive, like the scope marker: the version does not move.
        expect(json['version'], currentStatisticsVersion);
        expect(
          decodeStatisticsJson(encodeStatisticsJson(file)).learningSeconds,
          4321,
          reason: scope.name,
        );
      }
    });

    test('a record holding no time writes no key, so it encodes exactly as '
        'before', () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
      );
      expect(file.learningSeconds, 0);
      expect(encodeStatistics(file).containsKey('learningSeconds'), isFalse);
    });

    test('a file without the key decodes as no time, not as an error', () {
      final Map<String, Object?> legacy = <String, Object?>{
        'format': statisticsFormat,
        'version': 1,
        'deckRef': 'french.vok',
        'perUnit': <Object?>[],
      };
      expect(decodeStatistics(legacy).learningSeconds, 0);
    });

    test('a value that is not a whole number of seconds reads as no time', () {
      for (final Object? value in <Object?>['12', -5, 1.5, null]) {
        final Map<String, Object?> json = encodeStatistics(
          const StatisticsFile(deckRef: 'french.vok', perUnit: <UnitStats>[]),
        )..['learningSeconds'] = value;
        expect(decodeStatistics(json).learningSeconds, 0, reason: '$value');
      }
    });

    test('a key from a later build is still ignored beside it', () {
      final Map<String, Object?> json = encodeStatistics(
        const StatisticsFile(
          deckRef: 'french.vok',
          perUnit: <UnitStats>[],
          learningSeconds: 90,
        ),
      )..['somethingNew'] = <String, Object?>{'a': 1};
      expect(decodeStatistics(json).learningSeconds, 90);
    });
  });

  group('RecordedAttempt learning time', () {
    test('a No count answer carries its time although no counter moved', () {
      const RecordedAttempt attempt = RecordedAttempt(
        unitIndex: 1,
        direction: QueryDirection.direction1,
        learningSeconds: 20,
      );
      expect(attempt.learningSeconds, 20);
      expect(attempt.isEmpty, isTrue);
    });

    test('carries no time unless given some', () {
      const RecordedAttempt attempt = RecordedAttempt(
        unitIndex: 1,
        direction: QueryDirection.direction1,
      );
      expect(attempt.learningSeconds, 0);
    });
  });
}
