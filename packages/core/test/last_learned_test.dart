import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('lastLearned', () {
    test('returns null for a deck with no statistics files', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          lastLearned(
            deckPath: ctx == p.windows
                ? r'C:\decks\french.vok'
                : '/decks/french.vok',
            statisticsFileNames: const <String>[],
            timeOf: (String _) => null,
            context: ctx,
          ),
          isNull,
        );
      }
    });

    test('returns the one file\'s time when only one exists', () {
      final DateTime when = DateTime(2026, 7, 26, 9, 5, 3);
      expect(
        lastLearned(
          deckPath: '/decks/french.vok',
          statisticsFileNames: const <String>['french.sta'],
          timeOf: (String name) => name == 'french.sta' ? when : null,
          context: p.posix,
        ),
        when,
      );
    });

    test('picks the newest among several of the deck\'s statistics files', () {
      final DateTime sidecarTime = DateTime(2026, 1, 1);
      final DateTime sessionTime = DateTime(2026, 6, 15, 8);
      final DateTime allTimeTime = DateTime(2026, 9, 1);
      final Map<String, DateTime> times = <String, DateTime>{
        'french.sta': sidecarTime,
        'french_20260615_080000.sta': sessionTime,
        'french_alltime.sta': allTimeTime,
      };
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        final String deckPath = ctx == p.windows
            ? r'C:\decks\french.vok'
            : '/decks/french.vok';
        expect(
          lastLearned(
            deckPath: deckPath,
            statisticsFileNames: times.keys,
            timeOf: (String name) => times[name],
            context: ctx,
          ),
          allTimeTime,
        );
      }
    });

    test('ignores a neighbouring deck\'s files with a similar name', () {
      final DateTime frenchTime = DateTime(2026, 1, 1);
      final DateTime french2Time = DateTime(2026, 9, 1);
      final Map<String, DateTime> times = <String, DateTime>{
        'french.sta': frenchTime,
        'french2.sta': french2Time,
        'french2_alltime.sta': french2Time,
        'french2_20260901_000000.sta': french2Time,
      };
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        final String deckPath = ctx == p.windows
            ? r'C:\decks\french.vok'
            : '/decks/french.vok';
        expect(
          lastLearned(
            deckPath: deckPath,
            statisticsFileNames: times.keys,
            timeOf: (String name) => times[name],
            context: ctx,
          ),
          frenchTime,
        );
      }
    });

    test('skips a file it recognises but whose time could not be read', () {
      final DateTime sidecarTime = DateTime(2026, 1, 1);
      expect(
        lastLearned(
          deckPath: r'C:\decks\french.vok',
          statisticsFileNames: const <String>[
            'french.sta',
            'french_alltime.sta',
          ],
          timeOf: (String name) =>
              name == 'french.sta' ? sidecarTime : null,
          context: p.windows,
        ),
        sidecarTime,
      );
    });
  });

  group('DeckPaths.isStatisticsFileFor', () {
    test('recognises the sidecar, session, and all-time names', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        final String deckPath = ctx == p.windows
            ? r'C:\decks\french.vok'
            : '/decks/french.vok';
        expect(
          DeckPaths.isStatisticsFileFor(deckPath, 'french.sta', context: ctx),
          isTrue,
        );
        expect(
          DeckPaths.isStatisticsFileFor(
            deckPath,
            'french_20260726_090503.sta',
            context: ctx,
          ),
          isTrue,
        );
        expect(
          DeckPaths.isStatisticsFileFor(
            deckPath,
            'french_alltime.sta',
            context: ctx,
          ),
          isTrue,
        );
      }
    });

    test('is case-insensitive for the sidecar and all-time names', () {
      expect(
        DeckPaths.isStatisticsFileFor(
          '/decks/french.vok',
          'FRENCH.STA',
          context: p.posix,
        ),
        isTrue,
      );
      expect(
        DeckPaths.isStatisticsFileFor(
          '/decks/french.vok',
          'French_AllTime.sta',
          context: p.posix,
        ),
        isTrue,
      );
    });

    test('rejects a neighbouring deck\'s similarly named files', () {
      const String deckPath = '/decks/french.vok';
      expect(
        DeckPaths.isStatisticsFileFor(deckPath, 'french2.sta', context: p.posix),
        isFalse,
      );
      expect(
        DeckPaths.isStatisticsFileFor(
          deckPath,
          'french2_alltime.sta',
          context: p.posix,
        ),
        isFalse,
      );
      expect(
        DeckPaths.isStatisticsFileFor(
          deckPath,
          'french2_20260726_090503.sta',
          context: p.posix,
        ),
        isFalse,
      );
    });

    test('rejects an unrelated file', () {
      expect(
        DeckPaths.isStatisticsFileFor(
          '/decks/french.vok',
          'french.inf',
          context: p.posix,
        ),
        isFalse,
      );
    });
  });
}
