import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
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
  ///
  /// [typeLabel] is the localized caption for the extension filter; it is
  /// passed in by the caller so this service holds no user-facing strings.
  /// Android has no MIME type registered for `.vok`, so the system picker
  /// lists all files there and the label stays hidden — a file that does not
  /// decode surfaces as a load error, exactly as a wrong pick did before.
  Future<MobileDeckDocument?> openDeck({required String typeLabel}) async {
    final fs.XFile? picked = await fs.openFile(
      acceptedTypeGroups: <fs.XTypeGroup>[
        fs.XTypeGroup(label: typeLabel, extensions: const <String>['vok']),
      ],
    );
    if (picked == null) {
      return null;
    }
    final String source = await picked.readAsString();
    final LearningDeck deck = decodeDeckJson(source);
    final String path = picked.path;
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
        StatisticsFile(
          deckRef: _fileName(deckPath),
          // Hashes are recomputed from the deck on every write, exactly as on
          // desktop. Passing the counters through unhashed would leave the
          // phone's sidecars unidentifiable; passing them through with the
          // hashes they were loaded with would be worse still, since this
          // shell still re-indexes them positionally.
          perUnit: withUnitHashes(document.deck, statistics),
        ),
      ),
    );
  }

  /// Returns the `.sta` sidecar path for [deckPath].
  String statisticsSidecarPath(String deckPath) {
    return DeckPaths.statisticsSidecar(deckPath);
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

  String _fileName(String path) => DeckPaths.fileName(path);
}
