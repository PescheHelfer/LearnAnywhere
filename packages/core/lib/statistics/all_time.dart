/// A deck's lifetime record: the second, cumulative set of statistics.
///
/// Every deck quietly keeps two records. The **working** record is the one the
/// engine reads — it decides the super-query pool, mastery and the
/// Level-Learning ladder, and it is what "Clear current statistics" resets. The
/// **all-time** record, held here and written beside the deck as
/// `<deck>_alltime.sta` (`DeckPaths.allTimeStatistics`), accumulates everything
/// the learner has ever answered and is never consulted by the engine at all.
/// It exists to be looked at, which is what makes it safe: it can be
/// arbitrarily large and it changes nothing about what is asked.
///
/// **Accumulation is by live delta, never by merge.** Each recorded attempt
/// increments the working counter and the lifetime counter once, at the moment
/// it happens; loading, saving, merging decks and realigning never add to the
/// lifetime totals. Summing session files into the record instead would need a
/// per-file ledger of what has already been counted, or it would inflate the
/// totals on every re-save, reopen or crash recovery.
///
/// The delta is measured against the WORKING record — [AttemptDelta.between]
/// the counters before and after — so whatever that record declined to count,
/// this one declines too. That is how an attempt suppressed by the wrong-answer
/// ceiling is skipped in both records, and how an [AttemptRating.noCount]
/// rating stays a no-op in both. Re-deciding the ceiling against lifetime
/// wrongs would silently freeze the record forever once a unit passed it.
///
/// **Writing is by authority, never blind.** The record a deck holds in memory
/// travels as an [AllTimeRecord], which knows the file it was read from and so
/// which file it may replace; a record that never read a file may create one,
/// but never overwrite one. [AllTimeRecord] states that policy in full — it is
/// what stops a moment's unreadable file, or a merge that re-indexed an empty
/// record dense, from zeroing a lifetime of counters.
library;

import 'package:path/path.dart' as p;

import '../engine/engine.dart';
import '../models/models.dart';
import 'unit_identity.dart';

/// How much one recorded attempt added to a direction's counters.
final class AttemptDelta {
  /// Creates an attempt delta.
  const AttemptDelta({this.attempts = 0, this.correct = 0});

  /// The change [recordAttempt] made, measured between the working counters
  /// [before] and [after] it ran.
  ///
  /// A suppressed or uncounted attempt yields [none], which is exactly the
  /// point: the lifetime record is incremented by what the working record
  /// actually took, never by what was offered to it.
  factory AttemptDelta.between(DirectionStats before, DirectionStats after) {
    return AttemptDelta(
      attempts: after.attempts - before.attempts,
      correct: after.correct - before.correct,
    );
  }

  /// The delta of an attempt that was not counted.
  static const AttemptDelta none = AttemptDelta();

  /// Counted attempts added.
  final int attempts;

  /// Counted correct attempts added.
  final int correct;

  /// Whether nothing was counted.
  bool get isEmpty => attempts == 0 && correct == 0;

  /// Returns [stats] with this delta added.
  DirectionStats applyTo(DirectionStats stats) {
    return DirectionStats(
      attempts: stats.attempts + attempts,
      correct: stats.correct + correct,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttemptDelta &&
        other.attempts == attempts &&
        other.correct == correct;
  }

  @override
  int get hashCode => Object.hash(attempts, correct);
}

/// One attempt exactly as the working record took it.
///
/// Handed to [AllTimeStatistics.record] so the lifetime record is incremented
/// by the same amount and no other. [level] and [reachedLevel] are set only for
/// a Level-Learning attempt: [level] is the rung the answer was given at (read
/// BEFORE [recordLevelLearningAttempt] promotes), [reachedLevel] where the
/// ladder stands afterwards. A Level-Learning answer given at
/// [kFreeRecallLevel] also carries a [drill] delta, because free recall is the
/// same thing the drill modes test.
final class RecordedAttempt {
  /// Creates a recorded attempt.
  const RecordedAttempt({
    required this.unitIndex,
    required this.direction,
    this.drill = AttemptDelta.none,
    this.level,
    this.levelDelta = AttemptDelta.none,
    this.reachedLevel,
  });

