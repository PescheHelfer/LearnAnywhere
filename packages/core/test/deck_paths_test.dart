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

  group('DeckPaths.timestampedStatistics', () {
    final DateTime when = DateTime(2026, 7, 26, 9, 5, 3);

    test('names the session file <deck>_YYYYMMDD_HHMMSS.sta beside the '
        'deck', () {
      expect(
        DeckPaths.timestampedStatistics(
          r'C:\decks\french.vok',
          when,
          context: p.windows,
        ),
        r'C:\decks\french_20260726_090503.sta',
      );
      expect(
        DeckPaths.timestampedStatistics(
          '/home/pesche/decks/french.vok',
          when,
          context: p.posix,
        ),
        '/home/pesche/decks/french_20260726_090503.sta',
      );
    });

    test('keeps a bare deck name in the working directory', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          DeckPaths.timestampedStatistics('french.vok', when, context: ctx),
          'french_20260726_090503.sta',
        );
      }
    });

    test('zero-pads every stamp component', () {
      expect(
        DeckPaths.formatStamp(DateTime(2026, 1, 2, 3, 4, 5)),
        '20260102_030405',
      );
    });
  });

  group('DeckPaths.allTimeStatistics', () {
    test('names the lifetime file <deck>_alltime.sta beside the deck', () {
      expect(
        DeckPaths.allTimeStatistics(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks\french_alltime.sta',
      );
      expect(
        DeckPaths.allTimeStatistics(
          '/home/pesche/decks/french.vok',
          context: p.posix,
        ),
        '/home/pesche/decks/french_alltime.sta',
      );
    });

    test('keeps a bare deck name in the working directory', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          DeckPaths.allTimeStatistics('french.vok', context: ctx),
          'french_alltime.sta',
        );
      }
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
        'french_alltime_alltime.sta',
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

  group('DeckPaths.fileName / directory / baseName', () {
    test('split a path into its parts under either style', () {
      expect(
        DeckPaths.fileName(r'C:\decks\french.vok', context: p.windows),
        'french.vok',
      );
      expect(
        DeckPaths.directory(r'C:\decks\french.vok', context: p.windows),
        r'C:\decks',
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
        DeckPaths.directory('/decks/french.vok', context: p.posix),
        '/decks',
      );
      expect(
        DeckPaths.baseName('/decks/french.vok', context: p.posix),
        'french',
      );
    });

    test('report "." as the directory of a bare file name', () {
      // `Directory('.')` is the working directory, which is what the desktop
      // service relies on when a deck path has no folder part.
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(DeckPaths.directory('french.vok', context: ctx), '.');
      }
    });

    test('POSIX keeps a backslash inside the file name', () {
      expect(
        DeckPaths.fileName(r'/decks/back\slash.vok', context: p.posix),
        r'back\slash.vok',
      );
      expect(
        DeckPaths.directory(r'/decks/back\slash.vok', context: p.posix),
        '/decks',
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
      expect(
        DeckPaths.directory('C:/decks/french.vok', context: p.windows),
        'C:/decks',
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
