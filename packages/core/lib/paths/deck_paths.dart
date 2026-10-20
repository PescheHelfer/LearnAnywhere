/// Pure Dart derivation of the file paths that belong to a deck.
///
/// A deck (`.vok`) implies the location of its statistics (`.sta`) and its
/// linked mask (`.inf`): both are named after it, the mask beside it and the
/// desktop's statistics in the `statistics` folder beside it. That derivation
/// used to be done with ad-hoc `lastIndexOf` string surgery against
/// `Platform.pathSeparator`, which quietly assumed one separator per host. It
/// now goes through `package:path`, so a Windows path is parsed with Windows
/// rules and a POSIX path with POSIX rules — including the fact that on Linux a
/// backslash is an ORDINARY FILE NAME CHARACTER, not a separator.
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

/// Base-name suffix that marks the all-time statistics file of a deck.
///
/// Deliberately not a bare `<deck>.sta`: that name is the Android companion's
/// live statistics sidecar, so a deck carried between the two shells would
/// otherwise have one file meaning two different things.
const String allTimeStatisticsSuffix = 'alltime';

/// Name of the subfolder beside a deck that holds its session files and its
/// all-time statistics.
///
/// Fixed, lower case and never translated, so a deck folder shared between
/// Windows and Linux, or between an English and a German learner, means the
/// same folder to all of them.
const String statisticsFolderName = 'statistics';

/// Separator-safe derivation of the paths that belong to a deck.
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

  /// Returns the folder holding [deckPath]'s session files and all-time
  /// statistics: the [statisticsFolderName] subfolder beside the deck.
  ///
  /// The only place the desktop shell looks for them (ADR-0007). A bare deck
  /// name yields a bare `statistics`, relative like the deck itself.
  static String statisticsFolder(String deckPath, {p.Context? context}) {
    final p.Context ctx = context ?? p.context;
    final String deckFolder = ctx.dirname(deckPath);
    return deckFolder == '.'
        ? statisticsFolderName
        : ctx.join(deckFolder, statisticsFolderName);
  }

  /// Returns the plain `<deck>.sta` sidecar path for [deckPath].
  ///
  /// Beside the deck, NOT in [statisticsFolder]: this is the Android
  /// companion's live file, kept next to the deck in its private library.
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
  /// named `<deckname>_YYYYMMDD_HHMMSS.sta` in the deck's [statisticsFolder].
  static String timestampedStatistics(
    String deckPath,
    DateTime when, {
    p.Context? context,
  }) {
    return _inStatisticsFolder(
      deckPath,
      '_${formatStamp(when)}',
      context: context,
    );
  }

  /// Returns the all-time statistics path for [deckPath], named
  /// `<deckname>_alltime.sta` in the deck's [statisticsFolder].
  ///
  /// The lifetime record of a deck: written on every answer, never consulted by
  /// the learning engine. Its name cannot match
  /// [timestampedStatisticsPattern] (which requires digits after the
  /// underscore), so it is never picked up as a session file to auto-load.
  static String allTimeStatistics(String deckPath, {p.Context? context}) {
    return _inStatisticsFolder(
      deckPath,
      '_$allTimeStatisticsSuffix',
      context: context,
    );
  }

  /// `<statistics folder>/<deckname><suffix>.sta` for [deckPath].
  static String _inStatisticsFolder(
    String deckPath,
    String suffix, {
    p.Context? context,
  }) {
    final p.Context ctx = context ?? p.context;
    return ctx.join(
      statisticsFolder(deckPath, context: ctx),
      '${baseName(deckPath, context: ctx)}$suffix.$statisticsExtension',
    );
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

  /// Returns [path] shortened to the folder holding it and its file name,
  /// e.g. `...\Franz\LCI2_LC1.vok`.
  ///
  /// A deck's file name alone rarely says which language it belongs to, while
  /// its folder usually does; the whole path is too long for a link. The
  /// leading `...` stands in for what was dropped, so it appears only when
  /// something actually was: a deck whose folder sits at a root, or which has
  /// no folder part at all, is returned unchanged rather than pretending to be
  /// abbreviated.
  static String folderAndFileName(String path, {p.Context? context}) {
    final p.Context ctx = context ?? p.context;
    final String dir = ctx.dirname(path);
    final String folder = ctx.basename(dir);
    if (folder.isEmpty || folder == '.') {
      return path;
    }
    final String above = ctx.dirname(dir);
    if (above == ctx.rootPrefix(dir) || above == '.') {
      return path;
    }
    return '...${ctx.separator}$folder${ctx.separator}${ctx.basename(path)}';
  }

  /// Returns [path]'s last segment without its extension.
  static String baseName(String path, {p.Context? context}) {
    return (context ?? p.context).basenameWithoutExtension(path);
  }

  /// Whether [fileName] is one of [deckPath]'s statistics files: the plain
  /// sidecar, a timestamped session file, or the all-time file.
  ///
  /// [fileName] is a bare file name (as a directory listing returns it), not
  /// a full path. Matching is exact and case-insensitive for the sidecar and
  /// all-time names, and by [timestampedStatisticsPattern] for session files,
  /// so a neighbouring deck whose name is a prefix of this one — `Foo` next to
  /// `Foo2` — is never mistaken for it: `Foo2.sta` and `Foo2_alltime.sta`
  /// don't equal `Foo`'s exact names, and `Foo2_20260101_120000.sta` fails the
  /// anchored `Foo_` pattern.
  static bool isStatisticsFileFor(
    String deckPath,
    String fileName, {
    p.Context? context,
  }) {
    final p.Context ctx = context ?? p.context;
    final String candidate = fileName.toLowerCase();
    final String sidecar = DeckPaths.fileName(
      statisticsSidecar(deckPath, context: ctx),
      context: ctx,
    ).toLowerCase();
    if (candidate == sidecar) {
      return true;
    }
    final String allTime = DeckPaths.fileName(
      allTimeStatistics(deckPath, context: ctx),
      context: ctx,
    ).toLowerCase();
    if (candidate == allTime) {
      return true;
    }
    return timestampedStatisticsPattern(
      deckPath,
      context: ctx,
    ).hasMatch(fileName);
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