  /// One-based unit index.
  final int unitIndex;

  /// Direction the attempt was answered in.
  final QueryDirection direction;

  /// What the mode-agnostic (drill) counters took, after the ceiling.
  final AttemptDelta drill;

  /// The Level-Learning rung the answer was given at, or null outside
  /// Level Learning.
  final int? level;

  /// What that rung's counters took.
  final AttemptDelta levelDelta;

  /// Where the ladder stands after any promotion; the lifetime record keeps
  /// this as the most recently reached level.
  final int? reachedLevel;

  /// Whether the working record counted nothing, so neither should this one.
  bool get isEmpty => drill.isEmpty && levelDelta.isEmpty;
}

/// A deck's lifetime statistics, in the same two sections a `.sta` file has.
final class AllTimeStatistics {
  /// Creates a lifetime record.
  const AllTimeStatistics({
    this.perUnit = const <UnitStats>[],
    this.perLevel = const <LevelUnitStats>[],
  });

  /// Reads the record out of a decoded `.sta`.
  ///
  /// The caller is responsible for having checked [StatisticsFile.scope]; this
  /// only unpacks the two sections.
  factory AllTimeStatistics.fromFile(StatisticsFile file) {
    return AllTimeStatistics(
      perUnit: file.perUnit,
      perLevel: file.levelLearning?.perUnit ?? const <LevelUnitStats>[],
    );
  }

  /// The record of a deck that has never been answered — and of a missing
  /// lifetime file, which simply means the same thing.
  static const AllTimeStatistics empty = AllTimeStatistics();

  /// Lifetime per-unit counters.
  final List<UnitStats> perUnit;

  /// Lifetime Level-Learning counters, each carrying the last level reached.
  final List<LevelUnitStats> perLevel;

  /// Whether nothing has ever been recorded.
  bool get isEmpty => perUnit.isEmpty && perLevel.isEmpty;

  /// Returns this record with [attempt] added.
  ///
  /// An attempt the working record did not count changes nothing here either
  /// ([RecordedAttempt.isEmpty]).
  AllTimeStatistics record(RecordedAttempt attempt) {
    if (attempt.isEmpty || attempt.unitIndex < 1) {
      return this;
    }
    return AllTimeStatistics(
      perUnit: attempt.drill.isEmpty ? perUnit : _recordDrill(attempt),
      perLevel: attempt.level == null || attempt.levelDelta.isEmpty
          ? perLevel
          : _recordLevel(attempt),
    );
  }

  /// Returns this record re-indexed to a deck of [unitCount] units.
  AllTimeStatistics resized(int unitCount) {
    return AllTimeStatistics(
      perUnit: resizeUnitStats(perUnit, unitCount),
      perLevel: resizeLevelStats(perLevel, unitCount),
    );
  }

  /// Returns this record shifted for a unit inserted at 1-based [position] in
  /// a deck that now holds [unitCount] units.
  AllTimeStatistics afterInsert(int position, int unitCount) {
    return AllTimeStatistics(
      perUnit: statsAfterInsert(perUnit, position, unitCount),
      perLevel: levelStatsAfterInsert(perLevel, position),
    );
  }

  /// Returns this record shifted for the unit at 1-based [position] being
  /// deleted from a deck that now holds [unitCount] units.
  ///
  /// The deleted unit's lifetime counters go with it: the record only ever
  /// describes units that exist, so the Unit list and the Overview agree.
  AllTimeStatistics afterDelete(int position, int unitCount) {
    return AllTimeStatistics(
      perUnit: statsAfterDelete(perUnit, position, unitCount),
      perLevel: levelStatsAfterDelete(perLevel, position),
    );
  }

