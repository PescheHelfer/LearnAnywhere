import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'desktop_query_options.dart';

/// Callback used to persist live session counters in the shell.
typedef LearnSessionProgressChanged = void Function(int attempts, int correct);

/// Desktop learning session page.
final class LearnSessionPage extends StatefulWidget {
  /// Creates a desktop learning session page.
  const LearnSessionPage({
    required this.deck,
    required this.statistics,
    required this.options,
    required this.parameters,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.onParametersChanged,
    required this.onStatisticsChanged,
    required this.onSessionProgressChanged,
    required this.onOpenEditor,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

  /// Current query options.
  final DesktopQueryOptions options;

  /// Session parameters retained by the shell.
  final SessionParameters parameters;

  /// Counted attempts in the current in-memory session.
  final int sessionAttempts;

  /// Counted correct attempts in the current in-memory session.
  final int sessionCorrect;

  /// Called when setup parameters change.
  final ValueChanged<SessionParameters> onParametersChanged;

  /// Called when statistics are updated by a rating.
  final ValueChanged<List<UnitStats>> onStatisticsChanged;

  /// Called when live session counters change.
  final LearnSessionProgressChanged onSessionProgressChanged;

  /// Called when the user wants to interrupt and edit the deck.
  final VoidCallback onOpenEditor;

  @override
  State<LearnSessionPage> createState() => _LearnSessionPageState();
}

final class _LearnSessionPageState extends State<LearnSessionPage> {
  final Random _random = Random(1);
  final Set<SessionItem> _seenPracticeItems = <SessionItem>{};
  final Map<String, TextEditingController> _answerControllers =
      <String, TextEditingController>{};

  late SessionParameters _draftParameters;
  late int _startIndex;
  late int _endIndex;
  late int _thresholdPercent;

  SessionItem? _currentItem;
  AnswerEvaluation? _evaluation;
  AttemptRating _selectedRating = AttemptRating.noCount;
  Timer? _clockTimer;
  int _elapsedSeconds = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _draftParameters = _optionsApplied(widget.parameters);
    _startIndex = _draftParameters.startIndex ?? 1;
    _endIndex = _draftParameters.endIndex ?? widget.deck.units.length;
    _thresholdPercent = (_draftParameters.superStatusThreshold * 100).round();
    if (widget.options.showClock) {
      _startClock();
    }
  }

  @override
  void didUpdateWidget(LearnSessionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _draftParameters = _optionsApplied(_draftParameters);
    if (widget.options.showClock && _clockTimer == null) {
      _startClock();
    } else if (!widget.options.showClock && _clockTimer != null) {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
    if (_currentItem != null &&
        _currentItem!.unitIndex > widget.deck.units.length) {
      _currentItem = null;
      _completed = false;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    for (final TextEditingController controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.f1): const _LearnHelpIntent(),
        const SingleActivator(LogicalKeyboardKey.f3):
            const _LearnContinueIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const _LearnContinueIntent(),
        const SingleActivator(LogicalKeyboardKey.f10):
            const _LearnRevealIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _LearnSetupIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _LearnHelpIntent: CallbackAction<_LearnHelpIntent>(
            onInvoke: (_) {
              _showHelp();
              return null;
            },
          ),
          _LearnContinueIntent: CallbackAction<_LearnContinueIntent>(
            onInvoke: (_) {
              _continueShortcut();
              return null;
            },
          ),
          _LearnRevealIntent: CallbackAction<_LearnRevealIntent>(
            onInvoke: (_) {
              _reveal();
              return null;
            },
          ),
          _LearnSetupIntent: CallbackAction<_LearnSetupIntent>(
            onInvoke: (_) {
              setState(() {
                _currentItem = null;
                _completed = false;
              });
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (widget.deck.units.isEmpty) {
      return _EmptyLearnState(onOpenEditor: widget.onOpenEditor);
    }
    if (_completed) {
      return _CompletionView(onExtend: _backToSetup);
    }
    if (_currentItem == null) {
      return _SetupView(
        deck: widget.deck,
        parameters: _draftParameters,
        startIndex: _startIndex,
        endIndex: _endIndex,
        thresholdPercent: _thresholdPercent,
        onDirectionChanged: (DirectionSelection value) {
          setState(() => _draftParameters = _parametersWith(direction: value));
        },
        onModeChanged: (SessionMode value) {
          setState(() => _draftParameters = _parametersWith(mode: value));
        },
        onPracticeEachOnceChanged: (bool value) {
          setState(() {
            _draftParameters = _parametersWith(practiceEachOnce: value);
          });
        },
        onStartChanged: (int value) {
          setState(() => _startIndex = value);
        },
        onEndChanged: (int value) {
          setState(() => _endIndex = value);
        },
        onThresholdChanged: (int value) {
          setState(() => _thresholdPercent = value.clamp(1, 100).toInt());
        },
        onStartSession: _startSession,
      );
    }
    return _SessionView(
      deck: widget.deck,
      statistics: widget.statistics,
      options: widget.options,
      parameters: _draftParameters,
      item: _currentItem!,
      evaluation: _evaluation,
      selectedRating: _selectedRating,
      answerControllers: _answerControllers,
      elapsedSeconds: _elapsedSeconds,
      sessionAttempts: widget.sessionAttempts,
      sessionCorrect: widget.sessionCorrect,
      onReveal: _reveal,
      onRatingChanged: (AttemptRating value) {
        setState(() => _selectedRating = value);
      },
      onContinue: _continueAfterRating,
    );
  }

  void _startSession() {
    final int maxUnit = widget.deck.units.length;
    final int start = _startIndex.clamp(1, maxUnit).toInt();
    final int end = _endIndex.clamp(start, maxUnit).toInt();
    _draftParameters = _parametersWith(
      startIndex: start,
      endIndex: end,
      threshold: _thresholdPercent / 100,
    );
    widget.onParametersChanged(_draftParameters);
    _seenPracticeItems.clear();
    _selectNextItem();
  }

  void _backToSetup() {
    setState(() {
      _currentItem = null;
      _completed = false;
    });
  }

  void _selectNextItem() {
    final SessionItem? next = switch (_draftParameters.mode) {
      SessionMode.practice => pickPracticeItem(
        deck: widget.deck,
        parameters: _draftParameters,
        random: _random,
        seenItems: _seenPracticeItems,
      ),
      SessionMode.superQuery => _firstSuperQueryItem(),
    };
    if (next == null) {
      setState(() {
        _currentItem = null;
        _completed = true;
        _evaluation = null;
      });
      return;
    }
    if (_draftParameters.practiceEachOnce) {
      _seenPracticeItems.add(next);
    }
    _resetAnswerControllers(next);
    setState(() {
      _currentItem = next;
      _evaluation = null;
      _selectedRating = AttemptRating.noCount;
      _elapsedSeconds = 0;
    });
  }

  SessionItem? _firstSuperQueryItem() {
    final List<SessionItem> pool = activeSuperQueryPool(
      deck: widget.deck,
      statistics: widget.statistics,
      parameters: _draftParameters,
    );
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  void _resetAnswerControllers(SessionItem item) {
    for (final TextEditingController controller in _answerControllers.values) {
      controller.dispose();
    }
    _answerControllers.clear();
    if (!_draftParameters.withInput) {
      return;
    }
    final LearningUnit unit = widget.deck.units[item.unitIndex - 1];
    final Iterable<FieldDefinition> fields = answerFields(
      widget.deck,
      unit,
      item.direction,
    ).keys;
    for (final FieldDefinition field in fields) {
      _answerControllers[field.name] = TextEditingController();
    }
  }

  void _reveal() {
    final SessionItem? item = _currentItem;
    if (item == null || _evaluation != null) {
      return;
    }
    final LearningUnit unit = widget.deck.units[item.unitIndex - 1];
    final AnswerEvaluation? evaluation = _draftParameters.withInput
        ? evaluateAnswer(
            deck: widget.deck,
            unit: unit,
            direction: item.direction,
            enteredValues: <String, FieldValue>{
              for (final MapEntry<String, TextEditingController> entry
                  in _answerControllers.entries)
                entry.key: FieldValue.plain(entry.value.text),
            },
            options: widget.options.evaluationOptions,
          )
        : null;
    final AttemptRating defaultRating = _draftParameters.withInput
        ? (evaluation!.correct ? AttemptRating.correct : AttemptRating.wrong)
        : AttemptRating.correct;
    setState(() {
      _evaluation =
          evaluation ??
          const AnswerEvaluation(correct: true, fields: <FieldEvaluation>[]);
      _selectedRating = defaultRating;
    });
  }

  void _continueShortcut() {
    if (_currentItem == null) {
      _startSession();
    } else if (_evaluation == null) {
      _reveal();
    } else {
      _continueAfterRating();
    }
  }

  void _continueAfterRating() {
    final SessionItem? item = _currentItem;
    if (item == null || _evaluation == null) {
      return;
    }
    final List<UnitStats> updated = _recordRating(item, _selectedRating);
    widget.onStatisticsChanged(updated);
    final bool counted = _selectedRating != AttemptRating.noCount;
    final bool correct = _selectedRating == AttemptRating.correct;
    widget.onSessionProgressChanged(
      widget.sessionAttempts + (counted ? 1 : 0),
      widget.sessionCorrect + (correct ? 1 : 0),
    );
    _selectNextItem();
  }

  List<UnitStats> _recordRating(SessionItem item, AttemptRating rating) {
    final List<UnitStats> stats = _normalizedStats();
    final UnitStats current = stats[item.unitIndex - 1];
    final DirectionStats directionStats = current.statsFor(item.direction);
    final DirectionStats updatedDirection = recordAttempt(
      directionStats,
      rating,
      wrongAnswerCeiling: widget.options.wrongAnswerCeilingOptions,
    );
    stats[item.unitIndex - 1] = current.withDirectionStats(
      item.direction,
      updatedDirection,
    );
    return List<UnitStats>.unmodifiable(stats);
  }

  List<UnitStats> _normalizedStats() {
    final Map<int, UnitStats> byIndex = <int, UnitStats>{
      for (final UnitStats stats in widget.statistics) stats.index: stats,
    };
    return List<UnitStats>.generate(
      widget.deck.units.length,
      (int index) => byIndex[index + 1] ?? UnitStats(index: index + 1),
    );
  }

  SessionParameters _optionsApplied(SessionParameters parameters) {
    return SessionParameters(
      directionSelection: parameters.directionSelection,
      startIndex: parameters.startIndex,
      endIndex: parameters.endIndex,
      withInput: widget.options.withAnswerInput,
      mode: parameters.mode,
      practiceEachOnce: parameters.practiceEachOnce,
      superStatusThreshold: parameters.superStatusThreshold,
      minimumAttemptsGuardEnabled: widget.options.minimumAttemptsGuardEnabled,
      minAttempts: widget.options.minAttempts,
    );
  }

  SessionParameters _parametersWith({
    DirectionSelection? direction,
    int? startIndex,
    int? endIndex,
    bool? withInput,
    SessionMode? mode,
    bool? practiceEachOnce,
    double? threshold,
  }) {
    return SessionParameters(
      directionSelection: direction ?? _draftParameters.directionSelection,
      startIndex: startIndex ?? _draftParameters.startIndex,
      endIndex: endIndex ?? _draftParameters.endIndex,
      withInput: withInput ?? widget.options.withAnswerInput,
      mode: mode ?? _draftParameters.mode,
      practiceEachOnce: practiceEachOnce ?? _draftParameters.practiceEachOnce,
      superStatusThreshold: threshold ?? _draftParameters.superStatusThreshold,
      minimumAttemptsGuardEnabled: widget.options.minimumAttemptsGuardEnabled,
      minAttempts: widget.options.minAttempts,
    );
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _currentItem == null) {
        return;
      }
      setState(() => _elapsedSeconds += 1);
    });
  }

  void _showHelp() {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages.message(LearnAnywhereMessage.desktopHintBar)),
      ),
    );
  }
}

