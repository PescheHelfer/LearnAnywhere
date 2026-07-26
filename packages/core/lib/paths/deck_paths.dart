/// Pure Dart derivation of the file paths that sit beside a deck.
///
/// A deck (`.vok`) implies the location of its statistics (`.sta`) and its
/// linked mask (`.inf`): they live in the deck's own folder and are named after
/// it. That derivation used to be done with ad-hoc `lastIndexOf` string surgery
/// against `Platform.pathSeparator`, which quietly assumed one separator per
/// host. It now goes through `package:path`, so a Windows path is parsed with
/// Windows rules and a POSIX path with POSIX rules — including the fact that on
/// Linux a backslash is an ORDINARY FILE NAME CHARACTER, not a separator.
///
/// Every function takes an optional [p.Context], defaulting to the host's. Pass
/// [p.windows] or [p.posix] explicitly to get deterministic results — that is
/// what lets these paths be unit-tested on any host.
library;

import 'package:path/path.dart' as p;

/// Extension (without dot) of a deck file.
const String deckExtension = 'vok';

/// Extension (without dot) of a standalone mask file.
const String maskExtension = 'inf';

/// Extension (without dot) of a statistics file.
const String statisticsExtension = 'sta';

/// Separator-safe derivation of the paths that live beside a deck.
final class DeckPaths {
  const DeckPaths._();

  /// Returns [path] with its final extension replaced by [extension], keeping
  /// the directory part byte-for-byte.
  ///
  /// A [suffix] appends `_<suffix>` to the base name, which is how a
  /// conflict-free `<deck>_2.inf` is built. A path with no extension simply
  /// gains one.
  static String withExtension(
    String path,
    String extension, {
    int? suffix,
    p.Context? context,
  }) {
    final p.Context ctx = context ?? p.context;
    final String base = ctx.withoutExtension(path);
    final String suffixed = suffix == null ? base : '${base}_$suffix';
    return '$suffixed.$extension';
  }

  /// Returns the plain `<deck>.sta` sidecar path for [deckPath].
  static String statisticsSidecar(String deckPath, {p.Context? context}) {
    return withExtension(deckPath, statisticsExtension, context: context);
  }

  /// Returns the linked-mask path `<deck>.inf` for [deckPath], optionally with
  /// a numbered [suffix] when the conventional name is already taken.
  static String linkedMask(String deckPath, {int? suffix, p.Context? context}) {
    return withExtension(
      deckPath,
      maskExtension,
      suffix: suffix,
      context: context,
    );
  }

  /// Returns the timestamped session statistics path for [deckPath] at [when],
  /// named `<deckname>_YYYYMMDD_HHMMSS.sta` in the deck's own folder (§3.7).
  static String timestampedStatistics(
    String deckPath,
    DateTime when, {
    p.Context? context,
  }) {
    final p.Context ctx = context ?? p.context;
    return '${ctx.withoutExtension(deckPath)}_${formatStamp(when)}'
        '.$statisticsExtension';
  }

  /// Formats [when] as the `YYYYMMDD_HHMMSS` stamp used in session file names.
  static String formatStamp(DateTime when) {
    String pad(int value, int width) => value.toString().padLeft(width, '0');
    return '${pad(when.year, 4)}${pad(when.month, 2)}${pad(when.day, 2)}'
        '_${pad(when.hour, 2)}${pad(when.minute, 2)}${pad(when.second, 2)}';
  }

  /// Matches a `<deckname>_YYYYMMDD_HHMMSS.sta` FILE NAME (not a full path)
  /// belonging to [deckPath], capturing the six date/time groups in order.
  ///
  /// A plain `<deckname>.sta` deliberately does not match, so only session
  /// files this app wrote are considered for auto-loading.
  static RegExp timestampedStatisticsPattern(
    String deckPath, {
    p.Context? context,
  }) {
    return RegExp(
      '^${RegExp.escape(baseName(deckPath, context: context))}'
      r'_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})'
      '\\.$statisticsExtension\$',
      caseSensitive: false,
    );
  }

  /// Returns the last segment of [path].
  ///
  /// Under [p.windows] both `/` and `\` end a segment; under [p.posix] only
  /// `/` does, so a Linux file literally named `back\slash.vok` stays intact.
  static String fileName(String path, {p.Context? context}) {
    return (context ?? p.context).basename(path);
  }

  /// Returns the directory containing [path], or `.` when [path] has no
  /// directory part (which `Directory` resolves to the working directory).
  static String directory(String path, {p.Context? context}) {
    return (context ?? p.context).dirname(path);
  }

  /// Returns [path]'s last segment without its extension.
  static String baseName(String path, {p.Context? context}) {
    return (context ?? p.context).basenameWithoutExtension(path);
  }

  /// Whether [path] ends in `.[extension]`, ignoring case.
  ///
  /// Case-insensitive on every host on purpose: a deck typed as `FRENCH.VOK`
  /// must still be recognised on Linux, where the file system would otherwise
  /// treat it as a different name entirely.
  static bool hasExtension(String path, String extension) {
    return path.toLowerCase().endsWith('.${extension.toLowerCase()}');
  }
}