  List<UnitStats> _recordDrill(RecordedAttempt attempt) {
    final List<UnitStats> units = List<UnitStats>.of(perUnit);
    final int at = units.indexWhere(
      (UnitStats stats) => stats.index == attempt.unitIndex,
    );
    final UnitStats current = at < 0
        ? UnitStats(index: attempt.unitIndex)
        : units[at];
    final UnitStats updated = current.withDirectionStats(
      attempt.direction,
      attempt.drill.applyTo(current.statsFor(attempt.direction)),
    );
    if (at < 0) {
      units
        ..add(updated)
        ..sort((UnitStats a, UnitStats b) => a.index.compareTo(b.index));
    } else {
      units[at] = updated;
    }
    return List<UnitStats>.unmodifiable(units);
  }

  List<LevelUnitStats> _recordLevel(RecordedAttempt attempt) {
    final int level = attempt.level!;
    final List<LevelUnitStats> entries = List<LevelUnitStats>.of(perLevel);
    final int at = entries.indexWhere(
      (LevelUnitStats stats) => stats.index == attempt.unitIndex,
    );
    // A lifetime ladder entry starts at full support; only its counters and
    // its last-reached level ever move, and both are set from the attempt.
    final LevelUnitStats current = at < 0
        ? LevelUnitStats(
            index: attempt.unitIndex,
            dir1: LevelDirectionStats.fresh(kMaxSupportLevel),
            dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
          )
        : entries[at];
    final LevelDirectionStats before = current.statsFor(attempt.direction);
    final LevelUnitStats updated = current.withDirectionStats(
      attempt.direction,
      before
          .withLevelStats(
            level,
            attempt.levelDelta.applyTo(
              before.levels[level] ?? const DirectionStats(),
            ),
          )
          // A level is a state, not a counter: summing "back at full support
          // after a fresh start" with last month's free recall is meaningless,
          // so the record keeps the level most recently reached instead.
          .withCurrentLevel(attempt.reachedLevel ?? level),
    );
    if (at < 0) {
      entries
        ..add(updated)
        ..sort(
          (LevelUnitStats a, LevelUnitStats b) => a.index.compareTo(b.index),
        );
    } else {
      entries[at] = updated;
    }
    return List<LevelUnitStats>.unmodifiable(entries);
  }
}

/// How a lifetime record in memory came to hold what it holds.
///
/// This is what decides whether it may REPLACE the file at a deck path — see
/// [AllTimeRecord.speaksFor]. Reading is total and silent, so the outcome has
/// to survive in the model: a file that was merely absent and a file that
/// could not be read both yield an empty record, and only the first of them
/// may be written over.
enum AllTimeOrigin {
  /// Never read from anywhere: a brand-new deck, a deck arriving through the
  /// Lexicon file search, or a record built in memory. It speaks for no path.
  unread,

  /// There was no lifetime file beside the deck when it was opened, which
  /// simply means the deck has no history yet. The record speaks for that
  /// path: writing there creates the file rather than replacing one.
  ///
  /// The observation is made once, when the deck opens, and holds for the
  /// sitting. A lifetime file appearing beside an already-open deck — a second
  /// instance of the app, a sync client restoring one — is therefore written
  /// over rather than noticed. Catching that would mean re-reading before every
  /// answer, or tracking each write back into the record, and the file this
  /// deck is writing is by then the one it created itself.
  absent,

  /// Read and decoded from the lifetime file beside the deck. The record
  /// speaks for that path.
  loaded,