final class _EmptyLearnState extends StatelessWidget {
  const _EmptyLearnState({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.learnEmptyTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          Text(messages.message(LearnAnywhereMessage.learnEmptyBody)),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          FilledButton.icon(
            onPressed: onOpenEditor,
            icon: const Icon(Icons.edit),
            label: Text(messages.message(LearnAnywhereMessage.menuEdit)),
          ),
        ],
      ),
    );
  }
}

final class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.deck,
    required this.parameters,
    required this.startIndex,
    required this.endIndex,
    required this.thresholdPercent,
    required this.onDirectionChanged,
    required this.onModeChanged,
    required this.onPracticeEachOnceChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onThresholdChanged,
    required this.onStartSession,
  });

  final LearningDeck deck;
  final SessionParameters parameters;
  final int startIndex;
  final int endIndex;
  final int thresholdPercent;
  final ValueChanged<DirectionSelection> onDirectionChanged;
  final ValueChanged<SessionMode> onModeChanged;
  final ValueChanged<bool> onPracticeEachOnceChanged;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;
  final ValueChanged<int> onThresholdChanged;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return ListView(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.learnSetupTitle),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _DropdownRow<DirectionSelection>(
          label: messages.message(LearnAnywhereMessage.learnDirection),
          value: parameters.directionSelection,
          items: <DropdownMenuItem<DirectionSelection>>[
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.direction1,
              child: Text(deck.mask.direction1Label),
            ),
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.direction2,
              child: Text(deck.mask.direction2Label),
            ),
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.both,
              child: Text(
                messages.message(LearnAnywhereMessage.learnBothDirections),
              ),
            ),
          ],
          onChanged: onDirectionChanged,
        ),
        _DropdownRow<SessionMode>(
          label: messages.message(LearnAnywhereMessage.learnMode),
          value: parameters.mode,
          items: <DropdownMenuItem<SessionMode>>[
            DropdownMenuItem<SessionMode>(
              value: SessionMode.practice,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModePractice),
              ),
            ),
            DropdownMenuItem<SessionMode>(
              value: SessionMode.superQuery,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModeSuperQuery),
              ),
            ),
          ],
          onChanged: onModeChanged,
        ),
        _NumberRow(
          label: messages.message(LearnAnywhereMessage.learnRangeStart),
          value: startIndex,
          minimum: 1,
          onChanged: onStartChanged,
        ),
        _NumberRow(
          label: messages.message(LearnAnywhereMessage.learnRangeEnd),
          value: endIndex,
          minimum: 1,
          onChanged: onEndChanged,
        ),
        SwitchListTile(
          title: Text(
            messages.message(LearnAnywhereMessage.learnPracticeEachOnce),
          ),
          value: parameters.practiceEachOnce,
          onChanged: onPracticeEachOnceChanged,
        ),
        _NumberRow(
          label: messages.message(LearnAnywhereMessage.learnSuperThreshold),
          value: thresholdPercent,
          minimum: 1,
          maximum: 100,
          onChanged: onThresholdChanged,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onStartSession,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              messages.message(LearnAnywhereMessage.learnStartSession),
            ),
          ),
        ),
      ],
    );
  }
}

