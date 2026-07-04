import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

import 'desktop_document.dart';

/// Handles disk persistence for desktop deck, mask, and statistics files.
final class DesktopFileService {
  /// Creates a desktop file service.
  const DesktopFileService();

  /// Creates a new empty deck carrying the current auto-load/save toggles.
  ///
  /// The app layer auto-saves the outgoing statistics (with an overwrite
  /// prompt) before calling this; see `_confirmAndAutoSaveStats` in main.dart.
  Future<DesktopDocument> newDeck(
    DesktopDocument current, {
    LearningMask? mask,
  }) async {
    return DesktopDocument.empty(mask ?? current.mask).copyWith(
      autoLoadStatistics: current.autoLoadStatistics,
      autoSaveStatistics: current.autoSaveStatistics,
    );
  }

  /// Opens a `.vok` deck and auto-loads its sidecar `.sta` when configured.
  ///
  /// Outgoing statistics are auto-saved by the app layer before this runs.
  Future<DesktopDocument> openDeck(DesktopDocument current, String path) async {
    final LearningDeck deck = decodeDeckJson(await File(path).readAsString());
    var statistics = clearStatistics(deck);
    String? statisticsPath;
    if (current.autoLoadStatistics) {
      final String sidecarPath = statisticsSidecarPath(path);
      final File sidecar = File(sidecarPath);
      if (await sidecar.exists()) {
        statistics = decodeStatisticsJson(await sidecar.readAsString()).perUnit;
        statisticsPath = sidecarPath;
      }
    }
    return DesktopDocument(
      deck: deck,
      statistics: statistics,
      deckPath: path,
      statisticsPath: statisticsPath,
      autoLoadStatistics: current.autoLoadStatistics,
      autoSaveStatistics: current.autoSaveStatistics,
    );
  }

  /// Merges units from another `.vok` into the current in-memory deck.
  Future<DesktopDocument> mergeDeck(
    DesktopDocument current,
    String path,
  ) async {
    final LearningDeck incoming = decodeDeckJson(
      await File(path).readAsString(),
    );
    if (encodeMaskJson(incoming.mask) != encodeMaskJson(current.mask)) {
      throw const FileOperationException(
        'Cannot merge a deck whose embedded mask differs from the current mask.',
      );
    }
    final LearningDeck merged = LearningDeck(
      mask: current.mask,
      units: List<LearningUnit>.unmodifiable(<LearningUnit>[
        ...current.deck.units,
        ...incoming.units,
      ]),
    );
    return current.copyWith(
      deck: merged,
      statistics: _resizeStats(current.statistics, merged),
    );
  }

  /// Saves the current deck to [path] or its existing path.
  Future<DesktopDocument> saveDeck(
    DesktopDocument current, {
    String? path,
  }) async {
    final String? targetPath = path ?? current.deckPath;
    if (targetPath == null) {
      throw const FileOperationException('No deck path was provided.');
    }
    await File(targetPath).writeAsString(encodeDeckJson(current.deck));
    final DesktopDocument saved = current.copyWith(deckPath: targetPath);
    await autoSaveStatistics(saved);
    return saved;
  }

  /// Saves [deck] to [path] without changing the current desktop document.
  Future<void> saveDeckSnapshot(LearningDeck deck, String path) async {
    await File(path).writeAsString(encodeDeckJson(deck));
  }

