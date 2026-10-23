/// Pure Dart user-settings model, JSON serializer, and unit-range helpers.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../difficulty/difficult_units.dart';
import '../engine/engine.dart';
import '../models/models.dart';
import '../speech/speech_settings.dart';

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

/// Returns [ranges] with [range] stored for the deck at [path].
///
/// Any earlier entry for the same deck is dropped first, so a deck spelled two
/// ways on Windows still holds one range. Paths are compared with [context],
/// as in [withRecentDeckPath].
Map<String, UnitRangeSelection> withUnitRange(
  Map<String, UnitRangeSelection> ranges,
  String path,
  UnitRangeSelection range, {
  p.Context? context,
}) {
  final p.Context ctx = context ?? p.context;
  return Map<String, UnitRangeSelection>.unmodifiable(
    <String, UnitRangeSelection>{
      for (final MapEntry<String, UnitRangeSelection> entry in ranges.entries)
        if (!ctx.equals(entry.key, path)) entry.key: entry.value,
      path: range,
    },
  );
}

/// Returns the entries of [ranges] that belong to a deck on [recent], keyed
/// by the list's own spelling of its path.
///
/// This is what keeps the remembered ranges bounded: a deck that drops off
/// the recent list drops its range with it. Paths are compared with
/// [context], as in [withRecentDeckPath].
Map<String, UnitRangeSelection> unitRangesForRecentDecks(
  Map<String, UnitRangeSelection> ranges,
  List<String> recent, {
  p.Context? context,
}) {
  final p.Context ctx = context ?? p.context;
  final Map<String, UnitRangeSelection> kept = <String, UnitRangeSelection>{};
  for (final String path in recent) {
    final UnitRangeSelection? range = _unitRangeAt(ranges, path, ctx);
    if (range != null) {
      kept[path] = range;
    }
  }
  return Map<String, UnitRangeSelection>.unmodifiable(kept);
}