final class _SessionView extends StatelessWidget {
  const _SessionView({
    required this.deck,
    required this.statistics,
    required this.options,
    required this.parameters,
    required this.item,
    required this.evaluation,
    required this.selectedRating,
    required this.answerControllers,
    required this.elapsedSeconds,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.onReveal,
    required this.onRatingChanged,
    required this.onContinue,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final DesktopQueryOptions options;
  final SessionParameters parameters;
  final SessionItem item;
  final AnswerEvaluation? evaluation;
  final AttemptRating selectedRating;
  final Map<String, TextEditingController> answerControllers;
  final int elapsedSeconds;
  final int sessionAttempts;
  final int sessionCorrect;
  final VoidCallback onReveal;
  final ValueChanged<AttemptRating> onRatingChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = deck.units[item.unitIndex - 1];
    final CategoryDefinition category = deck.categoryForUnit(unit);
    return ListView(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      children: <Widget>[
        Text(
          _learnUnitHeader(
            messages,
            item.unitIndex,
            deck.units.length,
            category.name,
            _directionLabel(deck, item.direction),
          ),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _LiveStatsPanel(
          deck: deck,
          statistics: statistics,
          parameters: parameters,
          sessionAttempts: sessionAttempts,
          sessionCorrect: sessionCorrect,
          elapsedSeconds: options.showClock ? elapsedSeconds : null,
          timeLimitSeconds: options.timeLimitSeconds,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _FieldGroup(
          title: messages.message(LearnAnywhereMessage.learnPrompt),
          values: promptFields(deck, unit, item.direction),
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        if (parameters.withInput && evaluation == null)
          _AnswerInputGroup(
            values: answerFields(deck, unit, item.direction),
            controllers: answerControllers,
          ),
        if (evaluation == null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onReveal,
              icon: Icon(parameters.withInput ? Icons.check : Icons.visibility),
              label: Text(
                messages.message(
                  parameters.withInput
                      ? LearnAnywhereMessage.learnCheckAnswer
                      : LearnAnywhereMessage.learnReveal,
                ),
              ),
            ),
          )
        else
          _RevealPanel(
            deck: deck,
            unit: unit,
            direction: item.direction,
            evaluation: evaluation!,
            withInput: parameters.withInput,
            wrongInputCorrectable: options.wrongInputCorrectable,
            selectedRating: selectedRating,
            onRatingChanged: onRatingChanged,
            onContinue: onContinue,
          ),
      ],
    );
  }
}

final class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onExtend});

  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.superQueryCompleted),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          FilledButton.icon(
            onPressed: onExtend,
            icon: const Icon(Icons.tune),
            label: Text(
              messages.message(LearnAnywhereMessage.learnExtendSession),
            ),
          ),
        ],
      ),
    );
  }
}

