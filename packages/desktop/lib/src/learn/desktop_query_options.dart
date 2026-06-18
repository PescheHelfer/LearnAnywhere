import 'package:learn_anywhere_core/core.dart';

/// Desktop query options that affect learning sessions.
final class DesktopQueryOptions {
  /// Creates desktop query options.
  const DesktopQueryOptions({
    this.wrongInputCorrectable = true,
    this.completeInputRequired = true,
    this.caseSensitive = false,
    this.accentSensitive = false,
    this.showClock = false,
    this.timeLimitSeconds = 0,
    this.withAnswerInput = true,
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

  /// Whether to show a running clock during learning.
  final bool showClock;

  /// Warning time limit in seconds. Zero disables the warning.
  final int timeLimitSeconds;

  /// Whether the user types answers before reveal.
  final bool withAnswerInput;

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
    bool? showClock,
    int? timeLimitSeconds,
    bool? withAnswerInput,
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
      showClock: showClock ?? this.showClock,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      withAnswerInput: withAnswerInput ?? this.withAnswerInput,
      minimumAttemptsGuardEnabled:
          minimumAttemptsGuardEnabled ?? this.minimumAttemptsGuardEnabled,
      minAttempts: minAttempts ?? this.minAttempts,
      wrongAnswerCeilingEnabled:
          wrongAnswerCeilingEnabled ?? this.wrongAnswerCeilingEnabled,
      wrongAnswerCeiling: wrongAnswerCeiling ?? this.wrongAnswerCeiling,
    );
  }
}
