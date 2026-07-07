import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:learn_anywhere_core/core.dart';

/// Loaded mobile deck and its optional sidecar state.
final class MobileDeckDocument {
  /// Creates a mobile deck document.
  const MobileDeckDocument({
    required this.deck,
    required this.statistics,
    this.deckPath,
  });

  /// Current read-only deck.
  final LearningDeck deck;

  /// Optional path to the opened `.vok` deck.
  final String? deckPath;

  /// Per-unit statistics loaded from, or saved to, the `.sta` sidecar.
  final List<UnitStats> statistics;

  /// Returns a copy with selected fields replaced.
  MobileDeckDocument copyWith({List<UnitStats>? statistics}) {
    return MobileDeckDocument(
      deck: deck,
      deckPath: deckPath,
      statistics: statistics ?? this.statistics,
    );
  }
}

/// Handles Android deck opening and statistics sidecar persistence.
class MobileFileService {
  /// Opens a `.vok` deck selected through the platform file picker.
  Future<MobileDeckDocument?> openDeck() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['vok'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile picked = result.files.single;
    final String source = picked.path != null
        ? await File(picked.path!).readAsString()
        : utf8.decode(picked.bytes ?? const <int>[]);
    final LearningDeck deck = decodeDeckJson(source);
    final String? path = picked.path;
    return MobileDeckDocument(
      deck: deck,
      deckPath: path,
      statistics: await _loadStatistics(deck, path),
    );
  }

  /// Saves [statistics] beside [document]'s deck when a path is available.
  Future<void> saveStatistics(
    MobileDeckDocument document,
    List<UnitStats> statistics,
  ) async {
    final String? deckPath = document.deckPath;
    if (deckPath == null) {
      return;
    }
    await File(statisticsSidecarPath(deckPath)).writeAsString(
      encodeStatisticsJson(
        // Store the deck's file name only (not the absolute device path), to
        // match desktop and keep the .sta portable across platforms.
        StatisticsFile(deckRef: _fileName(deckPath), perUnit: statistics),
      ),
    );
  }

  /// Returns the `.sta` sidecar path for [deckPath].
  String statisticsSidecarPath(String deckPath) {
    final int dot = deckPath.lastIndexOf('.');
    if (dot <= deckPath.lastIndexOf(Platform.pathSeparator)) {
      return '$deckPath.sta';
    }
    return '${deckPath.substring(0, dot)}.sta';
  }

  Future<List<UnitStats>> _loadStatistics(
    LearningDeck deck,
    String? deckPath,
  ) async {
    if (deckPath == null) {
      return clearStatistics(deck);
    }
    final File sidecar = File(statisticsSidecarPath(deckPath));
    if (!sidecar.existsSync()) {
      return clearStatistics(deck);
    }
    final StatisticsFile statistics = decodeStatisticsJson(
      await sidecar.readAsString(),
    );
    return resizeUnitStats(statistics.perUnit, deck.units.length);
  }

  String _fileName(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf(r'\');
    final int separator = slash > backslash ? slash : backslash;
    return separator < 0 ? path : path.substring(separator + 1);
  }
}