UnitRangeSelection? _unitRangeAt(
  Map<String, UnitRangeSelection> ranges,
  String path,
  p.Context context,
) {
  for (final MapEntry<String, UnitRangeSelection> entry in ranges.entries) {
    if (context.equals(entry.key, path)) {
      return entry.value;
    }
  }
  return null;
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
/// recently opened decks with each one's unit range, and the last loaded mask
/// path. The unit range is per deck: opening a deck restores its own (see
/// [unitRangeFor] and [restoreUnitRange]).
final class LearnAnywhereSettings {
  /// Creates user settings.
  const LearnAnywhereSettings({
    this.wrongInputCorrectable = true,
    this.completeInputRequired = true,
    this.caseSensitive = true,
    this.accentSensitive = true,
    this.almostEnabled = false,
    this.almostThreshold = kDefaultAlmostThreshold,
    this.showUnitTime = false,
    this.showSittingTime = false,
    this.showStatisticsTime = false,
    this.showTotalTime = false,
    this.timeLimitSeconds = 0,
    this.minimumAttemptsGuardEnabled = false,
    this.minAttempts = 2,
    this.wrongAnswerCeilingEnabled = false,
    this.wrongAnswerCeiling = 10,
    this.mode = SessionMode.superQuery,
    this.direction = DirectionSelection.direction1,
    this.shuffle = true,
    this.difficultOnly = false,
    this.requireTypedAnswers = true,
    this.masteryThreshold = 0.4,
    this.entryLevelCap = kMaxSupportLevel,
    this.levelNamesEn = kDefaultLevelNamesEn,
    this.levelNamesDe = kDefaultLevelNamesDe,
    this.keepStatisticsVersions = 3,
    this.detectDifficultUnits = true,
    this.detectionThresholds = DetectionThresholds.defaults,
    this.speech = const SpeechSettings(),
    this.recentDeckPaths = const <String>[],
    this.unitRanges = const <String, UnitRangeSelection>{},
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

  /// Whether the learning screen shows the **unit time** pill: how long the
  /// unit in front of the learner has been there, which the time limit
  /// measures.
  final bool showUnitTime;

  /// Whether the learning screen shows the **sitting time** pill.
  final bool showSittingTime;

  /// Whether the learning screen shows the **statistics time** pill.
  final bool showStatisticsTime;

  /// Whether the learning screen shows the **total time** pill.
  final bool showTotalTime;

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

  /// Whether a session asks only difficult units
  /// ([SessionParameters.difficultOnly]).
  final bool difficultOnly;

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

  /// Whether a learning session's end flags the units the learner keeps
  /// getting wrong ([addDetectedDifficult]).
  ///
  /// On by default. Off, nothing is detected and existing automatic flags
  /// stay as they are; it is per machine, like every setting here.
  final bool detectDifficultUnits;

  /// The thresholds the detection rule judges by, at session end and on
  /// recompute; kept within [DetectionThresholds]' ranges.
  final DetectionThresholds detectionThresholds;

  /// The machine's own speech choices: a voice per language, and the rate.
  ///
  /// Stored here rather than in the deck because a voice belongs to the
  /// computer it is installed on; see [SpeechSettings].
  final SpeechSettings speech;

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

  /// The unit range each deck was last left at, keyed by its path.
  ///
  /// Only decks on [recentDeckPaths] are written to disk (see
  /// [unitRangesForRecentDecks]); maintained with [withUnitRange] and read
  /// with [unitRangeFor].
  final Map<String, UnitRangeSelection> unitRanges;

  /// The remembered unit range of the deck at [path], or null when there is
  /// none. Paths are compared with [context], as in [withRecentDeckPath].
  UnitRangeSelection? unitRangeFor(String path, {p.Context? context}) =>
      _unitRangeAt(unitRanges, path, context ?? p.context);

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
    bool? showUnitTime,
    bool? showSittingTime,
    bool? showStatisticsTime,
    bool? showTotalTime,
    int? timeLimitSeconds,
    bool? minimumAttemptsGuardEnabled,
    int? minAttempts,
    bool? wrongAnswerCeilingEnabled,
    int? wrongAnswerCeiling,
    SessionMode? mode,
    DirectionSelection? direction,
    bool? shuffle,
    bool? difficultOnly,
    bool? requireTypedAnswers,
    double? masteryThreshold,
    int? entryLevelCap,
    List<String>? levelNamesEn,
    List<String>? levelNamesDe,
    int? keepStatisticsVersions,
    bool? detectDifficultUnits,
    DetectionThresholds? detectionThresholds,
    SpeechSettings? speech,
    List<String>? recentDeckPaths,
    Map<String, UnitRangeSelection>? unitRanges,
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
      showUnitTime: showUnitTime ?? this.showUnitTime,
      showSittingTime: showSittingTime ?? this.showSittingTime,
      showStatisticsTime: showStatisticsTime ?? this.showStatisticsTime,
      showTotalTime: showTotalTime ?? this.showTotalTime,
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
      difficultOnly: difficultOnly ?? this.difficultOnly,
      requireTypedAnswers: requireTypedAnswers ?? this.requireTypedAnswers,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      entryLevelCap: entryLevelCap ?? this.entryLevelCap,
      levelNamesEn: levelNamesEn ?? this.levelNamesEn,
      levelNamesDe: levelNamesDe ?? this.levelNamesDe,
      keepStatisticsVersions:
          keepStatisticsVersions ?? this.keepStatisticsVersions,
      detectDifficultUnits: detectDifficultUnits ?? this.detectDifficultUnits,
      detectionThresholds: detectionThresholds ?? this.detectionThresholds,
      speech: speech ?? this.speech,
      recentDeckPaths: recentDeckPaths ?? this.recentDeckPaths,
      unitRanges: unitRanges ?? this.unitRanges,
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
        other.showUnitTime == showUnitTime &&
        other.showSittingTime == showSittingTime &&
        other.showStatisticsTime == showStatisticsTime &&
        other.showTotalTime == showTotalTime &&
        other.timeLimitSeconds == timeLimitSeconds &&
        other.minimumAttemptsGuardEnabled == minimumAttemptsGuardEnabled &&
        other.minAttempts == minAttempts &&
        other.wrongAnswerCeilingEnabled == wrongAnswerCeilingEnabled &&
        other.wrongAnswerCeiling == wrongAnswerCeiling &&
        other.mode == mode &&
        other.direction == direction &&
        other.shuffle == shuffle &&
        other.difficultOnly == difficultOnly &&
        other.requireTypedAnswers == requireTypedAnswers &&
        other.masteryThreshold == masteryThreshold &&
        other.entryLevelCap == entryLevelCap &&
        _stringListEquals(other.levelNamesEn, levelNamesEn) &&
        _stringListEquals(other.levelNamesDe, levelNamesDe) &&
        other.keepStatisticsVersions == keepStatisticsVersions &&
        other.detectDifficultUnits == detectDifficultUnits &&
        other.detectionThresholds == detectionThresholds &&
        other.speech == speech &&
        _stringListEquals(other.recentDeckPaths, recentDeckPaths) &&
        _unitRangesEqual(other.unitRanges, unitRanges) &&
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
    showUnitTime,
    showSittingTime,
    showStatisticsTime,
    showTotalTime,
    timeLimitSeconds,
    minimumAttemptsGuardEnabled,
    minAttempts,
    wrongAnswerCeilingEnabled,
    wrongAnswerCeiling,
    mode,
    direction,
    shuffle,
    difficultOnly,
    requireTypedAnswers,
    masteryThreshold,
    entryLevelCap,
    Object.hashAll(levelNamesEn),
    Object.hashAll(levelNamesDe),
    keepStatisticsVersions,
    detectDifficultUnits,
    detectionThresholds,
    speech,
    Object.hashAll(recentDeckPaths),
    Object.hashAllUnordered(
      unitRanges.entries.map(
        (MapEntry<String, UnitRangeSelection> entry) =>
            Object.hash(entry.key, entry.value),
      ),
    ),
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

bool _unitRangesEqual(
  Map<String, UnitRangeSelection> a,
  Map<String, UnitRangeSelection> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<String, UnitRangeSelection> entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// Encodes [settings] as a settings JSON object.
///
/// Unit ranges are written only for the decks on the recent list (see
/// [unitRangesForRecentDecks]), so the file never fills up with decks the
/// learner has moved on from.
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
    'showUnitTime': settings.showUnitTime,
    'showSittingTime': settings.showSittingTime,
    'showStatisticsTime': settings.showStatisticsTime,
    'showTotalTime': settings.showTotalTime,
    'timeLimitSeconds': settings.timeLimitSeconds,
    'minimumAttemptsGuardEnabled': settings.minimumAttemptsGuardEnabled,
    'minAttempts': settings.minAttempts,
    'wrongAnswerCeilingEnabled': settings.wrongAnswerCeilingEnabled,
    'wrongAnswerCeiling': settings.wrongAnswerCeiling,
    'mode': settings.mode.name,
    'direction': settings.direction.name,
    'shuffle': settings.shuffle,
    'difficultOnly': settings.difficultOnly,
    'requireTypedAnswers': settings.requireTypedAnswers,
    'masteryThreshold': settings.masteryThreshold,
    'entryLevelCap': settings.entryLevelCap,
    'levelNamesEn': settings.levelNamesEn,
    'levelNamesDe': settings.levelNamesDe,
    'keepStatisticsVersions': settings.keepStatisticsVersions,
    'difficultDetection': <String, Object?>{
      'enabled': settings.detectDifficultUnits,
      'minWrong': settings.detectionThresholds.minWrong,
      'minWrongRatePercent': settings.detectionThresholds.minWrongRatePercent,
      'minAttemptsWithoutCorrect':
          settings.detectionThresholds.minAttemptsWithoutCorrect,
    },
    'speech': encodeSpeechSettings(settings.speech),
    'recentDeckPaths': settings.recentDeckPaths,
    // Written alongside the list, though it is derived from it: a build that
    // predates the list — the Android companion until it catches up — reads
    // only this key, and would otherwise forget the deck on its next save.
    if (settings.lastDeckPath != null) 'lastDeckPath': settings.lastDeckPath,
    'unitRanges': <String, Object?>{
      for (final MapEntry<String, UnitRangeSelection> entry
          in unitRangesForRecentDecks(
            settings.unitRanges,
            settings.recentDeckPaths,
          ).entries)
        entry.key: <String, Object?>{
          'startUnit': entry.value.startUnit,
          'endUnit': entry.value.endUnit,
          'endManuallySet': entry.value.endManuallySet,
        },
    },
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
  final Map<Object?, Object?> detection = _map(json['difficultDetection']);
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
    // A file from before the four time pills holds only the one clock flag,
    // and that clock is the unit time.
    showUnitTime: _bool(
      json['showUnitTime'],
      _bool(json['showClock'], defaults.showUnitTime),
    ),
    showSittingTime: _bool(json['showSittingTime'], defaults.showSittingTime),
    showStatisticsTime: _bool(
      json['showStatisticsTime'],
      defaults.showStatisticsTime,
    ),
    showTotalTime: _bool(json['showTotalTime'], defaults.showTotalTime),
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
    difficultOnly: _bool(json['difficultOnly'], defaults.difficultOnly),
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
    detectDifficultUnits: _bool(
      detection['enabled'],
      defaults.detectDifficultUnits,
    ),
    detectionThresholds: _detectionThresholds(detection),
    speech: decodeSpeechSettings(json['speech']),
    recentDeckPaths: _recentDeckPaths(
      json['recentDeckPaths'],
      _nullableString(json['lastDeckPath']),
    ),
    unitRanges: _unitRanges(json['unitRanges']),
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

/// Returns the full range of a deck with [unitCount] units: for a deck with
/// no remembered range (see [restoreUnitRange]), or one the learner widened
/// to every unit.
///
/// Start is reset to 1, end to the unit count, and the manual-override flag is
/// cleared so a subsequent unit addition can auto-expand the range.
UnitRangeSelection resetUnitRange(int unitCount) {
  final int count = unitCount < 1 ? 1 : unitCount;
  return UnitRangeSelection(startUnit: 1, endUnit: count);
}

/// Returns the range to start a just-opened deck of [unitCount] units at,
/// from the range it was [remembered] at, if any.
///
/// Nothing remembered, or a start past the last unit, gives the whole deck
/// ([resetUnitRange]). Otherwise an end set by hand is clamped to the deck,
/// and an end nobody set follows the deck to its last unit, just as
/// [autoExpandEndUnit] grows it within a run.
UnitRangeSelection restoreUnitRange(
  UnitRangeSelection? remembered,
  int unitCount,
) {
  final UnitRangeSelection full = resetUnitRange(unitCount);
  if (remembered == null || remembered.startUnit > full.endUnit) {
    return full;
  }
  return remembered.copyWith(
    startUnit: remembered.startUnit < 1 ? 1 : remembered.startUnit,
    endUnit: remembered.endManuallySet
        ? remembered.endUnit.clamp(1, full.endUnit).toInt()
        : full.endUnit,
  );
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

Map<Object?, Object?> _map(Object? value) =>
    value is Map ? value : const <Object?, Object?>{};

/// Decodes the detection thresholds, each one on its own: a value that is
/// missing, not a whole number, or outside its range falls back to its own
/// default, so one bad entry never resets the other two.
DetectionThresholds _detectionThresholds(Map<Object?, Object?> json) {
  const DetectionThresholds defaults = DetectionThresholds.defaults;
  int within(String key, int fallback, ThresholdRange range) {
    final int decoded = _int(json[key], fallback);
    return range.contains(decoded) ? decoded : fallback;
  }

  return DetectionThresholds(
    minWrong: within(
      'minWrong',
      defaults.minWrong,
      DetectionThresholds.minWrongRange,
    ),
    minWrongRatePercent: within(
      'minWrongRatePercent',
      defaults.minWrongRatePercent,
      DetectionThresholds.minWrongRatePercentRange,
    ),
    minAttemptsWithoutCorrect: within(
      'minAttemptsWithoutCorrect',
      defaults.minAttemptsWithoutCorrect,
      DetectionThresholds.minAttemptsWithoutCorrectRange,
    ),
  );
}

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

/// Decodes the per-deck unit ranges, each entry on its own: one that is not a
/// path mapped to a whole-number start and end of at least 1 is dropped, so
/// one bad entry never costs another deck its range.
Map<String, UnitRangeSelection> _unitRanges(Object? value) {
  final Map<String, UnitRangeSelection> ranges = <String, UnitRangeSelection>{};
  for (final MapEntry<Object?, Object?> entry in _map(value).entries) {
    final Object? path = entry.key;
    final Map<Object?, Object?> json = _map(entry.value);
    final Object? start = json['startUnit'];
    final Object? end = json['endUnit'];
    if (path is! String || start is! int || end is! int) {
      continue;
    }
    if (start < 1 || end < 1) {
      continue;
    }
    ranges[path] = UnitRangeSelection(
      startUnit: start,
      endUnit: end,
      endManuallySet: _bool(json['endManuallySet'], false),
    );
  }
  return Map<String, UnitRangeSelection>.unmodifiable(ranges);
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
