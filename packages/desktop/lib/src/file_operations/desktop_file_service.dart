import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;

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

  /// Opens a `.vok` deck with cleared statistics and no auto-save target.
  ///
  /// Auto-loading a timestamped `.sta` (with its "load these?" prompt) is
  /// driven by the app layer after this runs, since it needs the UI; see
  /// `_maybeAutoLoadStatistics` in main.dart. Outgoing statistics are
  /// auto-saved by the app layer before this runs.
  ///
  /// The deck's lifetime record comes along silently — no prompt: it is not a
  /// choice the learner makes, and a missing file simply means an empty
  /// record.
  Future<DesktopDocument> openDeck(DesktopDocument current, String path) async {
    final LearningDeck deck = decodeDeckJson(await File(path).readAsString());
    return DesktopDocument(
      deck: deck,
      statistics: clearStatistics(deck),
      allTime: await readAllTimeStatistics(deck, path),
      deckPath: path,
      autoLoadStatistics: current.autoLoadStatistics,
      autoSaveStatistics: current.autoSaveStatistics,
    );
  }

  /// Merges units from another `.vok` into the current in-memory deck.
  ///
  /// The incoming deck must describe the SAME mask (equal [LearningMask.maskId]);
  /// its embedded cache may be at a different revision. The incoming units are
  /// converted to the current in-memory mask via [applyMaskToDeck], but only
  /// when that conversion is lossless (per [checkMaskCompatibility]). A
  /// different maskId, or a conversion that would drop/truncate data, is
  /// refused with a user-facing message.
  Future<DesktopDocument> mergeDeck(
    DesktopDocument current,
    String path,
  ) async {
    final LearningDeck incoming = decodeDeckJson(
      await File(path).readAsString(),
    );
    if (incoming.mask.maskId != current.mask.maskId) {
      throw const FileOperationException(
        LearnAnywhereMessage.errorMergeMaskMismatch,
      );
    }
    final MaskCompatibilityResult compat = checkMaskCompatibility(
      oldMask: incoming.mask,
      newMask: current.mask,
      units: incoming.units,
    );
    if (!compat.isCompatible) {
      throw const FileOperationException(
        LearnAnywhereMessage.errorMergeWouldLoseData,
      );
    }
    // Re-key the incoming units onto the current mask (ids are stable, so this
    // is lossless given the compatibility check above).
    final LearningDeck convertedIncoming = applyMaskToDeck(
      incoming,
      current.mask,
    );
    final LearningDeck merged = current.deck.copyWith(
      units: List<LearningUnit>.unmodifiable(<LearningUnit>[
        ...current.deck.units,
        ...convertedIncoming.units,
      ]),
    );
    // Incoming units are appended at the end, so no existing index shifts and
    // current.levelStatistics stays valid without a remap — unlike an
    // editor insert/delete, merge never needs levelStatsAfterInsert/Delete.
    return current.copyWith(
      deck: merged,
      unitsEdited: true,
      statistics: resizeUnitStats(current.statistics, merged.units.length),
      // Re-indexed, never summed: merging adds units, and adding units must
      // not add attempts to a record that counts by live delta.
      allTime: current.allTime.resized(merged.units.length),
    );
  }

  /// Saves the current deck to [path] or its existing path.
  ///
  /// The deck itself always lands. Its lifetime record only follows it when the
  /// record is entitled to the target's file (see [writeAllTimeStatistics]);
  /// the reported [DeckSaveResult.allTime] is how the shell tells the learner
  /// that a save-as left another deck's history where it was.
  ///
  /// The returned document carries what became of the record, both ways: a
  /// write that landed earns it authority over the target, and one that was
  /// refused is remembered on it, so the sitting that carries on afterwards is
  /// not silently accumulating into nothing.
  Future<DeckSaveResult> saveDeck(
    DesktopDocument current, {
    String? path,
  }) async {
    final String? targetPath = path ?? current.deckPath;
    if (targetPath == null) {
      throw const FileOperationException(LearnAnywhereMessage.errorNoFilePath);
    }
    final DesktopDocument saved = (await writeDeck(
      current,
      targetPath,
    )).copyWith(deckPath: targetPath);
    await autoSaveStatistics(saved);
    // A deck that had never been saved accumulated its lifetime record in
    // memory; this is the moment it first has somewhere to go.
    final AllTimeWriteOutcome allTime = await writeAllTimeStatistics(saved);
    return DeckSaveResult(
      document: switch (allTime) {
        // A write that landed makes the record the one describing that file, so
        // the next answer keeps flowing into it — including after a save-as
        // onto a path that held no record of its own.
        AllTimeWriteOutcome.written => saved.copyWith(
            allTime: saved.allTime.adoptedAt(targetPath),
          ),
        // A refused write earns no authority — that is the whole policy — but
        // it is remembered, because every write after it is refused too and
        // the learner has to be able to see that the record has stopped.
        AllTimeWriteOutcome.refused => saved.copyWith(
            allTime: saved.allTime.refusedAt(targetPath),
          ),
        AllTimeWriteOutcome.noPath ||
        AllTimeWriteOutcome.nothingToWrite => saved,
      },
      allTime: allTime,
    );
  }

  /// Writes [current]'s deck, and nothing else, to [path].
  ///
  /// Every write of the open deck comes through here, because this is where
  /// "last edited" is decided: when [DesktopDocument.unitsEdited] says the
  /// units changed since the file was last read or written, the deck is dated
  /// now; otherwise it keeps the date it already had. The write is whole-file,
  /// so any edit still pending lands with it — and is dated — whatever the
  /// write was for. The returned document holds the deck as written, with
  /// nothing pending.
  Future<DesktopDocument> writeDeck(
    DesktopDocument current,
    String path,
  ) async {
    final LearningDeck deck = current.unitsEdited
        ? current.deck.copyWith(lastEdited: LocalTimestamp.of(DateTime.now()))
        : current.deck;
    await saveDeckSnapshot(deck, path);
    return current.copyWith(deck: deck, unitsEdited: false);
  }

  /// Saves [deck] to [path] without changing the current desktop document.
  Future<void> saveDeckSnapshot(LearningDeck deck, String path) async {
    await File(path).writeAsString(encodeDeckJson(deck));
  }

  /// When the deck at [deckPath] was last edited and last learned, for the
  /// workspace's recent-decks list.
  ///
  /// Last edited is the date stored in the deck file. Last learned is core's
  /// [lastLearned] over the files beside the deck, stat-ed here. Neither
  /// failing is an error: a deck that is gone, cannot be read or will not
  /// decode simply has no last-edited date, and a statistics file that cannot
  /// be stat-ed is left out, so the list can always be drawn.
  Future<DeckDates> deckDates(String deckPath) async {
    LocalTimestamp? lastEdited;
    try {
      lastEdited = decodeDeckJson(
        await File(deckPath).readAsString(),
      ).lastEdited;
    } on Object {
      lastEdited = null;
    }
    final String folder = p.dirname(deckPath);
    final List<String> fileNames = <String>[];
    try {
      await for (final FileSystemEntity entity in Directory(folder).list()) {
        if (entity is File) {
          fileNames.add(DeckPaths.fileName(entity.path));
        }
      }
    } on Object {
      // A folder that cannot be listed has no statistics to offer.
    }
    return DeckDates(
      lastEdited: lastEdited,
      lastLearned: lastLearned(
        deckPath: deckPath,
        statisticsFileNames: fileNames,
        timeOf: (String fileName) {
          try {
            return File(p.join(folder, fileName)).lastModifiedSync();
          } on Object {
            return null;
          }
        },
      ),
    );
  }

  /// Recursively loads every `.vok` deck under [folder] (including subfolders),
  /// keyed by absolute path.
  ///
  /// This backs the Lexicon file search: the user picks a folder and every
  /// deck beneath it is searched. Files that fail to decode are skipped rather
  /// than aborting the scan, so one malformed `.vok` cannot break a search.
  Future<Map<String, LearningDeck>> loadDecksInFolder(String folder) async {
    final Directory directory = Directory(folder);
    if (!await directory.exists()) {
      throw FileOperationException(
        LearnAnywhereMessage.errorSearchDirectoryMissing,
        detail: folder,
      );
    }
    final Map<String, LearningDeck> decks = <String, LearningDeck>{};
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !DeckPaths.hasExtension(entity.path, 'vok')) {
        continue;
      }
      try {
        decks[entity.path] = decodeDeckJson(await entity.readAsString());
      } on Object {
        continue;
      }
    }
    return decks;
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
      if (entity is! File || !DeckPaths.hasExtension(entity.path, 'inf')) {
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
  /// and the user opts to create one from the deck's embedded mask. When a
  /// file already exists at the conventional path — an unrelated `.inf` that
  /// happens to share the deck's base file name — a numbered-suffix path
  /// (`_2`, `_3`, ...) is used instead of overwriting it.
  Future<String> createLinkedMask(String deckPath, LearningMask mask) async {
    String infPath = DeckPaths.linkedMask(deckPath);
    var suffix = 2;
    while (await File(infPath).exists()) {
      infPath = DeckPaths.linkedMask(deckPath, suffix: suffix);
      suffix += 1;
    }
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
          !DeckPaths.hasExtension(entity.path, 'vok') ||
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
  /// [applyMaskToDeck]).
  ///
  /// Returns one result per path, in the order given, so a caller can report
  /// how many writes actually landed. A path that fails to decode or write is
  /// reported as a failure rather than silently skipped — but never aborts
  /// the rest of the batch.
  Future<List<MaskWriteResult>> applyMaskPropagation({
    required LearningMask newMask,
    required Iterable<String> deckPaths,
  }) async {
    final List<MaskWriteResult> results = <MaskWriteResult>[];
    for (final String path in deckPaths) {
      bool wrote = false;
      try {
        final LearningDeck deck = decodeDeckJson(await File(path).readAsString());
        final LearningDeck updated = applyMaskToDeck(deck, newMask);
        await File(path).writeAsString(encodeDeckJson(updated));
        wrote = true;
      } on Object {
        wrote = false;
      }
      results.add(MaskWriteResult(path: path, succeeded: wrote));
    }
    return results;
  }

  /// Recursively scans [root] for `.inf` and `.vok` files whose maskId equals
  /// [reference]'s, classifying each against [reference] for tier-2 sync
  /// (Step 7). Never merges: files that differ from [reference] at the same
  /// revision are flagged [MaskSyncStatus.differs] to be warned about, and
  /// decks that would lose data are flagged [MaskSyncStatus.wouldBreak].
  Future<List<MaskSyncEntry>> scanMaskCopies({
    required String root,
    required LearningMask reference,
  }) async {
    final Directory directory = Directory(root);
    final List<MaskSyncEntry> entries = <MaskSyncEntry>[];
    if (!await directory.exists()) {
      return entries;
    }
    final String referenceJson = encodeMaskJson(reference);
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      final bool isMask = DeckPaths.hasExtension(entity.path, 'inf');
      final bool isDeck = DeckPaths.hasExtension(entity.path, 'vok');
      if (!isMask && !isDeck) {
        continue;
      }
      try {
        final String content = await entity.readAsString();
        if (isMask) {
          final LearningMask mask = decodeMaskJson(content);
          if (mask.maskId != reference.maskId) {
            continue;
          }
          entries.add(
            MaskSyncEntry(
              path: entity.path,
              isMask: true,
              revision: mask.revision,
              status: _classifyMaskCopy(mask, reference, referenceJson),
              reasons: const <MaskBreakingReason>[],
              maskName: mask.name,
            ),
          );
        } else {
          final LearningDeck deck = decodeDeckJson(content);
          if (deck.mask.maskId != reference.maskId) {
            continue;
          }
          final MaskCompatibilityResult compat = checkMaskCompatibility(
            oldMask: deck.mask,
            newMask: reference,
            units: deck.units,
          );
          final MaskSyncStatus status;
          // A copy ahead of the reference must never be downgraded, even if
          // applying the reference would otherwise be compatible — checked
          // before compatibility so a stale reference can't overwrite it.
          if (deck.mask.revision > reference.revision) {
            status = MaskSyncStatus.newer;
          } else if (!compat.isCompatible) {
            status = MaskSyncStatus.wouldBreak;
          } else if (encodeMaskJson(deck.mask) == referenceJson) {
            status = MaskSyncStatus.upToDate;
          } else {
            status = MaskSyncStatus.willUpdate;
          }
          entries.add(
            MaskSyncEntry(
              path: entity.path,
              isMask: false,
              revision: deck.mask.revision,
              status: status,
              reasons: status == MaskSyncStatus.wouldBreak
                  ? compat.reasons
                  : const <MaskBreakingReason>[],
              maskName: deck.mask.name,
            ),
          );
        }
      } on Object {
        continue;
      }
    }
    entries.sort((MaskSyncEntry a, MaskSyncEntry b) => a.path.compareTo(b.path));
    return entries;
  }

  /// Overwrites each `.inf` in [paths] with [reference] and rewrites each
  /// `.vok`'s embedded cache via [applyMaskToDeck]. The caller passes only the
  /// paths the user selected (never breaking ones).
  ///
  /// Returns one result per path, in the order given, so a caller can report
  /// how many writes actually landed. A path that fails to decode or write
  /// (e.g. read-only, or removed between scan and apply) is reported as a
  /// failure rather than silently skipped — but never aborts the rest of the
  /// batch.
  Future<List<MaskWriteResult>> applyMaskSync({
    required LearningMask reference,
    required Iterable<String> paths,
  }) async {
    final List<MaskWriteResult> results = <MaskWriteResult>[];
    for (final String path in paths) {
      bool wrote = false;
      try {
        if (DeckPaths.hasExtension(path, 'inf')) {
          await File(path).writeAsString(encodeMaskJson(reference));
          wrote = true;
        } else if (DeckPaths.hasExtension(path, 'vok')) {
          final LearningDeck deck = decodeDeckJson(
            await File(path).readAsString(),
          );
          await File(
            path,
          ).writeAsString(encodeDeckJson(applyMaskToDeck(deck, reference)));
          wrote = true;
        }
      } on Object {
        wrote = false;
      }
      results.add(MaskWriteResult(path: path, succeeded: wrote));
    }
    return results;
  }

  MaskSyncStatus _classifyMaskCopy(
    LearningMask copy,
    LearningMask reference,
    String referenceJson,
  ) {
    if (encodeMaskJson(copy) == referenceJson) {
      return MaskSyncStatus.upToDate;
    }
    // A copy ahead of the reference must never be downgraded — this is what
    // let a stale in-memory reference classify a newer .inf as "will update"
    // and overwrite it with older data.
    if (copy.revision > reference.revision) {
      return MaskSyncStatus.newer;
    }
    // Same revision but different content is an unexpected divergence: warn,
    // never silently overwrite.
    if (copy.revision == reference.revision) {
      return MaskSyncStatus.differs;
    }
    return MaskSyncStatus.willUpdate;
  }

  /// Reads only the scope marker of the `.sta` at [path].
  ///
  /// The shell has to know WHICH record a file holds before it loads it: a
  /// deck's lifetime record may be loaded by hand, but only after the learner
  /// has been warned, and declining that warning has to leave the document
  /// untouched. Asking first — rather than loading and unwinding — is what
  /// keeps [loadStatistics] free of a decision it cannot make.
  Future<StatisticsScope> readStatisticsScope(String path) async {
    return decodeStatisticsJson(await File(path).readAsString()).scope;
  }

  /// Loads a `.sta` statistics file into the current document.
  ///
  /// The stored counters are realigned onto the deck by their per-unit hashes,
  /// so a deck edited outside the app keeps the history of every unit that is
  /// still there. The result reports how many units' statistics could not be
  /// carried over, which is the only thing worth telling the user about.
  Future<StatisticsLoadResult> loadStatistics(
    DesktopDocument current,
    String path,
  ) async {
    final StatisticsFile statistics = decodeStatisticsJson(
      await File(path).readAsString(),
    );
    final StatisticsRealignment realigned = realignStatistics(
      deck: current.deck,
      statistics: statistics.perUnit,
      levelStatistics:
          statistics.levelLearning?.perUnit ?? const <LevelUnitStats>[],
    );
    // A lifetime file loaded by hand becomes the working numbers, but never a
    // file this app writes back to. Both paths a save can land on are dropped
    // here, at the one place that knows the file's scope: the statistics path
    // is what a plain "Save stats" overwrites, and the auto-save target is
    // what every single answer overwrites. Letting go of the latter is also
    // what makes the next session mint a fresh timestamped file.
    final bool isAllTime = statistics.scope == StatisticsScope.allTime;
    return StatisticsLoadResult(
      scope: statistics.scope,
      document: current.copyWith(
        statistics: realigned.statistics,
        levelStatistics: realigned.levelStatistics,
        statisticsPath: path,
        clearStatisticsPath: isAllTime,
        clearAutoSaveTarget: isAllTime,
        lastSessionMode: statistics.lastSessionMode,
        clearLastSessionMode: statistics.lastSessionMode == null,
      ),
      // With no deck open there is nothing for the numbers to attach to, so
      // every entry is "unmatched" — but no unit changed, and saying so would
      // be nonsense. Loading stats before a deck has always discarded them.
      resetUnits: current.deck.units.isEmpty ? 0 : realigned.resetUnits,
    );
  }

  /// Saves current statistics to [path] and records it as the statistics path.
  Future<DesktopDocument> saveStatistics(
    DesktopDocument current,
    String path,
  ) async {
    await writeStatistics(current, path);
    return current.copyWith(statisticsPath: path);
  }

  /// Writes [document]'s statistics to [path] without changing the document.
  ///
  /// The low-level write shared by [saveStatistics], [autoSaveStatistics], and
  /// the per-answer session auto-save.
  Future<void> writeStatistics(DesktopDocument document, String path) async {
    await File(path).writeAsString(
      encodeStatisticsJson(
        StatisticsFile(
          deckRef: document.deckPath == null
              ? 'unsaved.vok'
              : DeckPaths.fileName(document.deckPath!),
          // Hashes are computed here, on every write, so the file always
          // identifies the deck exactly as it stands at this moment.
          perUnit: withUnitHashes(document.deck, document.statistics),
          levelLearning: _levelSection(document.levelStatistics),
          lastSessionMode: document.lastSessionMode,
        ),
      ),
    );
  }

  /// Clears all current statistics, writing the sitting being cleared out to
  /// its auto-save target first and then letting go of that target.
  ///
  /// Both halves matter. Without the flush the target still points at the
  /// finished sitting's timestamped file and the very next answer overwrites it
  /// with counters starting from zero — the one action for starting fresh would
  /// also be the action that destroys the history. Releasing the target is what
  /// sends the next session down the "no target yet" path in
  /// `_ensureAutoSaveTargetForSession`, which mints a file stamped with the time
  /// that session started rather than reusing the old stamp. The statistics path
  /// goes with it: the cleared numbers live in no file, so a plain "Save stats"
  /// must ask rather than silently overwrite the sitting just preserved.
  ///
  /// Nothing is written when auto-saving is off, when no target is set, or when
  /// no deck is open — the option governs whether a session file exists at all,
  /// and an empty deck has no numbers worth putting over a file that has some.
  ///
  /// The deck's lifetime record is deliberately left alone, in memory and on
  /// disk. Keeping the two genuinely independent is the whole point: starting
  /// over should not cost the learner the history.
  Future<DesktopDocument> clearCurrentStatistics(
    DesktopDocument current,
  ) async {
    if (current.deck.units.isNotEmpty) {
      await autoSaveStatistics(current);
    }
    return current.copyWith(
      statistics: clearStatistics(current.deck),
      levelStatistics: const <LevelUnitStats>[],
      // Nothing recorded means no mode to have recorded it in.
      clearLastSessionMode: true,
      clearStatisticsPath: true,
      clearAutoSaveTarget: true,
    );
  }

  /// Returns the lifetime statistics path `<deck>_alltime.sta` for [deckPath].
  ///
  /// Deliberately neither the bare `<deck>.sta` sidecar (which is the Android
  /// companion's live statistics file) nor anything
  /// [DeckPaths.timestampedStatisticsPattern] can match, so the lifetime record
  /// is never picked up as a session file to auto-load.
  String allTimeStatisticsPath(String deckPath) {
    return DeckPaths.allTimeStatistics(deckPath);
  }

  /// Reads the lifetime record beside [deckPath] and realigns it onto [deck].
  ///
  /// Silent by design and total: a missing, unreadable or malformed file all
  /// open as an empty record, and nothing interrupts the open. What the
  /// returned [AllTimeRecord] adds is WHICH of those happened — an absent file
  /// yields a record entitled to write there, an unreadable one a record that
  /// is not. Without that distinction a file locked for a second by a sync
  /// client would come back indistinguishable from a deck with no history, and
  /// the next answer would overwrite it with zeros.
  ///
  /// Realignment KEEPS the counters of a unit whose text changed (see
  /// [realignAllTimeStatistics]) and never adds to the totals.
  Future<AllTimeRecord> readAllTimeStatistics(
    LearningDeck deck,
    String deckPath,
  ) async {
    final File file = File(allTimeStatisticsPath(deckPath));
    if (!await file.exists()) {
      return AllTimeRecord.absent(deckPath);
    }
    try {
      return AllTimeRecord.loaded(
        realignAllTimeStatistics(
          deck: deck,
          allTime: AllTimeStatistics.fromFile(
            decodeStatisticsJson(await file.readAsString()),
          ),
        ),
        deckPath,
      );
    } on Object {
      return AllTimeRecord.unreadable(deckPath);
    }
  }

  /// Writes [document]'s lifetime record to `<deck>_alltime.sta`, unless the
  /// record is not entitled to replace what is already there.
  ///
  /// The authority rule is [AllTimeRecord.speaksFor]: a record may create a
  /// lifetime file anywhere, but may replace one only at the deck path it was
  /// read from. That covers three ways a learner's history used to be lost
  /// without a single answer being given — a read that failed for a moment, a
  /// merge or editor edit re-indexing a never-read record dense, and a save-as
  /// filing one deck's record under another deck's name.
  ///
  /// A no-op for a deck with no path yet — it keeps accumulating in memory
  /// until [saveDeck] gives it one. NOT governed by the auto-save-statistics
  /// option: that option decides whether a *resumable* session file exists,
  /// and tying the two would mean turning off resumable sessions silently
  /// stops the learner's progress record.
  ///
  /// Also a no-op for an EMPTY record: there is nothing to say yet, so no
  /// sidecar is created for a deck nobody has answered. A record genuinely
  /// reset to zero is dense, not empty, so it still writes — and, being a
  /// write that zeroes a file, it still has to be entitled to it. This test
  /// is a courtesy, not a guard: a deck-shape change re-indexes even an
  /// untouched record dense, so a deck only ever edited can end up with a
  /// zeroed sidecar. That costs nothing, because what protects an existing
  /// file is the authority rule above, never this one.
  ///
  /// [replaceUnreadFile] is the single deliberate exception, for the
  /// learner-confirmed clear of the lifetime record itself: that is the one
  /// action that means "zero this file whatever it holds", and it says so here
  /// rather than by pretending the record was read.
  Future<AllTimeWriteOutcome> writeAllTimeStatistics(
    DesktopDocument document, {
    bool replaceUnreadFile = false,
  }) async {
    final String? deckPath = document.deckPath;
    if (deckPath == null) {
      return AllTimeWriteOutcome.noPath;
    }
    if (document.allTime.isEmpty && !replaceUnreadFile) {
      return AllTimeWriteOutcome.nothingToWrite;
    }
    if (!replaceUnreadFile &&
        !document.allTime.speaksFor(deckPath) &&
        await File(allTimeStatisticsPath(deckPath)).exists()) {
      return AllTimeWriteOutcome.refused;
    }
    await File(allTimeStatisticsPath(deckPath)).writeAsString(
      encodeStatisticsJson(
        StatisticsFile(
          deckRef: DeckPaths.fileName(deckPath),
          scope: StatisticsScope.allTime,
          // Written dense and fully hashed, one row per deck unit, so the file
          // always describes the deck as it stands. A unit answered only above
          // free recall has ladder counters and no drill counters; without a
          // row of its own it would carry no identity, and the next open could
          // only realign it positionally.
          perUnit: withUnitHashes(
            document.deck,
            resizeUnitStats(document.allTime.perUnit, document.deck.units.length),
          ),
          levelLearning: _levelSection(document.allTime.perLevel),
        ),
      ),
    );
    return AllTimeWriteOutcome.written;
  }

  /// Auto-saves statistics to the active auto-save target, when auto-saving is
  /// enabled and a target is set. A no-op when auto-saving is suspended
  /// (no target) or turned off.
  Future<void> autoSaveStatistics(DesktopDocument document) async {
    final String? target = document.autoSaveTargetPath;
    if (!document.autoSaveStatistics || target == null) {
      return;
    }
    await writeStatistics(document, target);
  }

  /// Wraps [levelStatistics] in a [LevelLearningStats] section, or null when
  /// empty so the `.sta` file stays a v1 document with no Level-Learning data.
  LevelLearningStats? _levelSection(List<LevelUnitStats> levelStatistics) {
    if (levelStatistics.isEmpty) {
      return null;
    }
    return LevelLearningStats(perUnit: levelStatistics);
  }

  /// Returns the platform-appropriate path of the user settings file.
  ///
  /// On Windows this lives under `%APPDATA%`, elsewhere under
  /// `$XDG_CONFIG_HOME` or `$HOME/.config`, always inside a `LearnAnywhere`
  /// folder. The path is resolved here (in the app layer) and handed to the
  /// pure-Dart settings serializer in core.
  String settingsFilePath() {
    final Map<String, String> env = Platform.environment;
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
            ? p.join(home, '.config')
            : Directory.current.path;
      }
    }
    return p.join(base, 'LearnAnywhere', settingsFileName);
  }

  /// Builds the timestamped session `.sta` path for [deckPath] at [when],
  /// named `<deckname>_YYYYMMDD_HHMMSS.sta` in the deck's own folder (§3.7).
  String timestampedStatisticsPath(String deckPath, DateTime when) {
    return DeckPaths.timestampedStatistics(deckPath, when);
  }

  /// Finds every `<deckname>_YYYYMMDD_HHMMSS.sta` beside [deckPath], parses
  /// each embedded timestamp, and returns them newest-first.
  ///
  /// Files whose name does not match the timestamped convention (including a
  /// plain `<deckname>.sta`) are ignored, so only session files this app wrote
  /// are considered for auto-loading.
  Future<List<TimestampedStatistics>> findTimestampedStatistics(
    String deckPath,
  ) async {
    // `DeckPaths.directory` yields '.' for a bare file name, which `Directory`
    // already resolves to the working directory.
    final Directory directory = Directory(DeckPaths.directory(deckPath));
    if (!await directory.exists()) {
      return const <TimestampedStatistics>[];
    }
    final RegExp pattern = DeckPaths.timestampedStatisticsPattern(deckPath);
    final List<TimestampedStatistics> found = <TimestampedStatistics>[];
    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final RegExpMatch? match = pattern.firstMatch(
        DeckPaths.fileName(entity.path),
      );
      if (match == null) {
        continue;
      }
      found.add(
        TimestampedStatistics(
          path: entity.path,
          timestamp: DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
          ),
        ),
      );
    }
    found.sort(
      (TimestampedStatistics a, TimestampedStatistics b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    return found;
  }

  /// Deletes the oldest timestamped session `.sta` files beside [deckPath]
  /// beyond the newest [keep], so a long-running deck's folder doesn't fill
  /// up with one file per session.
  ///
  /// [protectPath] (typically the active auto-save target) is never deleted,
  /// even if it would otherwise fall outside the newest [keep]. `keep == 0`
  /// disables pruning entirely. Deletion failures for an individual file are
  /// swallowed — a locked or already-removed file must not abort the rest.
  Future<void> pruneTimestampedStatistics(
    String deckPath, {
    required int keep,
    String? protectPath,
  }) async {
    if (keep <= 0) {
      return;
    }
    final List<TimestampedStatistics> found = await findTimestampedStatistics(
      deckPath,
    );
    if (found.length <= keep) {
      return;
    }
    for (final TimestampedStatistics stats in found.skip(keep)) {
      if (stats.path == protectPath) {
        continue;
      }
      try {
        await File(stats.path).delete();
      } on Object {
        continue;
      }
    }
  }

  /// Summarizes how many of [unitCount] in-scope units a loaded [file] has
  /// already been queried on ("x out of y"), for the auto-load prompt.
  StatisticsCoverage statisticsCoverage(
    StatisticsFile file,
    int unitCount, {
    int? startIndex,
    int? endIndex,
  }) {
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: unitCount,
      statistics: file.perUnit,
      startIndex: startIndex,
      endIndex: endIndex,
    );
    return StatisticsCoverage(
      queriedUnits: summary.queriedUnits,
      totalUnits: summary.totalUnits,
    );
  }
}

