/// Taking a **new version** of a shared deck without losing one's own flags.
///
/// Flags belong to one copy of a deck (ADR-0005, "flags belong to one copy of
/// a deck"). When the deck's author sends out a new version — typos fixed,
/// units added or moved — the learner takes its content, and their own flags
/// move across onto the units they belong to. The author's flags are not the
/// learner's verdict and are ignored.
library;

import 'dart:math';

import '../compatibility/mask_compatibility.dart';
import '../engine/engine.dart';
import '../models/models.dart';
import '../statistics/unit_identity.dart';

/// How alike two units' question and answer text must at least be
/// ([normalizedSimilarity]) for a unit the new version edited to keep its
/// flags.
const double kNewVersionSimilarityThreshold = 0.8;

/// Why a file cannot be taken as a new version of the open deck.
enum NewVersionRefusal {
  /// The file is on a different mask, so it is not a version of this deck.
  differentMask,

  /// Bringing the file onto the newer mask revision would drop or truncate
  /// its data, exactly as mask sync refuses to.
  wouldLoseData,
}

/// The outcome of [takeNewVersion].
sealed class NewVersionOutcome {
  const NewVersionOutcome();
}

/// The new version, taken: its content with the open deck's flags.
final class NewVersionTaken extends NewVersionOutcome {
  /// Creates a taken new version.
  const NewVersionTaken({
    required this.deck,
    required this.carried,
    required this.dropped,
  });

  /// The incoming deck's units, carrying only the open deck's flags, on the
  /// newer of the two mask revisions and with the incoming deck's last-edited
  /// date.
  final LearningDeck deck;

  /// How many flags found their unit in the new version, counting each
  /// manual or automatic flag in each direction on its own.
  final int carried;

  /// How many flags were lost because their unit no longer exists, counted
  /// like [carried].
  final int dropped;
}

/// The file could not be taken as a new version; nothing changes.
final class NewVersionRefused extends NewVersionOutcome {
  /// Creates a refusal.
  const NewVersionRefused(
    this.reason, {
    this.reasons = const <MaskBreakingReason>[],
  });

  /// Why the file was refused.
  final NewVersionRefusal reason;

  /// For [NewVersionRefusal.wouldLoseData], what the re-key would lose, as
  /// mask sync explains it; empty otherwise.
  final List<MaskBreakingReason> reasons;
}

/// Takes [incoming] as a new version of the [open] deck: its content, with
/// every flag it carries cleared and the open deck's flags copied onto the
/// matching units, each direction on its own.
///
/// Units are matched in two passes:
///
/// 1. **Exact**: each incoming unit takes the earliest unclaimed open unit
///    with the same [unitIdentityHash], so a unit that only moved keeps its
///    flags and identical units keep theirs in order.
/// 2. **Similar**: of the units still unmatched on both sides, pairs within
///    one category are formed greedily, most alike first, by the
///    [normalizedSimilarity] of their [unitIdentityText] — at least
///    [kNewVersionSimilarityThreshold]; of equally alike pairs, the one whose
///    positions are nearer. So a typo-fixed unit keeps its flags even with a
///    unit inserted before it or where it stood.
///
/// Open units left unmatched lose their flags ([NewVersionTaken.dropped]);
/// incoming units left unmatched start unflagged.
///
/// [incoming] must be on the open deck's mask (the same mask id). The result
/// is on the newer of the two revisions ([newestMask]), which the incoming
/// units are re-keyed onto as mask sync does — refused when that would lose
/// data. Pure: no files, no statistics.
NewVersionOutcome takeNewVersion({
  required LearningDeck open,
  required LearningDeck incoming,
}) {
  if (incoming.mask.maskId != open.mask.maskId) {
    return const NewVersionRefused(NewVersionRefusal.differentMask);
  }
  // Incoming first: of equal revisions, the new version's own mask needs no
  // re-key at all.
  final LearningMask reference = newestMask(<LearningMask>[
    incoming.mask,
    open.mask,
  ]);
  final MaskCompatibilityResult compat = checkMaskCompatibility(
    oldMask: incoming.mask,
    newMask: reference,
    units: incoming.units,
  );
  if (!compat.isCompatible) {
    return NewVersionRefused(
      NewVersionRefusal.wouldLoseData,
      reasons: compat.reasons,
    );
  }
  final List<LearningUnit> units = applyMaskToDeck(incoming, reference).units;
  final List<int?> sources = _matchUnits(reference, open.units, units);

  var carried = 0;
  final List<LearningUnit> flagged = <LearningUnit>[];
  for (var i = 0; i < units.length; i += 1) {
    final int? source = sources[i];
    final LearningUnit? mine = source == null ? null : open.units[source];
    carried += mine == null ? 0 : _flagCount(mine);
    flagged.add(
      units[i].copyWith(
        direction1Flags: mine?.direction1Flags ?? DifficultFlags.none,
        direction2Flags: mine?.direction2Flags ?? DifficultFlags.none,
      ),
    );
  }
  final int total = open.units.fold(
    0,
    (int sum, LearningUnit unit) => sum + _flagCount(unit),
  );
  return NewVersionTaken(
    deck: LearningDeck(
      mask: reference,
      units: List<LearningUnit>.unmodifiable(flagged),
      lastEdited: incoming.lastEdited,
    ),
    carried: carried,
    dropped: total - carried,
  );
}

