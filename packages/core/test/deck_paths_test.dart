import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Every case is asserted against BOTH an explicit Windows context and an
/// explicit POSIX context, so the expectations are identical no matter which
/// host runs the suite. That is the point of these tests: the sidecar
/// derivation used to depend on `Platform.pathSeparator`, which made it
/// untestable for the other platform and silently wrong for POSIX paths that
/// contain a backslash.
void main() {
  group('DeckPaths.statisticsSidecar', () {
    test('replaces the deck extension, keeping the directory', () {
      expect(
        DeckPaths.statisticsSidecar(
          r'C:\decks\french.vok',
          context: p.windows,
        ),
        r'C:\decks\french.sta',
      );
      expect(
        DeckPaths.statisticsSidecar(
          '/home/pesche/decks/french.vok',
          context: p.posix,
        ),
        '/home/pesche/decks/french.sta',
      );
    });

    test('handles a bare file name with no directory part', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          DeckPaths.statisticsSidecar('french.vok', context: ctx),
          'french.sta',
        );
      }
    });

    test('appends an extension when the deck name has none', () {
      expect(
        DeckPaths.statisticsSidecar(r'C:\decks\french', context: p.windows),
        r'C:\decks\french.sta',
      );
      expect(
        DeckPaths.statisticsSidecar('/decks/french', context: p.posix),
        '/decks/french.sta',
      );
    });

    test('only the final extension is replaced', () {
      expect(
        DeckPaths.statisticsSidecar(
          '/decks/french.v2.vok',
          context: p.posix,
        ),
        '/decks/french.v2.sta',
      );
    });

    test('a dot in a DIRECTORY name is never mistaken for the extension', () {
      // The old lastIndexOf('.') logic had to special-case this; `package:path`
      // only ever looks inside the last segment.
      expect(
        DeckPaths.statisticsSidecar(
          r'C:\my.decks\french',
          context: p.windows,
        ),
        r'C:\my.decks\french.sta',
      );
      expect(
        DeckPaths.statisticsSidecar('/my.decks/french', context: p.posix),
        '/my.decks/french.sta',
      );
    });

    test('stays beside the deck, never in the statistics folder: it is '
        'Android\'s live file', () {
      expect(
        DeckPaths.statisticsSidecar(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks\french.sta',
      );
      expect(
        DeckPaths.statisticsSidecar('/decks/french.vok', context: p.posix),
        '/decks/french.sta',
      );
    });

    test('a backslash is a NAME character under POSIX but a separator on '
        'Windows', () {
      // The single most likely Linux-only defect in the old code: it treated
      // '\' as a separator on every platform in some helpers.
      expect(
        DeckPaths.statisticsSidecar(r'/decks/back\slash.vok', context: p.posix),
        r'/decks/back\slash.sta',
      );
      expect(
        DeckPaths.statisticsSidecar(r'C:/decks/french.vok', context: p.windows),
        r'C:/decks/french.sta',
      );
    });
  });

  group('DeckPaths.statisticsFolder', () {
    test('is the lower-case statistics subfolder beside the deck', () {
      expect(
        DeckPaths.statisticsFolder(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks\statistics',
      );
      expect(
        DeckPaths.statisticsFolder(
          '/home/pesche/decks/french.vok',
          context: p.posix,
        ),
        '/home/pesche/decks/statistics',
      );
    });

    test('a bare deck name gets a relative statistics folder', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          DeckPaths.statisticsFolder('french.vok', context: ctx),
          'statistics',
        );
      }
    });

    test('a POSIX backslash stays part of the folder name', () {
      expect(
        DeckPaths.statisticsFolder(r'/de\cks/french.vok', context: p.posix),
        r'/de\cks/statistics',
      );
    });
  });

  group('DeckPaths.timestampedStatistics', () {
    final DateTime when = DateTime(2026, 7, 26, 9, 5, 3);

    test('names the session file <deck>_YYYYMMDD_HHMMSS.sta in the '
        'statistics folder', () {
      expect(
        DeckPaths.timestampedStatistics(
          r'C:\decks\french.vok',
          when,
          context: p.windows,
        ),
        r'C:\decks\statistics\french_20260726_090503.sta',
      );
      expect(
        DeckPaths.timestampedStatistics(
          '/home/pesche/decks/french.vok',
          when,
          context: p.posix,
        ),
        '/home/pesche/decks/statistics/french_20260726_090503.sta',
      );
    });

    test('a bare deck name gets a relative statistics folder', () {
      expect(
        DeckPaths.timestampedStatistics('french.vok', when, context: p.windows),
        r'statistics\french_20260726_090503.sta',
      );
      expect(
        DeckPaths.timestampedStatistics('french.vok', when, context: p.posix),
        'statistics/french_20260726_090503.sta',
      );
    });

    test('a deck name with pattern metacharacters is kept literally', () {
      expect(
        DeckPaths.timestampedStatistics(
          r'C:\decks\a+b (1).vok',
          when,
          context: p.windows,
        ),
        r'C:\decks\statistics\a+b (1)_20260726_090503.sta',
      );
      expect(
        DeckPaths.timestampedStatistics(
          '/decks/a+b (1).vok',
          when,
          context: p.posix,
        ),
        '/decks/statistics/a+b (1)_20260726_090503.sta',
      );
    });

    test('zero-pads every stamp component', () {
      expect(
        DeckPaths.formatStamp(DateTime(2026, 1, 2, 3, 4, 5)),
        '20260102_030405',
      );
    });
  });

  group('DeckPaths.allTimeStatistics', () {
    test('names the lifetime file <deck>_alltime.sta in the statistics '
        'folder', () {
      expect(
        DeckPaths.allTimeStatistics(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks\statistics\french_alltime.sta',
      );
      expect(
        DeckPaths.allTimeStatistics(
          '/home/pesche/decks/french.vok',
          context: p.posix,
        ),
        '/home/pesche/decks/statistics/french_alltime.sta',
      );
    });

    test('a bare deck name gets a relative statistics folder', () {
      expect(
        DeckPaths.allTimeStatistics('french.vok', context: p.windows),
        r'statistics\french_alltime.sta',
      );
      expect(
        DeckPaths.allTimeStatistics('french.vok', context: p.posix),
        'statistics/french_alltime.sta',
      );
    });

    test('a deck name with pattern metacharacters is kept literally', () {
      expect(
        DeckPaths.allTimeStatistics(r'C:\decks\a+b (1).vok', context: p.windows),
        r'C:\decks\statistics\a+b (1)_alltime.sta',
      );
      expect(
        DeckPaths.allTimeStatistics('/decks/a+b (1).vok', context: p.posix),
        '/decks/statistics/a+b (1)_alltime.sta',
      );
    });

    test('is distinct from the bare sidecar name', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          DeckPaths.allTimeStatistics('french.vok', context: ctx),
          isNot(DeckPaths.statisticsSidecar('french.vok', context: ctx)),
        );
      }
    });

    test('can NEVER be matched by the pattern that auto-loads the most recent '
        'session file', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        final String deckPath = ctx == p.windows
            ? r'C:\decks\french.vok'
            : '/decks/french.vok';
        final RegExp pattern = DeckPaths.timestampedStatisticsPattern(
          deckPath,
          context: ctx,
        );
        expect(
          pattern.hasMatch(
            DeckPaths.fileName(
              DeckPaths.allTimeStatistics(deckPath, context: ctx),
              context: ctx,
            ),
          ),
          isFalse,
        );
      }
    });

    test('a deck literally named <name>_alltime still gets its own lifetime '
        'file, never the same path twice', () {
      expect(
        DeckPaths.allTimeStatistics('french_alltime.vok', context: p.posix),
        'statistics/french_alltime_alltime.sta',
      );
    });
  });

  group('DeckPaths.timestampedStatisticsPattern', () {
    test('matches this deck\'s session files and captures the stamp', () {
      final RegExp pattern = DeckPaths.timestampedStatisticsPattern(
        '/decks/french.vok',
        context: p.posix,
      );
      final RegExpMatch? match = pattern.firstMatch(
        'french_20260726_090503.sta',
      );
      expect(match, isNotNull);
      expect(
        <String?>[
          match!.group(1),
          match.group(2),
          match.group(3),
          match.group(4),
          match.group(5),
          match.group(6),
        ],
        <String>['2026', '07', '26', '09', '05', '03'],
      );
    });

    test('rejects a plain <deck>.sta and another deck\'s session file', () {
      final RegExp pattern = DeckPaths.timestampedStatisticsPattern(
        r'C:\decks\french.vok',
        context: p.windows,
      );
      expect(pattern.hasMatch('french.sta'), isFalse);
      expect(pattern.hasMatch('german_20260726_090503.sta'), isFalse);
      expect(pattern.hasMatch('french_2026_0726_090503.sta'), isFalse);
    });

    test('a regex metacharacter in the deck name is escaped, not '
        'interpreted', () {
      final RegExp pattern = DeckPaths.timestampedStatisticsPattern(
        '/decks/fr(en)ch+1.vok',
        context: p.posix,
      );
      expect(pattern.hasMatch('fr(en)ch+1_20260726_090503.sta'), isTrue);
      expect(pattern.hasMatch('frXenXchX1_20260726_090503.sta'), isFalse);
    });

    test('is derived from the deck name only, ignoring the folder', () {
      final RegExp windowsPattern = DeckPaths.timestampedStatisticsPattern(
        r'C:\a\french.vok',
        context: p.windows,
      );
      final RegExp posixPattern = DeckPaths.timestampedStatisticsPattern(
        '/b/c/french.vok',
        context: p.posix,
      );
      expect(windowsPattern.pattern, posixPattern.pattern);
    });
  });

  group('DeckPaths.linkedMask', () {
    test('derives <deck>.inf beside the deck', () {
      expect(
        DeckPaths.linkedMask(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks\french.inf',
      );
      expect(
        DeckPaths.linkedMask('/decks/french.vok', context: p.posix),
        '/decks/french.inf',
      );
    });

    test('numbers the base name when the conventional path is taken', () {
      expect(
        DeckPaths.linkedMask(
          '/decks/french.vok',
          suffix: 2,
          context: p.posix,
        ),
        '/decks/french_2.inf',
      );
      expect(
        DeckPaths.linkedMask(
          r'C:\decks\french.vok',
          suffix: 3,
          context: p.windows,
        ),
        r'C:\decks\french_3.inf',
      );
    });
  });

  group('DeckPaths.fileName / baseName', () {
    test('split a path into its parts under either style', () {
      expect(
        DeckPaths.fileName(r'C:\decks\french.vok', context: p.windows),
        'french.vok',
      );
      expect(
        DeckPaths.baseName(r'C:\decks\french.vok', context: p.windows),
        'french',
      );

      expect(
        DeckPaths.fileName('/decks/french.vok', context: p.posix),
        'french.vok',
      );
      expect(
        DeckPaths.baseName('/decks/french.vok', context: p.posix),
        'french',
      );
    });

    test('POSIX keeps a backslash inside the file name', () {
      expect(
        DeckPaths.fileName(r'/decks/back\slash.vok', context: p.posix),
        r'back\slash.vok',
      );
      expect(
        DeckPaths.baseName(r'/decks/back\slash.vok', context: p.posix),
        r'back\slash',
      );
    });

    test('Windows accepts forward slashes as separators too', () {
      expect(
        DeckPaths.fileName('C:/decks/french.vok', context: p.windows),
        'french.vok',
      );
    });
  });

  group('DeckPaths.hasExtension', () {
    test('is case-insensitive on every host', () {
      // Deliberate: a deck saved as FRENCH.VOK must still be recognised on
      // Linux, where the file system itself is case-sensitive.
      expect(DeckPaths.hasExtension('/decks/FRENCH.VOK', deckExtension), isTrue);
      expect(DeckPaths.hasExtension('/decks/french.Vok', deckExtension), isTrue);
      expect(DeckPaths.hasExtension(r'C:\decks\mask.INF', maskExtension), isTrue);
    });

    test('does not match a different extension or a bare stem', () {
      expect(DeckPaths.hasExtension('/decks/french.inf', deckExtension), isFalse);
      expect(DeckPaths.hasExtension('/decks/french', deckExtension), isFalse);
      expect(DeckPaths.hasExtension('/decks/vok', deckExtension), isFalse);
    });
  });

  group('DeckPaths.folderAndFileName', () {
    test('keeps the containing folder, eliding what is above it', () {
      expect(
        DeckPaths.folderAndFileName(
          r'D:\Sprachen\Kurse\Franz\LCI2_LC1.vok',
          context: p.windows,
        ),
        r'...\Franz\LCI2_LC1.vok',
      );
      expect(
        DeckPaths.folderAndFileName(
          '/home/pesche/decks/Franz/LCI2_LC1.vok',
          context: p.posix,
        ),
        '.../Franz/LCI2_LC1.vok',
      );
    });

    test('does not claim an elision when the folder is all there is', () {
      // Nothing sits above the folder, so there is nothing to stand in for.
      expect(
        DeckPaths.folderAndFileName(r'D:\Franz\french.vok', context: p.windows),
        r'D:\Franz\french.vok',
      );
      expect(
        DeckPaths.folderAndFileName('/Franz/french.vok', context: p.posix),
        '/Franz/french.vok',
      );
      expect(
        DeckPaths.folderAndFileName('Franz/french.vok', context: p.posix),
        'Franz/french.vok',
      );
    });

    test('falls back to the bare name when there is no folder at all', () {
      expect(
        DeckPaths.folderAndFileName('french.vok', context: p.posix),
        'french.vok',
      );
      expect(
        DeckPaths.folderAndFileName(r'C:\french.vok', context: p.windows),
        r'C:\french.vok',
      );
      expect(
        DeckPaths.folderAndFileName('/french.vok', context: p.posix),
        '/french.vok',
      );
    });

    test('a POSIX backslash stays part of the name it belongs to', () {
      // On Linux a backslash is an ordinary file-name character, so neither
      // the folder nor the file name may be split on it.
      expect(
        DeckPaths.folderAndFileName(
          '/home/pesche/back\\slash/deck\\one.vok',
          context: p.posix,
        ),
        '.../back\\slash/deck\\one.vok',
      );
    });
  });

  group('host-context default', () {
    test('the no-context overload agrees with the host style', () {
      final p.Context host = p.context;
      expect(
        DeckPaths.statisticsSidecar(host.join('decks', 'french.vok')),
        host.join('decks', 'french.sta'),
      );
      expect(
        DeckPaths.fileName(host.join('decks', 'french.vok')),
        'french.vok',
      );
    });
  });
}