/// What became of a write of the deck's lifetime record.
///
/// Only [refused] is worth telling the learner about, and no caller may drop
/// it on the floor. A save reports it in the status line at the moment it
/// happens; a per-answer write cannot interrupt a live session, so it marks
/// the record instead ([AllTimeRecord.refusedAt]) and the all-time statistics
/// say so for as long as the state lasts. What must never happen again is the
/// third option: nobody reading it, and the rest of the sitting accumulating
/// into a record that will never be written.
enum AllTimeWriteOutcome {
  /// The record was written to `<deck>_alltime.sta`.
  written,

  /// The deck has no path yet, so the record keeps accumulating in memory.
  noPath,

  /// Nothing has been read or answered, so there is nothing to write and no
  /// sidecar is created.
  nothingToWrite,

  /// A lifetime file is already there and this record is not entitled to
  /// replace it — it never read that file. The file is left exactly as it was.
  refused,
}

/// When a deck was last edited and last learned; `null` for either means it
/// has no record of that.
final class DeckDates {
  /// Creates a deck's dates.
  const DeckDates({this.lastEdited, this.lastLearned});

  /// The date stored in the deck file for its last unit edit.
  final LocalTimestamp? lastEdited;

  /// The newest modification time among the deck's statistics files.
  final DateTime? lastLearned;
}