final class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.title, required this.values});

  final String title;
  final Map<FieldDefinition, FieldValue> values;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries
            .map((MapEntry<FieldDefinition, FieldValue> entry) {
              return _FieldLine(field: entry.key, value: entry.value);
            })
            .toList(growable: false),
      ),
    );
  }
}

final class _AnswerInputGroup extends StatelessWidget {
  const _AnswerInputGroup({required this.values, required this.controllers});

  final Map<FieldDefinition, FieldValue> values;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return _Section(
      title: messages.message(LearnAnywhereMessage.learnYourAnswer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.keys
            .map((FieldDefinition field) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: LearnAnywhereTokens.gapSmall,
                ),
                child: SizedBox(
                  width: max(260, field.length * 12 + 32).toDouble(),
                  child: TextField(
                    key: ValueKey<String>('learn-answer-${field.name}'),
                    controller: controllers[field.name],
                    maxLines: 1,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(field.length),
                    ],
                    decoration: InputDecoration(labelText: field.name),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

final class _RevealPanel extends StatelessWidget {
  const _RevealPanel({
    required this.deck,
    required this.unit,
    required this.direction,
    required this.evaluation,
    required this.withInput,
    required this.wrongInputCorrectable,
    required this.selectedRating,
    required this.onRatingChanged,
    required this.onContinue,
  });

  final LearningDeck deck;
  final LearningUnit unit;
  final QueryDirection direction;
  final AnswerEvaluation evaluation;
  final bool withInput;
  final bool wrongInputCorrectable;
  final AttemptRating selectedRating;
  final ValueChanged<AttemptRating> onRatingChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Text(
          evaluation.correct
              ? messages.message(LearnAnywhereMessage.learnCorrectMessage)
              : messages.message(LearnAnywhereMessage.learnWrongMessage),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _FieldGroup(
          title: messages.message(LearnAnywhereMessage.learnSolution),
          values: answerFields(deck, unit, direction),
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _FieldGroup(
          title: messages.message(LearnAnywhereMessage.learnRemarks),
          values: remarkFields(deck, unit, direction),
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          children: _ratingOptions(messages)
              .map((MapEntry<AttemptRating, String> entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selectedRating == entry.key,
                  onSelected: (_) => onRatingChanged(entry.key),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: Text(messages.message(LearnAnywhereMessage.learnContinue)),
        ),
      ],
    );
  }

  List<MapEntry<AttemptRating, String>> _ratingOptions(
    LearnAnywhereLocalizations messages,
  ) {
    if (!withInput) {
      return <MapEntry<AttemptRating, String>>[
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingKnewIt),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.wrong,
          messages.message(LearnAnywhereMessage.learnRatingDidNotKnow),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.noCount,
          messages.message(LearnAnywhereMessage.learnRatingNoCount),
        ),
      ];
    }
    if (evaluation.correct) {
      return <MapEntry<AttemptRating, String>>[
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingCorrect),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.wrong,
          messages.message(LearnAnywhereMessage.learnRatingActuallyWrong),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.noCount,
          messages.message(LearnAnywhereMessage.learnRatingNoCount),
        ),
      ];
    }
    return <MapEntry<AttemptRating, String>>[
      MapEntry<AttemptRating, String>(
        AttemptRating.wrong,
        messages.message(LearnAnywhereMessage.learnRatingWrong),
      ),
      if (wrongInputCorrectable)
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingActuallyCorrect),
        ),
      MapEntry<AttemptRating, String>(
        AttemptRating.noCount,
        messages.message(LearnAnywhereMessage.learnRatingNoCount),
      ),
    ];
  }
}