  /// A lifetime file is there but could not be read or decoded — locked by a
  /// sync client, a backup or a virus scanner, or malformed. The record does
  /// NOT speak for that path: what is on disk may be a lifetime of counters
  /// this record knows nothing about.
  unreadable,
}

/// A lifetime record together with the file it is entitled to speak for.
///
/// **A record may only replace a lifetime file it was successfully read
/// from.** That is the whole write policy, and it exists because every other
/// guard is too weak: a record can become non-empty without a single answer
/// being given (any deck-shape change re-indexes it dense), so "is this record
/// empty?" cannot stand in for "is this record entitled to speak for this
/// file?".
///
/// Three consequences follow, and they are the point of the type:
///
/// - A **failed read is a refusal to write**, not a licence to zero. A file
///   locked for a second at the moment the deck opened stays intact, and the
///   learner is told the session will not reach it.
/// - **Creating a file is always allowed**; only replacing one is restricted.
///   A deck that has never been saved accumulates in memory and writes its
///   record the moment it first gets a path — that path holds nothing to
///   protect. Where it does hold something (a save-as onto a deck that has a
///   history of its own), the write is refused instead.
/// - The authority is **carried by the record**, so re-indexing it for a
///   merge, an editor insert or a resize cannot manufacture one. Every
///   operation here returns a record with the same [origin] and [deckPath].
///
/// The single deliberate exception is the learner-confirmed clear of the
/// lifetime record itself, which opts out explicitly at the call site.
///
/// A refusal is not the end of the matter, because the learner keeps answering
/// afterwards and those answers now reach nothing. So a refusal is remembered
/// ([refusedPath], [isRefused]) rather than merely returned: the policy is
/// unchanged, but the state it puts the sitting in is visible, and
/// [isUnreadableAt] separates its two causes so neither is reported as the
/// other.
final class AllTimeRecord {
  /// Creates a record with an explicit origin.
  const AllTimeRecord({
    this.statistics = AllTimeStatistics.empty,
    this.origin = AllTimeOrigin.unread,
    this.deckPath,
    this.refusedPath,
  });

  /// A record read from the lifetime file beside [deckPath].
  const AllTimeRecord.loaded(AllTimeStatistics statistics, String deckPath)
    : this(
        statistics: statistics,
        origin: AllTimeOrigin.loaded,
        deckPath: deckPath,
      );

  /// The empty record of a deck that has no lifetime file beside [deckPath].
  const AllTimeRecord.absent(String deckPath)
    : this(origin: AllTimeOrigin.absent, deckPath: deckPath);

  /// The empty record standing in for a lifetime file beside [deckPath] that
  /// could not be read.
  const AllTimeRecord.unreadable(String deckPath)
    : this(origin: AllTimeOrigin.unreadable, deckPath: deckPath);

  /// A record that has never been read from anywhere.
  static const AllTimeRecord unread = AllTimeRecord();

  /// The counters themselves.
  final AllTimeStatistics statistics;

  /// Where these counters came from.
  final AllTimeOrigin origin;

  /// The deck path this record was read for, if any.
  final String? deckPath;

  /// The deck path a write of this record was last REFUSED at, if any.
  ///
  /// Set by whoever attempted the write, because a refusal is a fact about the
  /// disk — a file exists at that path and this record never read it — that
  /// cannot be re-derived from the record alone. Carrying it is what turns the
  /// refusal from a silent one-way door into a state the learner can be shown:
  /// from here on every answer accumulates in memory only.
  ///
  /// Cleared by [adoptedAt], because a write that lands is exactly the cure.
  final String? refusedPath;

  /// Lifetime per-unit counters.
  List<UnitStats> get perUnit => statistics.perUnit;

  /// Lifetime Level-Learning counters.
  List<LevelUnitStats> get perLevel => statistics.perLevel;

  /// Whether nothing has ever been recorded here.
  bool get isEmpty => statistics.isEmpty;

  /// Whether THIS record's own lifetime file — the one beside [path] — was
  /// there and could not be read.
  ///
  /// Both halves of the question matter, and asking only about [origin] is the
  /// mix-up this exists to prevent. A record whose own file was unreadable at
  /// open is refused a write at its OWN path for that reason; the same record
  /// is refused a write at a DIFFERENT path (a save-as onto a deck with a
  /// history of its own) for the opposite one — there the file being spared is
  /// not this deck's at all. Reporting the second as "could not be read" tells
  /// the learner their history belongs to a deck it does not.
  bool isUnreadableAt(String path, {p.Context? context}) {
    final String? own = deckPath;
    return origin == AllTimeOrigin.unreadable &&
        own != null &&
        (context ?? p.context).equals(own, path);
  }