/// A saved deck and what became of its lifetime record.
final class DeckSaveResult {
  /// Creates a deck save result.
  const DeckSaveResult({required this.document, required this.allTime});

  /// The document with its deck path (and, when the record was written, its
  /// authority over that path) applied.
  final DesktopDocument document;

  /// Whether the lifetime record followed the deck to the target path.
  final AllTimeWriteOutcome allTime;
}

/// A loaded `.sta` and what realigning it onto the current deck cost.
final class StatisticsLoadResult {
  /// Creates a statistics load result.
  const StatisticsLoadResult({
    required this.document,
    required this.resetUnits,
    this.scope = StatisticsScope.session,
  });

  /// The document with the loaded statistics applied.
  final DesktopDocument document;

  /// Which record the loaded file held.
  ///
  /// [StatisticsScope.allTime] means the learner picked a deck's lifetime
  /// record by hand — a supported way to drive a practice run from
  /// lifetime-worst units, but one the shell must never turn into a write
  /// target.
  final StatisticsScope scope;

  /// How many units' recorded statistics could not be carried over.
  ///
  /// Zero for the ordinary case of an unchanged deck; non-zero only when the
  /// deck was edited outside the app, which is worth reporting.
  final int resetUnits;
}

/// A timestamped session `.sta` discovered beside a deck, with its parsed time.
final class TimestampedStatistics {
  /// Creates a discovered timestamped statistics record.
  const TimestampedStatistics({required this.path, required this.timestamp});