  /// Loads all `.vok` decks matching a simple file glob pattern.
  Future<Map<String, LearningDeck>> loadDecksByPattern(String pattern) async {
    final _DeckPattern parsed = _DeckPattern.parse(pattern);
    final Directory directory = Directory(parsed.directoryPath);
    if (!await directory.exists()) {
      throw FileOperationException(
        'Search directory does not exist: ${parsed.directoryPath}',
      );
    }
    final RegExp fileNamePattern = parsed.fileNameRegex;
    final Map<String, LearningDeck> decks = <String, LearningDeck>{};
    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final String fileName = _fileName(entity.path);
      if (!fileNamePattern.hasMatch(fileName)) {
        continue;
      }
      decks[entity.path] = decodeDeckJson(await entity.readAsString());
    }
    return decks;
  }

  /// Clears units in memory without deleting files.
  DesktopDocument clearUnits(DesktopDocument current) {
    final LearningDeck deck = LearningDeck(
      mask: current.mask,
      units: const <LearningUnit>[],
    );
    return current.copyWith(deck: deck, statistics: clearStatistics(deck));
  }

  /// Loads a standalone `.inf` mask and clears in-memory units.
  ///
  /// Outgoing statistics are auto-saved by the app layer before this runs.
  Future<DesktopDocument> loadMask(DesktopDocument current, String path) async {
    final LearningMask mask = decodeMaskJson(await File(path).readAsString());
    return DesktopDocument.empty(mask).copyWith(
      autoLoadStatistics: current.autoLoadStatistics,
      autoSaveStatistics: current.autoSaveStatistics,
    );
  }

  /// Saves the current embedded mask as a standalone `.inf`.
  Future<void> saveMask(LearningMask mask, String path) async {
    await File(path).writeAsString(encodeMaskJson(mask));
  }

  /// Reads and decodes a standalone `.inf` mask file.
  Future<LearningMask> readMask(String path) async {
    return decodeMaskJson(await File(path).readAsString());
  }

  /// Finds the `.inf` in [deckPath]'s own directory whose embedded maskId
  /// equals [maskId], or `null` when none exists.
  ///
  /// This resolves the editable mask file LINKED to a loaded deck (Step 4).
  /// Two files describe the same mask iff their maskIds are equal, so matching
  /// is by maskId only — never by name or contents. Unreadable or invalid
  /// `.inf` files are skipped rather than aborting the scan.
  Future<String?> findLinkedMaskPath(String deckPath, String maskId) async {
    final Directory directory = File(deckPath).parent;
    if (!await directory.exists()) {
      return null;
    }
    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File || !_hasExtension(entity.path, 'inf')) {
        continue;
      }
      try {
        final LearningMask mask = decodeMaskJson(await entity.readAsString());
        if (mask.maskId == maskId) {
          return entity.path;
        }
      } on Object {
        continue;
      }
    }
    return null;
  }

  /// Writes a new `.inf` beside [deckPath] built from [mask], REUSING its
  /// existing maskId (never minting a new one), and returns the created path.
  ///
  /// Used when the Mask Editor opens for a deck that has no linked `.inf` yet
  /// and the user opts to create one from the deck's embedded mask.
  Future<String> createLinkedMask(String deckPath, LearningMask mask) async {
    final String infPath = _withExtension(deckPath, 'inf');
    await File(infPath).writeAsString(encodeMaskJson(mask));
    return infPath;
  }

  /// Classifies (WITHOUT writing) every `.vok` in [maskDirectory] that shares
  /// [newMask]'s maskId, comparing each deck's embedded (old) mask to [newMask]
  /// via the core compatibility check.
  ///
  /// This is the dry-run behind tier-1 propagation (Step 6): the caller decides
  /// what to write based on the returned plan. [excludePaths] skips files (e.g.
  /// the deck currently open in memory, handled separately). Decks that fail to
  /// decode are skipped.
  Future<MaskPropagationPlan> planMaskPropagation({
    required String maskDirectory,
    required LearningMask newMask,
    Iterable<String> excludePaths = const <String>[],
  }) async {
    final Directory directory = Directory(maskDirectory);
    final List<String> compatible = <String>[];
    final List<DeckBreak> breaking = <DeckBreak>[];
    if (!await directory.exists()) {
      return MaskPropagationPlan(compatible: compatible, breaking: breaking);
    }
    final Set<String> excluded = excludePaths.toSet();
    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File ||
          !_hasExtension(entity.path, 'vok') ||
          excluded.contains(entity.path)) {
        continue;
      }
      final LearningDeck deck;
      try {
        deck = decodeDeckJson(await entity.readAsString());
      } on Object {
        continue;
      }
      if (deck.mask.maskId != newMask.maskId) {
        continue;
      }
      final MaskCompatibilityResult result = checkMaskCompatibility(
        oldMask: deck.mask,
        newMask: newMask,
        units: deck.units,
      );
      if (result.isCompatible) {
        compatible.add(entity.path);
      } else {
        breaking.add(DeckBreak(deckPath: entity.path, reasons: result.reasons));
      }
    }
    return MaskPropagationPlan(compatible: compatible, breaking: breaking);
  }

  /// Overwrites the embedded mask cache of each deck in [deckPaths] with
  /// [newMask], pruning any unit data orphaned by the new schema (see
  /// [applyMaskToDeck]). Decks that fail to decode are skipped.
  Future<void> applyMaskPropagation({
    required LearningMask newMask,
    required Iterable<String> deckPaths,
  }) async {
    for (final String path in deckPaths) {
      final LearningDeck deck;
      try {
        deck = decodeDeckJson(await File(path).readAsString());
      } on Object {
        continue;
      }
      final LearningDeck updated = applyMaskToDeck(deck, newMask);
      await File(path).writeAsString(encodeDeckJson(updated));
    }
  }

  bool _hasExtension(String path, String extension) {
    return path.toLowerCase().endsWith('.${extension.toLowerCase()}');
  }

  String _withExtension(String path, String extension) {
    final int separator = path.lastIndexOf(Platform.pathSeparator);
    final int dot = path.lastIndexOf('.');
    final String base = dot > separator ? path.substring(0, dot) : path;
    return '$base.$extension';
  }

  /// Loads a `.sta` statistics file into the current document.
  Future<DesktopDocument> loadStatistics(
    DesktopDocument current,
    String path,
  ) async {
    final StatisticsFile statistics = decodeStatisticsJson(
      await File(path).readAsString(),
    );
    return current.copyWith(
      statistics: _resizeStats(statistics.perUnit, current.deck),
      statisticsPath: path,
    );
  }

  /// Saves current statistics to [path].
  Future<DesktopDocument> saveStatistics(
    DesktopDocument current,
    String path,
  ) async {
    await File(path).writeAsString(
      encodeStatisticsJson(
        StatisticsFile(
          deckRef: current.deckPath == null
              ? 'unsaved.vok'
              : _fileName(current.deckPath!),
          perUnit: current.statistics,
        ),
      ),
    );
    return current.copyWith(statisticsPath: path);
  }

  /// Clears all current statistics.
  DesktopDocument clearStatisticsInMemory(DesktopDocument current) {
    return current.copyWith(statistics: clearStatistics(current.deck));
  }

  /// Auto-saves statistics for [document] when configured and a deck path exists.
  Future<void> autoSaveStatistics(DesktopDocument document) async {
    if (!document.autoSaveStatistics || document.deckPath == null) {
      return;
    }
    final String targetPath =
        document.statisticsPath ?? statisticsSidecarPath(document.deckPath!);
    await File(targetPath).writeAsString(
      encodeStatisticsJson(
        StatisticsFile(
          deckRef: _fileName(document.deckPath!),
          perUnit: document.statistics,
        ),
      ),
    );
  }

  /// Returns the platform-appropriate path of the user settings file.
  ///
  /// On Windows this lives under `%APPDATA%`, elsewhere under
  /// `$XDG_CONFIG_HOME` or `$HOME/.config`, always inside a `LearnAnywhere`
  /// folder. The path is resolved here (in the app layer) and handed to the
  /// pure-Dart settings serializer in core.
  String settingsFilePath() {
    final Map<String, String> env = Platform.environment;
    final String sep = Platform.pathSeparator;
    final String base;
    if (Platform.isWindows) {
      base = env['APPDATA'] ?? Directory.current.path;
    } else {
      final String? xdg = env['XDG_CONFIG_HOME'];
      if (xdg != null && xdg.isNotEmpty) {
        base = xdg;
      } else {
        final String? home = env['HOME'];
        base = home != null && home.isNotEmpty
            ? '$home$sep.config'
            : Directory.current.path;
      }
    }
    return '$base${sep}LearnAnywhere$sep$settingsFileName';
  }

  /// Returns the conventional `.sta` sidecar path for [deckPath].
  String statisticsSidecarPath(String deckPath) {
    final int separator = deckPath.lastIndexOf(Platform.pathSeparator);
    final int dot = deckPath.lastIndexOf('.');
    if (dot > separator) {
      return '${deckPath.substring(0, dot)}.sta';
    }
    return '$deckPath.sta';
  }

  List<UnitStats> _resizeStats(List<UnitStats> current, LearningDeck deck) {
    final Map<int, UnitStats> byIndex = <int, UnitStats>{
      for (final UnitStats stats in current) stats.index: stats,
    };
    return List<UnitStats>.generate(
      deck.units.length,
      (int index) => byIndex[index + 1] ?? UnitStats(index: index + 1),
      growable: false,
    );
  }

  String _fileName(String path) {
    final int separator = path.lastIndexOf(Platform.pathSeparator);
    return separator < 0 ? path : path.substring(separator + 1);
  }
}