  /// Whether the last write of this record was refused, so the answers being
  /// given now reach no file at all.
  ///
  /// A state the learner is entitled to know they are in: the deck still
  /// saves, the current statistics still save, and the lifetime record alone
  /// has quietly stopped. Reopening the deck where it now lives is what ends
  /// it — that read hands the deck a record which legitimately speaks for the
  /// file beside it.
  bool get isRefused => refusedPath != null;

  /// Whether this record may replace an existing lifetime file for [path].
  ///
  /// True only for the deck path it was read for, and only when that read
  /// actually established what the file holds — an [AllTimeOrigin.absent]
  /// file counts, because "nothing there" is knowing what it holds.
  bool speaksFor(String path, {p.Context? context}) {
    final String? own = deckPath;
    if (own == null ||
        origin == AllTimeOrigin.unread ||
        origin == AllTimeOrigin.unreadable) {
      return false;
    }
    return (context ?? p.context).equals(own, path);
  }

  /// Returns this record with [attempt] added, keeping its authority.
  AllTimeRecord record(RecordedAttempt attempt) {
    return _with(statistics.record(attempt));
  }

  /// Returns this record re-indexed to a deck of [unitCount] units.
  AllTimeRecord resized(int unitCount) => _with(statistics.resized(unitCount));

  /// Returns this record shifted for a unit inserted at 1-based [position] in
  /// a deck that now holds [unitCount] units.
  AllTimeRecord afterInsert(int position, int unitCount) {
    return _with(statistics.afterInsert(position, unitCount));
  }

  /// Returns this record shifted for the unit at 1-based [position] being
  /// deleted from a deck that now holds [unitCount] units.
  AllTimeRecord afterDelete(int position, int unitCount) {
    return _with(statistics.afterDelete(position, unitCount));
  }

  /// Returns this record emptied, keeping its origin and its path.
  ///
  /// This is the learner-confirmed clear of the lifetime record: the counters
  /// go, the identity stays. Keeping the identity is what lets the answers
  /// given after the clear accumulate into the same file again — a record that
  /// forgot which file it came from would speak for none, and everything
  /// answered from here on would stay in memory.
  ///
  /// Nothing is decided here about whether the file may be replaced. The clear
  /// is the one write entitled to zero a file it never read, and it says so at
  /// its call site rather than by forging an origin here.
  AllTimeRecord cleared() => _with(AllTimeStatistics.empty);

  /// Returns this record as the one now describing the lifetime file at
  /// [path] — what a write that actually landed there earns it.
  ///
  /// Any earlier refusal is dropped with it: a record that has just written
  /// the file is no longer being refused anything.
  AllTimeRecord adoptedAt(String path) {
    return AllTimeRecord(
      statistics: statistics,
      origin: AllTimeOrigin.loaded,
      deckPath: path,
    );
  }

  /// Returns this record marked as having been refused a write at [path].
  ///
  /// Changes nothing about what the record may do — [speaksFor] is untouched
  /// and the write policy stays exactly as it was. All this carries is that
  /// the refusal happened, so the shell can stop being silent about it.
  AllTimeRecord refusedAt(String path) {
    return AllTimeRecord(
      statistics: statistics,
      origin: origin,
      deckPath: deckPath,
      refusedPath: path,
    );
  }