  /// Absolute path of the `<deckname>_YYYYMMDD_HHMMSS.sta` file.
  final String path;

  /// The timestamp parsed from the file name.
  final DateTime timestamp;
}

/// How many in-scope units a loaded statistics file has been queried on.
final class StatisticsCoverage {
  /// Creates a coverage summary.
  const StatisticsCoverage({
    required this.queriedUnits,
    required this.totalUnits,
  });

  /// Units with at least one recorded attempt.
  final int queriedUnits;

  /// In-scope units considered.
  final int totalUnits;
}

/// The status of one `.inf`/`.vok` copy found during a tier-2 sync scan.
enum MaskSyncStatus {
  /// Already identical to the reference mask; nothing to do.
  upToDate,

  /// An older/compatible copy that will be brought up to the reference.
  willUpdate,

  /// A deck that would lose data if updated; excluded from sync.
  wouldBreak,

  /// A copy that differs from the reference at the SAME revision; warned about
  /// and never auto-merged.
  differs,

  /// A copy whose revision is AHEAD of the reference; excluded from sync so a
  /// stale reference (e.g. an open deck's un-reconciled embedded mask) can
  /// never overwrite it with older data.
  newer,
}

/// One `.inf` or `.vok` copy of a mask found during a cross-directory sync.
final class MaskSyncEntry {
  /// Creates a sync entry.
  const MaskSyncEntry({
    required this.path,
    required this.isMask,
    required this.revision,
    required this.status,
    required this.reasons,
    required this.maskName,
  });