/// A same-directory deck that a mask edit would break, with its reasons.
final class DeckBreak {
  /// Creates a deck-break record.
  const DeckBreak({required this.deckPath, required this.reasons});

  /// Path of the `.vok` that would lose data.
  final String deckPath;

  /// Why applying the new mask would break this deck.
  final List<MaskBreakingReason> reasons;
}

/// The dry-run result of tier-1 propagation: which sibling decks would update
/// cleanly and which would break.
final class MaskPropagationPlan {
  /// Creates a propagation plan.
  const MaskPropagationPlan({required this.compatible, required this.breaking});

  /// Paths of decks whose embedded cache can be updated without data loss.
  final List<String> compatible;

  /// Decks that would lose data, with reasons; not updated unless forced.
  final List<DeckBreak> breaking;

  /// Whether any sibling deck would break.
  bool get hasBreaking => breaking.isNotEmpty;

  /// All matching deck paths (compatible + breaking).
  List<String> get allPaths => <String>[
    ...compatible,
    ...breaking.map((DeckBreak deck) => deck.deckPath),
  ];
}

/// File operation failure with a user-facing message.
final class FileOperationException implements Exception {
  /// Creates a file operation exception.
  const FileOperationException(this.message);

  /// Failure message.
  final String message;

  @override
  String toString() => message;
}