final class _LiveStatsPanel extends StatelessWidget {
  const _LiveStatsPanel({
    required this.deck,
    required this.statistics,
    required this.parameters,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.elapsedSeconds,
    required this.timeLimitSeconds,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final SessionParameters parameters;
  final int sessionAttempts;
  final int sessionCorrect;
  final int? elapsedSeconds;
  final int timeLimitSeconds;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<SessionItem> pool = activeSuperQueryPool(
      deck: deck,
      statistics: statistics,
      parameters: parameters,
    );
    final int totalItems = _totalItems(deck, parameters);
    final int mastered = (totalItems - pool.length)
        .clamp(0, totalItems)
        .toInt();
    final int accuracy = sessionAttempts == 0
        ? 0
        : ((sessionCorrect / sessionAttempts) * 100).round();
    final bool timeWarning =
        elapsedSeconds != null &&
        timeLimitSeconds > 0 &&
        elapsedSeconds! >= timeLimitSeconds;
    return Wrap(
      spacing: LearnAnywhereTokens.gapSmall,
      runSpacing: LearnAnywhereTokens.gapSmall,
      children: <Widget>[
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: '$mastered/$totalItems',
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveRemaining),
          value: pool.length.toString(),
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveAccuracy),
          value: '$accuracy%',
        ),
        if (elapsedSeconds != null)
          _StatPill(
            label: 'Time',
            value: _clockText(elapsedSeconds!),
            warning: timeWarning,
          ),
      ],
    );
  }
}

