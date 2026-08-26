/// Pure Dart user-settings model, JSON serializer, and unit-range helpers.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../engine/engine.dart';
import '../models/models.dart';

/// Settings file format marker.
const String settingsFormat = 'learn-anywhere/settings';

/// Current supported settings format version.
const int currentSettingsVersion = 1;

/// Conventional settings file name stored in the user-data directory.
const String settingsFileName = 'learn_anywhere.settings.json';

/// Number of Level-Learning levels (support level 3 down to free recall 0).
const int levelNameCount = 4;

/// Number of recently opened decks remembered for the workspace's quick list.
const int maxRecentDeckPaths = 3;

/// Returns [current] with [path] promoted to the front, capped at
/// [maxRecentDeckPaths] and holding each deck only once.
///
/// Paths are compared with [context] — the host's rules by default — so on
/// Windows two spellings of one deck that differ only in capitalisation take a
/// single slot, while on POSIX, where they name two different files, they take
/// one each.
List<String> withRecentDeckPath(
  List<String> current,
  String path, {
  p.Context? context,
}) {
  final p.Context ctx = context ?? p.context;
  final List<String> next = <String>[path];
  for (final String entry in current) {
    if (next.length >= maxRecentDeckPaths) {
      break;
    }
    if (!ctx.equals(entry, path)) {
      next.add(entry);
    }
  }
  return List<String>.unmodifiable(next);
}

/// Returns the entries of [recent] that are not the deck open at [currentPath].
///
/// The quick list only ever offers somewhere else to go, so the deck already
/// loaded is dropped from it. [context] compares paths as in
/// [withRecentDeckPath]; a null [currentPath] (nothing loaded) offers the whole
/// list.
List<String> recentDecksExcluding(
  List<String> recent,
  String? currentPath, {
  p.Context? context,
}) {
  if (currentPath == null) {
    return recent;
  }
  final p.Context ctx = context ?? p.context;
  return List<String>.unmodifiable(
    recent.where((String entry) => !ctx.equals(entry, currentPath)),
  );
}

/// Default English Level-Learning level names, ordered engine level 3 → 0.
const List<String> kDefaultLevelNamesEn = <String>[
  'Beginner',
  'Learner',
  'Almost There',
  'Champion',
];

/// Default German Level-Learning level names, ordered engine level 3 → 0.
const List<String> kDefaultLevelNamesDe = <String>[
  'Anfänger',
  'Lerner',
  'Fast geschafft',
  'Meister',
];

/// Alternative English space-launch level-name preset (UI offers it), 3 → 0.
const List<String> kSpaceLaunchLevelNamesEn = <String>[
  'Launchpad',
  'Lift-Off',
  'In Orbit',
  'Moon Landing',
];

/// Alternative German space-launch level-name preset (UI offers it), 3 → 0.
const List<String> kSpaceLaunchLevelNamesDe = <String>[
  'Startrampe',
  'Abflug',
  'Umlaufbahn',
  'Mondlandung',
];

/// Returns the custom name for engine [level] (`0..3`) from [names].
///
/// [names] is ordered engine level 3 → 0 (as stored in the settings'
/// `levelNamesEn`/`levelNamesDe`), so level 3 maps to `names[0]` and level 0
/// to `names[3]`. Out-of-range input yields an empty string rather than
/// throwing, so the UI never crashes on malformed data.
String levelNameFor(List<String> names, int level) {
  final int index = kMaxSupportLevel - level;
  if (index < 0 || index >= names.length) {
    return '';
  }
  return names[index];
}

/// Persisted, framework-independent user settings.
///
/// Holds the advanced practice options, the practice-setup choices, the
/// recently opened decks, and the last loaded mask path. Start unit and end
/// unit are intentionally not part of this model: they are per-file and reset
/// when a deck is loaded (see [resetUnitRange] and [autoExpandEndUnit]).
final class LearnAnywhereSettings {
  /// Creates user settings.
  const LearnAnywhereSettings({
    this.wrongInputCorrectable = true,
    this.completeInputRequired = true,
    this.caseSensitive = true,
    this.accentSensitive = true,
    this.almostEnabled = false,
    this.almostThreshold = kDefaultAlmostThreshold,
    this.showClock = false,
    this.timeLimitSeconds = 0,
    this.minimumAttemptsGuardEnabled = false,
    this.minAttempts = 2,
    this.wrongAnswerCeilingEnabled = false,
    this.wrongAnswerCeiling = 10,
    this.mode = SessionMode.superQuery,
    this.direction = DirectionSelection.direction1,
    this.shuffle = true,
    this.requireTypedAnswers = true,
    this.masteryThreshold = 0.4,
    this.entryLevelCap = kMaxSupportLevel,
    this.levelNamesEn = kDefaultLevelNamesEn,
    this.levelNamesDe = kDefaultLevelNamesDe,
    this.keepStatisticsVersions = 3,
    this.recentDeckPaths = const <String>[],
    this.lastMaskPath,
  });

