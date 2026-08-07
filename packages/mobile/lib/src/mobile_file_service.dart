import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// Path to the deck's `.vok` file in the on-device library.
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

/// One deck in the on-device library, as shown by the library screen.
final class LibraryDeckEntry {
  /// Creates a library deck entry.
  const LibraryDeckEntry({
    required this.path,
    required this.name,
    required this.unitCount,
  });

  /// Path to the deck's `.vok` file in the library.
  final String path;

  /// Deck (mask) name, shown as the entry's title.
  final String name;

  /// Number of units in the deck.
  final int unitCount;
}

/// Handles the on-device deck library: import, open, delete, and statistics
/// sidecar persistence.
///
/// The library is a flat folder in internal app storage (per-app, covered by
/// Android auto-backup), keyed by file name — SAF picker results carry no
/// folder structure to reconstruct. `.vok` and `.sta` both live there, paired
/// by name exactly as `DeckPaths` already assumes.
class MobileFileService {
  /// Creates a mobile file service.
  ///
  /// [libraryDirectory] lets tests point the service at a fake directory
  /// instead of real device storage.
  MobileFileService({Directory? libraryDirectory})
    : _libraryDirectoryOverride = libraryDirectory;

  final Directory? _libraryDirectoryOverride;

  /// Returns the library directory, creating it if it does not exist yet.
  Future<Directory> libraryDirectory() async {
    final Directory override = _libraryDirectoryOverride ?? await _default();
    if (!override.existsSync()) {
      await override.create(recursive: true);
    }
    return override;
  }

  Future<Directory> _default() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'library'));
  }

  /// Lists the decks currently in the library, sorted by name.
  ///
  /// A file that fails to decode is skipped rather than surfaced as an
  /// error: one damaged deck should not make the whole library unusable.
  Future<List<LibraryDeckEntry>> listDecks() async {
    final Directory dir = await libraryDirectory();
    final List<LibraryDeckEntry> entries = <LibraryDeckEntry>[];
    for (final FileSystemEntity entity in dir.listSync()) {
      if (entity is! File || !DeckPaths.hasExtension(entity.path, deckExtension)) {
        continue;
      }
      try {
        final LearningDeck deck = decodeDeckJson(await entity.readAsString());
        entries.add(
          LibraryDeckEntry(
            path: entity.path,
            name: deck.mask.name,
            unitCount: deck.units.length,
          ),
        );
      } on Object {
        continue;
      }
    }
    entries.sort(
      (LibraryDeckEntry a, LibraryDeckEntry b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  /// Opens the deck at [path] in the library, loading its `.sta` sidecar
  /// (realigned against the deck) when one exists.
  Future<MobileDeckDocument> openDeck(String path) async {
    final LearningDeck deck = decodeDeckJson(await File(path).readAsString());
    return MobileDeckDocument(
      deck: deck,
      deckPath: path,
      statistics: await _loadStatistics(deck, path),
    );
  }

  /// Imports one or more `.vok` decks through the system document picker,
  /// copying their bytes into the library.
  ///
  /// Android has no MIME type registered for `.vok`, so the system picker
  /// lists all files there; a file that fails to decode surfaces as the
  /// existing load error rather than being silently skipped, since a picked
  /// file (unlike a stray library entry) was explicitly chosen by the user.
  ///
  /// Returns the number of decks imported (0 if the user cancelled).
  Future<int> importDecks() async {
    final List<fs.XFile> picked = await fs.openFiles(
      acceptedTypeGroups: <fs.XTypeGroup>[
        fs.XTypeGroup(extensions: const <String>['vok']),
      ],
    );
    if (picked.isEmpty) {
      return 0;
    }
    return importFiles(picked);
  }

  /// Imports [files] into the library, applying collision-replace.
  ///
  /// Split out from [importDecks] so the copy and collision-replace logic can
  /// be exercised without driving the system file picker: tests pass in
  /// [fs.XFile]s built from fixture files instead.
  Future<int> importFiles(List<fs.XFile> files) async {
    final Directory dir = await libraryDirectory();
    for (final fs.XFile file in files) {
      final String source = await file.readAsString();
      final LearningDeck deck = decodeDeckJson(source);
      final String destinationPath = p.join(
        dir.path,
        DeckPaths.fileName(file.path),
      );
      await _importOne(
        destinationPath: destinationPath,
        deck: deck,
        source: source,
      );
    }
    return files.length;
  }

  Future<void> _importOne({
    required String destinationPath,
    required LearningDeck deck,
    required String source,
  }) async {
    final File sidecar = File(statisticsSidecarPath(destinationPath));
    if (await sidecar.exists()) {
      // Name collision: replace the .vok, keep and realign the .sta so the
      // deck's statistics survive being re-imported from elsewhere.
      final StatisticsFile existing = decodeStatisticsJson(
        await sidecar.readAsString(),
      );
      final StatisticsRealignment realignment = realignStatistics(
        deck: deck,
        statistics: existing.perUnit,
        levelStatistics:
            existing.levelLearning?.perUnit ?? const <LevelUnitStats>[],
      );
      await File(destinationPath).writeAsString(source);
      await sidecar.writeAsString(
        encodeStatisticsJson(
          StatisticsFile(
            deckRef: DeckPaths.fileName(destinationPath),
            perUnit: realignment.statistics,
          ),
        ),
      );
    } else {
      await File(destinationPath).writeAsString(source);
    }
  }

  /// Deletes the deck at [path] and its `.sta` sidecar, if any.
  Future<void> deleteDeck(String path) async {
    final File deck = File(path);
    if (await deck.exists()) {
      await deck.delete();
    }
    final File sidecar = File(statisticsSidecarPath(path));
    if (await sidecar.exists()) {
      await sidecar.delete();
    }
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
          deckRef: DeckPaths.fileName(deckPath),
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
    String deckPath,
  ) async {
    final File sidecar = File(statisticsSidecarPath(deckPath));
    if (!await sidecar.exists()) {
      return clearStatistics(deck);
    }
    final StatisticsFile statistics = decodeStatisticsJson(
      await sidecar.readAsString(),
    );
    return realignStatistics(deck: deck, statistics: statistics.perUnit)
        .statistics;
  }
}
