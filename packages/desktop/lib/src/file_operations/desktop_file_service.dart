import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

import 'desktop_document.dart';

/// Handles disk persistence for desktop deck, mask, and statistics files.
final class DesktopFileService {
  /// Creates a desktop file service.
  const DesktopFileService();

  /// Creates a new empty deck, auto-saving current statistics first if needed.
  Future<DesktopDocument> newDeck(
    DesktopDocument current, {
    LearningMask? mask,
  }) async {
    await autoSaveStatistics(current);
    return DesktopDocument.empty(mask ?? current.mask).copyWith(
      autoLoadStatistics: current.autoLoadStatistics,
      autoSaveStatistics: current.autoSaveStatistics,
    );
  }

  /// Opens a `.vok` deck and auto-loads its sidecar `.sta` when configured.
  Future<DesktopDocument> openDeck(DesktopDocument current, String path) async {
    await autoSaveStatistics(current);
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

  /// Clears units in memory without deleting files.
  DesktopDocument clearUnits(DesktopDocument current) {
    final LearningDeck deck = LearningDeck(
      mask: current.mask,
      units: const <LearningUnit>[],
    );
    return current.copyWith(deck: deck, statistics: clearStatistics(deck));
  }

  /// Loads a standalone `.inf` mask and clears in-memory units.
  Future<DesktopDocument> loadMask(DesktopDocument current, String path) async {
    await autoSaveStatistics(current);
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

/// File operation failure with a user-facing message.
final class FileOperationException implements Exception {
  /// Creates a file operation exception.
  const FileOperationException(this.message);

  /// Failure message.
  final String message;

  @override
  String toString() => message;
}