  /// Whether a wrong answer can be rated as actually correct.
  final bool wrongInputCorrectable;

  /// Whether every non-empty solution field must be answered.
  final bool completeInputRequired;

  /// Whether case differences are significant.
  final bool caseSensitive;

  /// Whether accent differences are significant.
  final bool accentSensitive;

  /// Whether a near-miss answer is flagged as "Almost" (offering "Close
  /// enough") instead of a plain wrong.
  final bool almostEnabled;

  /// Similarity threshold (`0.0..1.0`) at or above which a non-exact answer is
  /// classified as "Almost".
  final double almostThreshold;

  /// Whether to show a running clock during learning.
  final bool showClock;

  /// Warning time limit in seconds. Zero disables the warning.
  final int timeLimitSeconds;

  /// Whether mastery requires a minimum number of attempts.
  final bool minimumAttemptsGuardEnabled;

  /// Minimum attempts required when the guard is enabled.
  final int minAttempts;

  /// Whether wrong answers stop being counted after a ceiling.
  final bool wrongAnswerCeilingEnabled;

  /// Maximum wrong answers to count per unit and direction.
  final int wrongAnswerCeiling;

  /// Selected session mode.
  final SessionMode mode;

  /// Selected direction scope.
  final DirectionSelection direction;

  /// Whether in-scope units are presented in random order.
  final bool shuffle;

  /// Whether the user types answers before reveal.
  final bool requireTypedAnswers;

  /// Required hit rate for mastery.
  final double masteryThreshold;

  /// Highest Level-Learning support level a seeded unit may start at (`0..3`).
  ///
  /// A higher number means more support, so this caps the *most* support a new
  /// unit gets. The default [kMaxSupportLevel] imposes no restriction.
  final int entryLevelCap;

  /// English Level-Learning level names, ordered engine level 3 → 0.
  final List<String> levelNamesEn;

  /// German Level-Learning level names, ordered engine level 3 → 0.
  final List<String> levelNamesDe;

  /// Number of timestamped session `.sta` files to keep per deck, oldest
  /// pruned first after each new one is written; `0` keeps every file.
  final int keepStatisticsVersions;

  /// Recently opened `.vok` deck paths, newest first, at most
  /// [maxRecentDeckPaths] and each deck only once.
  ///
  /// Maintained with [withRecentDeckPath]; the workspace offers it minus the
  /// deck currently open (see [recentDecksExcluding]).
  final List<String> recentDeckPaths;

  /// Last loaded `.vok` deck path, if any.
  ///
  /// Derived from [recentDeckPaths] rather than stored beside it, so the two
  /// can never disagree about which deck was opened last.
  String? get lastDeckPath =>
      recentDeckPaths.isEmpty ? null : recentDeckPaths.first;

  /// Last loaded `.inf` mask path, if any.
  final String? lastMaskPath;