final class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LearnAnywhereTokens.gapMedium,
          vertical: LearnAnywhereTokens.gapSmall,
        ),
        child: Text('$label: $value'),
      ),
    );
  }
}

final class _FieldLine extends StatelessWidget {
  const _FieldLine({required this.field, required this.value});

  final FieldDefinition field;
  final FieldValue value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 160, child: Text(field.name)),
          Expanded(
            child: LearnAnywhereRichText(
              value: value,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        child,
      ],
    );
  }
}

final class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: SizedBox(
        width: 360,
        child: DropdownButtonFormField<T>(
          decoration: InputDecoration(labelText: label),
          initialValue: value,
          items: items,
          onChanged: (T? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

final class _NumberRow extends StatefulWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.minimum,
    required this.onChanged,
    this.maximum,
  });

  final String label;
  final int value;
  final int minimum;
  final int? maximum;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

final class _NumberRowState extends State<_NumberRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String text = widget.value.toString();
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: SizedBox(
        width: 240,
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(labelText: widget.label),
          onChanged: (String value) {
            var parsed = int.tryParse(value) ?? widget.minimum;
            if (parsed < widget.minimum) {
              parsed = widget.minimum;
            }
            final int? maximum = widget.maximum;
            if (maximum != null && parsed > maximum) {
              parsed = maximum;
            }
            widget.onChanged(parsed);
          },
        ),
      ),
    );
  }
}

String _directionLabel(LearningDeck deck, QueryDirection direction) {
  return switch (direction) {
    QueryDirection.direction1 => deck.mask.direction1Label,
    QueryDirection.direction2 => deck.mask.direction2Label,
  };
}

String _learnUnitHeader(
  LearnAnywhereLocalizations messages,
  int index,
  int total,
  String category,
  String direction,
) {
  return messages
      .message(LearnAnywhereMessage.learnUnitHeader)
      .replaceAll('{index}', index.toString())
      .replaceAll('{total}', total.toString())
      .replaceAll('{category}', category)
      .replaceAll('{direction}', direction);
}

int _totalItems(LearningDeck deck, SessionParameters parameters) {
  final int start = parameters.startIndex ?? 1;
  final int end = parameters.endIndex ?? deck.units.length;
  final int unitCount = max(
    0,
    min(end, deck.units.length) - max(1, start) + 1,
  ).toInt();
  return switch (parameters.directionSelection) {
    DirectionSelection.both => unitCount * 2,
    DirectionSelection.direction1 || DirectionSelection.direction2 => unitCount,
  };
}

String _clockText(int seconds) {
  final int minutes = seconds ~/ 60;
  final int rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

final class _LearnHelpIntent extends Intent {
  const _LearnHelpIntent();
}

final class _LearnContinueIntent extends Intent {
  const _LearnContinueIntent();
}

final class _LearnRevealIntent extends Intent {
  const _LearnRevealIntent();
}

final class _LearnSetupIntent extends Intent {
  const _LearnSetupIntent();
}