  /// Absolute path of the found file.
  final String path;

  /// Whether this is a standalone `.inf` (true) or a deck `.vok` (false).
  final bool isMask;

  /// The copy's current embedded revision.
  final int revision;

  /// How this copy compares to the reference mask.
  final MaskSyncStatus status;

  /// Breaking reasons when [status] is [MaskSyncStatus.wouldBreak].
  final List<MaskBreakingReason> reasons;

  /// The copy's own mask name, so the review dialog can distinguish e.g. a
  /// differently-named/differently-languaged mask before it is overwritten.
  final String maskName;

  /// Whether the sync may update this copy (only older/compatible copies).
  bool get isUpdatable => status == MaskSyncStatus.willUpdate;
}

/// One path's outcome from [DesktopFileService.applyMaskPropagation] or
/// [DesktopFileService.applyMaskSync].
final class MaskWriteResult {
  /// Creates a write result.
  const MaskWriteResult({required this.path, required this.succeeded});

  /// The path this result is for, as given to [DesktopFileService
  /// .applyMaskPropagation] or [DesktopFileService.applyMaskSync].
  final String path;

  /// Whether the write landed on disk.
  final bool succeeded;
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

/// File operation failure carrying a localizable message id.
///
/// The message text is resolved by the UI layer from the i18n catalog (so
/// business code stays language-agnostic). When [messageId] contains a
/// `{detail}` placeholder, [detail] fills it.
final class FileOperationException implements Exception {
  /// Creates a file operation exception for [messageId].
  const FileOperationException(this.messageId, {this.detail});

  /// Catalog id of the user-facing failure message.
  final LearnAnywhereMessage messageId;

  /// Optional value substituted into the message's `{detail}` placeholder.
  final String? detail;

  @override
  String toString() => detail == null ? messageId.name : '${messageId.name}: $detail';
}