final class _DeckPattern {
  const _DeckPattern({
    required this.directoryPath,
    required this.fileNamePattern,
  });

  final String directoryPath;
  final String fileNamePattern;

  RegExp get fileNameRegex {
    final StringBuffer buffer = StringBuffer('^');
    for (var index = 0; index < fileNamePattern.length; index += 1) {
      final String character = fileNamePattern[index];
      if (character == '*') {
        buffer.write('.*');
      } else if (character == '?') {
        buffer.write('.');
      } else {
        buffer.write(RegExp.escape(character));
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString(), caseSensitive: false);
  }

  static _DeckPattern parse(String pattern) {
    final String trimmed = pattern.trim();
    if (trimmed.isEmpty) {
      throw const FileOperationException('No search pattern was provided.');
    }
    final int slash = trimmed.lastIndexOf('/');
    final int backslash = trimmed.lastIndexOf(r'\');
    final int separator = slash > backslash ? slash : backslash;
    final String directoryPath = separator < 0
        ? Directory.current.path
        : trimmed.substring(0, separator);
    final String fileNamePattern = separator < 0
        ? trimmed
        : trimmed.substring(separator + 1);
    if (fileNamePattern.isEmpty) {
      throw const FileOperationException(
        'Search pattern must include a file mask.',
      );
    }
    return _DeckPattern(
      directoryPath: directoryPath.isEmpty
          ? Directory.current.path
          : directoryPath,
      fileNamePattern: fileNamePattern,
    );
  }
}
