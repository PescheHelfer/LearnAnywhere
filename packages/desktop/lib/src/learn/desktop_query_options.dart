import 'package:learn_anywhere_core/core.dart';

/// Desktop query options that affect learning sessions.
final class DesktopQueryOptions {
  /// Creates desktop query options.
  const DesktopQueryOptions({
    this.wrongInputCorrectable = true,
    this.completeInputRequired = true,
    this.caseSensitive = false,
    this.accentSensitive = false,
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

  /// Whether the learning screen shows the Unit time pill, which the time
  /// limit measures.
  final bool showUnitTime;

  /// Whether the learning screen shows the Sitting time pill.
  final bool showSittingTime;

  /// Whether the learning screen shows the Statistics time pill.
  final bool showStatisticsTime;

  /// Whether the learning screen shows the Total time pill.
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

  /// Answer evaluation options derived from these desktop preferences.
  AnswerEvaluationOptions get evaluationOptions {
    return AnswerEvaluationOptions(
      caseSensitive: caseSensitive,
      accentSensitive: accentSensitive,
      completeInputRequired: completeInputRequired,
    );
  }

  /// Wrong-answer ceiling options derived from these desktop preferences.
  WrongAnswerCeiling get wrongAnswerCeilingOptions {
    return WrongAnswerCeiling(
      enabled: wrongAnswerCeilingEnabled,
      value: wrongAnswerCeiling,
    );
  }

  /// Returns a copy with selected fields changed.
  DesktopQueryOptions copyWith({
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
  }) {
    return DesktopQueryOptions(
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
    );
  }
}