/// An open-deck unit and an incoming one alike enough to be the same unit.
typedef _Pair = ({int open, int incoming, double similarity});

/// For each of [incoming], the index in [open] of the unit it matches, or
/// `null`; see [takeNewVersion] for the two passes. Both sides are judged
/// under [mask].
List<int?> _matchUnits(
  LearningMask mask,
  List<LearningUnit> open,
  List<LearningUnit> incoming,
) {
  final List<int?> sources = List<int?>.filled(incoming.length, null);
  final Set<int> claimed = <int>{};

  // Pass 1: identical units, first come first served in open-deck order.
  final Map<String, List<int>> openByHash = <String, List<int>>{};
  for (var o = 0; o < open.length; o += 1) {
    openByHash
        .putIfAbsent(unitIdentityHash(mask, open[o]), () => <int>[])
        .add(o);
  }
  for (var i = 0; i < incoming.length; i += 1) {
    final List<int>? candidates = openByHash[unitIdentityHash(
      mask,
      incoming[i],
    )];
    if (candidates != null && candidates.isNotEmpty) {
      final int o = candidates.removeAt(0);
      sources[i] = o;
      claimed.add(o);
    }
  }

  // Pass 2: edited units, most alike pairs first.
  final List<int> openLeft = <int>[
    for (var o = 0; o < open.length; o += 1)
      if (!claimed.contains(o)) o,
  ];
  final List<int> incomingLeft = <int>[
    for (var i = 0; i < incoming.length; i += 1)
      if (sources[i] == null) i,
  ];
  if (openLeft.isEmpty || incomingLeft.isEmpty) {
    return sources;
  }
  final Map<int, String> openText = <int, String>{
    for (final int o in openLeft) o: unitIdentityText(mask, open[o]),
  };
  final Map<int, String> incomingText = <int, String>{
    for (final int i in incomingLeft) i: unitIdentityText(mask, incoming[i]),
  };
  final List<_Pair> pairs = <_Pair>[];
  for (final int mine in openLeft) {
    for (final int theirs in incomingLeft) {
      if (open[mine].categoryId != incoming[theirs].categoryId) {
        continue;
      }
      final String myText = openText[mine]!;
      final String theirText = incomingText[theirs]!;
      // The edit distance is at least the difference in length, so a pair
      // whose lengths alone rule out the threshold needs no distance at all.
      final int longer = max(myText.length, theirText.length);
      if (longer > 0 &&
          min(myText.length, theirText.length) / longer <
              kNewVersionSimilarityThreshold) {
        continue;
      }
      final double similarity = normalizedSimilarity(myText, theirText);
      if (similarity >= kNewVersionSimilarityThreshold) {
        pairs.add((open: mine, incoming: theirs, similarity: similarity));
      }
    }
  }
  pairs.sort((_Pair a, _Pair b) {
    final int bySimilarity = b.similarity.compareTo(a.similarity);
    if (bySimilarity != 0) {
      return bySimilarity;
    }
    final int byDistance = (a.open - a.incoming).abs().compareTo(
      (b.open - b.incoming).abs(),
    );
    if (byDistance != 0) {
      return byDistance;
    }
    final int byIncoming = a.incoming.compareTo(b.incoming);
    return byIncoming != 0 ? byIncoming : a.open.compareTo(b.open);
  });
  for (final _Pair pair in pairs) {
    if (sources[pair.incoming] == null && !claimed.contains(pair.open)) {
      sources[pair.incoming] = pair.open;
      claimed.add(pair.open);
    }
  }
  return sources;
}

/// How many flags [unit] carries: each manual or automatic flag in each
/// direction counts once.
int _flagCount(LearningUnit unit) {
  var count = 0;
  for (final QueryDirection direction in QueryDirection.values) {
    final DifficultFlags flags = unit.flagsFor(direction);
    count += (flags.manual ? 1 : 0) + (flags.automatic ? 1 : 0);
  }
  return count;
}