  AllTimeRecord _with(AllTimeStatistics updated) {
    return AllTimeRecord(
      statistics: updated,
      origin: origin,
      deckPath: deckPath,
      refusedPath: refusedPath,
    );
  }
}

/// Carries [allTime] over to wherever its units now sit in [deck].
///
/// Like [realignStatistics] this matches by [UnitStats.hash] first, so a unit
/// that moved keeps its counters. It then differs deliberately in one way: a
/// deck slot left unmatched keeps whatever the record holds AT ITS OWN INDEX,
/// provided no earlier match claimed it. That is the unit whose question or
/// answer text was edited in place — the working record resets it, because its
/// counters no longer describe that question, but a typo fix must not cost a
/// term its lifetime history, so here the counters are re-pointed and kept.
///
/// What is left over is a unit that is no longer in the deck at all, and it
/// drops out of the record with its counters.
///
/// A record carrying no hashes at all is realigned positionally, exactly as
/// [realignStatistics] does with an unhashed file: it says nothing about
/// identity, and guessing would be worse than the status quo.
AllTimeStatistics realignAllTimeStatistics({
  required LearningDeck deck,
  required AllTimeStatistics allTime,
}) {
  final int unitCount = deck.units.length;
  final List<String> hashes = deckUnitHashes(deck);
  if (!allTime.perUnit.any((UnitStats stats) => stats.hash != null)) {
    return AllTimeStatistics(
      perUnit: withUnitHashes(deck, resizeUnitStats(allTime.perUnit, unitCount)),
      perLevel: resizeLevelStats(allTime.perLevel, unitCount),
    );
  }

  final Map<String, List<UnitStats>> available = <String, List<UnitStats>>{};
  for (final UnitStats stats in allTime.perUnit) {
    final String? hash = stats.hash;
    if (hash == null) {
      continue;
    }
    available.putIfAbsent(hash, () => <UnitStats>[]).add(stats);
  }
  final Map<int, UnitStats> storedByIndex = <int, UnitStats>{
    for (final UnitStats stats in allTime.perUnit) stats.index: stats,
  };
  final Map<int, LevelUnitStats> levelByIndex = <int, LevelUnitStats>{
    for (final LevelUnitStats stats in allTime.perLevel) stats.index: stats,
  };
  // Every index the record says anything about. A unit answered only above
  // free recall has a ladder entry and NO drill entry, so keying the carry-over
  // on the drill section alone would drop its ladder history on the next open.
  final Set<int> storedIndices = <int>{
    ...storedByIndex.keys,
    ...levelByIndex.keys,
  };

  // Which stored index each deck slot inherits from, or null for a slot with
  // nothing to inherit.
  final List<int?> slots = List<int?>.filled(unitCount, null);
  final Set<int> claimed = <int>{};

  // Pass 1 — identity. A unit that only moved is found wherever it went.
  // Only the drill section carries hashes, so this is the only pass that can
  // use them.
  for (var slot = 0; slot < unitCount; slot += 1) {
    final List<UnitStats>? candidates = available[hashes[slot]];
    if (candidates == null || candidates.isEmpty) {
      continue;
    }
    final UnitStats source = candidates.removeAt(0);
    claimed.add(source.index);
    slots[slot] = source.index;
  }

  // Pass 2 — position. What is still unmatched at a slot whose stored index
  // nothing else took is the same unit with edited text, so it keeps its
  // counters under the new identity. A ladder-only entry reaches its unit here.
  for (var slot = 0; slot < unitCount; slot += 1) {
    final int index = slot + 1;
    if (slots[slot] != null ||
        !storedIndices.contains(index) ||
        claimed.contains(index)) {
      continue;
    }
    claimed.add(index);
    slots[slot] = index;
  }

  final List<UnitStats> perUnit = <UnitStats>[];
  final List<LevelUnitStats> perLevel = <LevelUnitStats>[];
  for (var slot = 0; slot < unitCount; slot += 1) {
    final int index = slot + 1;
    final int? source = slots[slot];
    final UnitStats? stored = source == null ? null : storedByIndex[source];
    perUnit.add(
      (stored ?? UnitStats(index: index)).withIdentity(
        index: index,
        hash: hashes[slot],
      ),
    );
    final LevelUnitStats? levels = source == null
        ? null
        : levelByIndex[source];
    if (levels != null) {
      perLevel.add(
        LevelUnitStats(index: index, dir1: levels.dir1, dir2: levels.dir2),
      );
    }
  }
  return AllTimeStatistics(
    perUnit: List<UnitStats>.unmodifiable(perUnit),
    perLevel: List<LevelUnitStats>.unmodifiable(perLevel),
  );
}