  /// Returns a copy with selected fields changed.
  LearnAnywhereSettings copyWith({
    bool? wrongInputCorrectable,
    bool? completeInputRequired,
    bool? caseSensitive,
    bool? accentSensitive,
    bool? almostEnabled,
    double? almostThreshold,
    bool? showClock,
    int? timeLimitSeconds,
    bool? minimumAttemptsGuardEnabled,
    int? minAttempts,
    bool? wrongAnswerCeilingEnabled,
    int? wrongAnswerCeiling,
    SessionMode? mode,
    DirectionSelection? direction,
    bool? shuffle,
    bool? requireTypedAnswers,
    double? masteryThreshold,
    int? entryLevelCap,
    List<String>? levelNamesEn,
    List<String>? levelNamesDe,
    int? keepStatisticsVersions,
    List<String>? recentDeckPaths,
    String? lastMaskPath,
    bool clearLastMaskPath = false,
  }) {
    return LearnAnywhereSettings(
      wrongInputCorrectable:
          wrongInputCorrectable ?? this.wrongInputCorrectable,
      completeInputRequired:
          completeInputRequired ?? this.completeInputRequired,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      accentSensitive: accentSensitive ?? this.accentSensitive,
      almostEnabled: almostEnabled ?? this.almostEnabled,
      almostThreshold: almostThreshold ?? this.almostThreshold,
      showClock: showClock ?? this.showClock,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      minimumAttemptsGuardEnabled:
          minimumAttemptsGuardEnabled ?? this.minimumAttemptsGuardEnabled,
      minAttempts: minAttempts ?? this.minAttempts,
      wrongAnswerCeilingEnabled:
          wrongAnswerCeilingEnabled ?? this.wrongAnswerCeilingEnabled,
      wrongAnswerCeiling: wrongAnswerCeiling ?? this.wrongAnswerCeiling,
      mode: mode ?? this.mode,
      direction: direction ?? this.direction,
      shuffle: shuffle ?? this.shuffle,
      requireTypedAnswers: requireTypedAnswers ?? this.requireTypedAnswers,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      entryLevelCap: entryLevelCap ?? this.entryLevelCap,
      levelNamesEn: levelNamesEn ?? this.levelNamesEn,
      levelNamesDe: levelNamesDe ?? this.levelNamesDe,
      keepStatisticsVersions:
          keepStatisticsVersions ?? this.keepStatisticsVersions,
      recentDeckPaths: recentDeckPaths ?? this.recentDeckPaths,
      lastMaskPath: clearLastMaskPath ? null : lastMaskPath ?? this.lastMaskPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LearnAnywhereSettings &&
        other.wrongInputCorrectable == wrongInputCorrectable &&
        other.completeInputRequired == completeInputRequired &&
        other.caseSensitive == caseSensitive &&
        other.accentSensitive == accentSensitive &&
        other.almostEnabled == almostEnabled &&
        other.almostThreshold == almostThreshold &&
        other.showClock == showClock &&
        other.timeLimitSeconds == timeLimitSeconds &&
        other.minimumAttemptsGuardEnabled == minimumAttemptsGuardEnabled &&
        other.minAttempts == minAttempts &&
        other.wrongAnswerCeilingEnabled == wrongAnswerCeilingEnabled &&
        other.wrongAnswerCeiling == wrongAnswerCeiling &&
        other.mode == mode &&
        other.direction == direction &&
        other.shuffle == shuffle &&
        other.requireTypedAnswers == requireTypedAnswers &&
        other.masteryThreshold == masteryThreshold &&
        other.entryLevelCap == entryLevelCap &&
        _stringListEquals(other.levelNamesEn, levelNamesEn) &&
        _stringListEquals(other.levelNamesDe, levelNamesDe) &&
        other.keepStatisticsVersions == keepStatisticsVersions &&
        _stringListEquals(other.recentDeckPaths, recentDeckPaths) &&
        other.lastMaskPath == lastMaskPath;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    wrongInputCorrectable,
    completeInputRequired,
    caseSensitive,
    accentSensitive,
    almostEnabled,
    almostThreshold,
    showClock,
    timeLimitSeconds,
    minimumAttemptsGuardEnabled,
    minAttempts,
    wrongAnswerCeilingEnabled,
    wrongAnswerCeiling,
    mode,
    direction,
    shuffle,
    requireTypedAnswers,
    masteryThreshold,
    entryLevelCap,
    Object.hashAll(levelNamesEn),
    Object.hashAll(levelNamesDe),
    keepStatisticsVersions,
    Object.hashAll(recentDeckPaths),
    lastMaskPath,
  ]);
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Encodes [settings] as a settings JSON object.
Map<String, Object?> encodeSettings(LearnAnywhereSettings settings) {
  return <String, Object?>{
    'format': settingsFormat,
    'version': currentSettingsVersion,
    'wrongInputCorrectable': settings.wrongInputCorrectable,
    'completeInputRequired': settings.completeInputRequired,
    'caseSensitive': settings.caseSensitive,
    'accentSensitive': settings.accentSensitive,
    'almostEnabled': settings.almostEnabled,
    'almostThreshold': settings.almostThreshold,
    'showClock': settings.showClock,
    'timeLimitSeconds': settings.timeLimitSeconds,
    'minimumAttemptsGuardEnabled': settings.minimumAttemptsGuardEnabled,
    'minAttempts': settings.minAttempts,
    'wrongAnswerCeilingEnabled': settings.wrongAnswerCeilingEnabled,
    'wrongAnswerCeiling': settings.wrongAnswerCeiling,
    'mode': settings.mode.name,
    'direction': settings.direction.name,
    'shuffle': settings.shuffle,
    'requireTypedAnswers': settings.requireTypedAnswers,
    'masteryThreshold': settings.masteryThreshold,
    'entryLevelCap': settings.entryLevelCap,
    'levelNamesEn': settings.levelNamesEn,
    'levelNamesDe': settings.levelNamesDe,
    'keepStatisticsVersions': settings.keepStatisticsVersions,
    'recentDeckPaths': settings.recentDeckPaths,
    // Written alongside the list, though it is derived from it: a build that
    // predates the list — the Android companion until it catches up — reads
    // only this key, and would otherwise forget the deck on its next save.
    if (settings.lastDeckPath != null) 'lastDeckPath': settings.lastDeckPath,
    if (settings.lastMaskPath != null) 'lastMaskPath': settings.lastMaskPath,
  };
}

/// Decodes a settings JSON object, tolerating missing keys by using defaults.
LearnAnywhereSettings decodeSettings(Object? value) {
  if (value is! Map) {
    return const LearnAnywhereSettings();
  }
  final Map<Object?, Object?> json = value;
  const LearnAnywhereSettings defaults = LearnAnywhereSettings();
  return LearnAnywhereSettings(
    wrongInputCorrectable: _bool(
      json['wrongInputCorrectable'],
      defaults.wrongInputCorrectable,
    ),
    completeInputRequired: _bool(
      json['completeInputRequired'],
      defaults.completeInputRequired,
    ),
    caseSensitive: _bool(json['caseSensitive'], defaults.caseSensitive),
    accentSensitive: _bool(json['accentSensitive'], defaults.accentSensitive),
    almostEnabled: _bool(json['almostEnabled'], defaults.almostEnabled),
    almostThreshold: _double(
      json['almostThreshold'],
      defaults.almostThreshold,
    ),
    showClock: _bool(json['showClock'], defaults.showClock),
    timeLimitSeconds: _int(json['timeLimitSeconds'], defaults.timeLimitSeconds),
    minimumAttemptsGuardEnabled: _bool(
      json['minimumAttemptsGuardEnabled'],
      defaults.minimumAttemptsGuardEnabled,
    ),
    minAttempts: _int(json['minAttempts'], defaults.minAttempts),
    wrongAnswerCeilingEnabled: _bool(
      json['wrongAnswerCeilingEnabled'],
      defaults.wrongAnswerCeilingEnabled,
    ),
    wrongAnswerCeiling: _int(
      json['wrongAnswerCeiling'],
      defaults.wrongAnswerCeiling,
    ),
    mode: _enumByName(SessionMode.values, json['mode'], defaults.mode),
    direction: _enumByName(
      DirectionSelection.values,
      json['direction'],
      defaults.direction,
    ),
    shuffle: _bool(json['shuffle'], defaults.shuffle),
    requireTypedAnswers: _bool(
      json['requireTypedAnswers'],
      defaults.requireTypedAnswers,
    ),
    masteryThreshold: _double(
      json['masteryThreshold'],
      defaults.masteryThreshold,
    ),
    entryLevelCap: _clampLevel(
      _int(json['entryLevelCap'], defaults.entryLevelCap),
      defaults.entryLevelCap,
    ),
    levelNamesEn: _levelNames(json['levelNamesEn'], defaults.levelNamesEn),
    levelNamesDe: _levelNames(json['levelNamesDe'], defaults.levelNamesDe),
    keepStatisticsVersions: _int(
      json['keepStatisticsVersions'],
      defaults.keepStatisticsVersions,
    ),
    recentDeckPaths: _recentDeckPaths(
      json['recentDeckPaths'],
      _nullableString(json['lastDeckPath']),
    ),
    lastMaskPath: _nullableString(json['lastMaskPath']),
  );
}

/// Parses a settings JSON string into a [LearnAnywhereSettings].
LearnAnywhereSettings decodeSettingsJson(String source) {
  return decodeSettings(jsonDecode(source));
}

/// Encodes [settings] as a pretty UTF-8 JSON string.
String encodeSettingsJson(LearnAnywhereSettings settings) {
  return '${const JsonEncoder.withIndent('  ').convert(encodeSettings(settings))}\n';
}

/// Reads and parses the settings file at [path].
///
/// Returns default settings when the file does not exist or cannot be parsed,
/// so a corrupt or missing file never blocks startup.
Future<LearnAnywhereSettings> readSettingsFile(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return const LearnAnywhereSettings();
  }
  try {
    return decodeSettingsJson(await file.readAsString());
  } on Object {
    return const LearnAnywhereSettings();
  }
}

