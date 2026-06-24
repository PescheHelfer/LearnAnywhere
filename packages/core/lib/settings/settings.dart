/// Pure Dart user-settings model, JSON serializer, and unit-range helpers.
library;

import 'dart:convert';
import 'dart:io';

import '../models/models.dart';

/// Settings file format marker.
const String settingsFormat = 'learn-anywhere/settings';

/// Current supported settings format version.
const int currentSettingsVersion = 1;

/// Conventional settings file name stored in the user-data directory.
const String settingsFileName = 'learn_anywhere.settings.json';

/// Persisted, framework-independent user settings.
///
/// Holds the advanced practice options, the practice-setup choices, and the
/// last loaded deck and mask paths. Start unit and end unit are intentionally
/// not part of this model: they are per-file and reset when a deck is loaded
/// (see [resetUnitRange] and [autoExpandEndUnit]).
final class LearnAnywhereSettings {
  /// Creates user settings.
  const LearnAnywhereSettings({
    this.wrongInputCorrectable = true,
    this.completeInputRequired = true,
    this.caseSensitive = false,
    this.accentSensitive = false,
    this.showClock = false,
    this.timeLimitSeconds = 0,
    this.minimumAttemptsGuardEnabled = false,
    this.minAttempts = 2,
    this.wrongAnswerCeilingEnabled = false,
    this.wrongAnswerCeiling = 10,
    this.mode = SessionMode.superQuery,
    this.direction = DirectionSelection.direction1,
    this.shuffle = false,
    this.requireTypedAnswers = true,
    this.superStatusThreshold = 0.4,
    this.lastDeckPath,
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

  /// Required hit rate for super-query mastery.
  final double superStatusThreshold;

  /// Last loaded `.vok` deck path, if any.
  final String? lastDeckPath;

  /// Last loaded `.inf` mask path, if any.
  final String? lastMaskPath;

  /// Returns a copy with selected fields changed.
  LearnAnywhereSettings copyWith({
    bool? wrongInputCorrectable,
    bool? completeInputRequired,
    bool? caseSensitive,
    bool? accentSensitive,
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
    double? superStatusThreshold,
    String? lastDeckPath,
    String? lastMaskPath,
    bool clearLastDeckPath = false,
    bool clearLastMaskPath = false,
  }) {
    return LearnAnywhereSettings(
      wrongInputCorrectable:
          wrongInputCorrectable ?? this.wrongInputCorrectable,
      completeInputRequired:
          completeInputRequired ?? this.completeInputRequired,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      accentSensitive: accentSensitive ?? this.accentSensitive,
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
      superStatusThreshold: superStatusThreshold ?? this.superStatusThreshold,
      lastDeckPath: clearLastDeckPath ? null : lastDeckPath ?? this.lastDeckPath,
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
        other.superStatusThreshold == superStatusThreshold &&
        other.lastDeckPath == lastDeckPath &&
        other.lastMaskPath == lastMaskPath;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    wrongInputCorrectable,
    completeInputRequired,
    caseSensitive,
    accentSensitive,
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
    superStatusThreshold,
    lastDeckPath,
    lastMaskPath,
  ]);
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
    'superStatusThreshold': settings.superStatusThreshold,
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
    superStatusThreshold: _double(
      json['superStatusThreshold'],
      defaults.superStatusThreshold,
    ),
    lastDeckPath: _nullableString(json['lastDeckPath']),
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