/// Writes [settings] to the UTF-8 JSON file at [path], creating parent
/// directories as needed.
Future<void> writeSettingsFile(String path, LearnAnywhereSettings settings) async {
  final File file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(encodeSettingsJson(settings));
}

/// Per-file unit range selection with manual-override tracking.
final class UnitRangeSelection {
  /// Creates a unit range selection.
  const UnitRangeSelection({
    required this.startUnit,
    required this.endUnit,
    this.endManuallySet = false,
  });

  /// One-based first unit.
  final int startUnit;

  /// One-based last unit.
  final int endUnit;

  /// Whether the user manually restricted the end unit.
  ///
  /// When `false`, [autoExpandEndUnit] may grow [endUnit] as units are added.
  final bool endManuallySet;

  /// Returns a copy with selected fields changed.
  UnitRangeSelection copyWith({
    int? startUnit,
    int? endUnit,
    bool? endManuallySet,
  }) {
    return UnitRangeSelection(
      startUnit: startUnit ?? this.startUnit,
      endUnit: endUnit ?? this.endUnit,
      endManuallySet: endManuallySet ?? this.endManuallySet,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UnitRangeSelection &&
        other.startUnit == startUnit &&
        other.endUnit == endUnit &&
        other.endManuallySet == endManuallySet;
  }

  @override
  int get hashCode => Object.hash(startUnit, endUnit, endManuallySet);
}

/// Returns a fresh range for a newly loaded file with [unitCount] units.
///
/// Start is reset to 1, end to the unit count, and the manual-override flag is
/// cleared so a subsequent unit addition can auto-expand the range.
UnitRangeSelection resetUnitRange(int unitCount) {
  final int count = unitCount < 1 ? 1 : unitCount;
  return UnitRangeSelection(startUnit: 1, endUnit: count);
}

/// Grows the end unit after units are added, unless the user overrode it.
///
/// Auto-expansion happens only when [UnitRangeSelection.endManuallySet] is
/// `false` and the previous end unit equalled [previousCount] (the user had not
/// restricted the range). Otherwise the range is returned unchanged.
UnitRangeSelection autoExpandEndUnit(
  UnitRangeSelection current, {
  required int previousCount,
  required int newCount,
}) {
  if (!current.endManuallySet &&
      current.endUnit == previousCount &&
      newCount > previousCount) {
    return current.copyWith(endUnit: newCount);
  }
  return current;
}

bool _bool(Object? value, bool fallback) => value is bool ? value : fallback;

int _int(Object? value, int fallback) => value is int ? value : fallback;

double _double(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

String? _nullableString(Object? value) => value is String ? value : null;

/// Clamps a decoded level into `0..3`, falling back to [fallback] on failure.
int _clampLevel(int value, int fallback) {
  if (value < kFreeRecallLevel || value > kMaxSupportLevel) {
    return fallback;
  }
  return value;
}

/// Decodes a level-name list, requiring exactly [levelNameCount] strings.
///
/// Anything else (missing key, wrong length, non-string entries) falls back to
/// [fallback] so a partial or corrupt file still yields a usable ladder.
List<String> _levelNames(Object? value, List<String> fallback) {
  if (value is! List || value.length != levelNameCount) {
    return fallback;
  }
  final List<String> names = <String>[];
  for (final Object? entry in value) {
    if (entry is! String) {
      return fallback;
    }
    names.add(entry);
  }
  return List<String>.unmodifiable(names);
}

/// Decodes the recent-deck list, seeding it from [lastDeckPath] when needed.
///
/// Anything that is not a list of strings yields an empty list rather than
/// failing the load, matching the rest of this decoder's tolerance. The stored
/// entries are re-normalized (deduplicated, capped, and led by [lastDeckPath]),
/// so a hand-edited file — or one last written by a build that only knows the
/// single last-deck key — still produces a well-formed list.
List<String> _recentDeckPaths(Object? value, String? lastDeckPath) {
  final List<String> stored = <String>[];
  if (value is List) {
    for (final Object? entry in value) {
      if (entry is! String) {
        stored.clear();
        break;
      }
      stored.add(entry);
    }
  }
  List<String> recent = <String>[];
  for (final String path in stored.reversed) {
    recent = withRecentDeckPath(recent, path);
  }
  if (lastDeckPath != null) {
    recent = withRecentDeckPath(recent, lastDeckPath);
  }
  return List<String>.unmodifiable(recent);
}

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final T candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return fallback;
}
