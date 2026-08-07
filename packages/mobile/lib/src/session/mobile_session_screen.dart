import 'dart:math';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_file_service.dart';

/// Mobile read-only learning session for one already-configured deck.
///
/// Two taps per card: prompt with "Show answer" reveals the solution,
/// remarks, and the Knew it / Didn't know / No count buttons — tapping any
/// of those both rates the card and advances to the next one. Statistics are
/// saved after every rated card.
final class MobileSessionScreen extends StatefulWidget {
  /// Creates the mobile learning session screen.
  const MobileSessionScreen({
    required this.document,
    required this.parameters,
    required this.wrongAnswerCeiling,
    required this.fileService,
    super.key,
  });

  /// Deck opened from the library, plus its loaded statistics.
  final MobileDeckDocument document;

  /// Session parameters chosen on the setup screen.
  final SessionParameters parameters;

  /// Wrong-answer ceiling from the guardrail settings.
  final WrongAnswerCeiling wrongAnswerCeiling;

  /// File service used to persist statistics.
  final MobileFileService fileService;

  @override
  State<MobileSessionScreen> createState() => _MobileSessionScreenState();
}

enum _MobileSessionStage { prompt, reveal, completed }

final class _MobileSessionScreenState extends State<MobileSessionScreen> {
  final Random _random = Random();

  // Presentation order for practice/onceThrough — respects
  // SessionParameters.shuffle, mirroring desktop's _nextOrderedItem. Drill
  // (superQuery) instead draws from activeSuperQueryPool every time, exactly
  // as on desktop, so shuffle does not apply to it on either shell.
  List<SessionItem> _order = const <SessionItem>[];
  int _orderPosition = 0;

  late MobileDeckDocument _document;
  _MobileSessionStage _stage = _MobileSessionStage.prompt;
  SessionItem? _currentItem;
  int _sessionAttempts = 0;
  int _sessionCorrect = 0;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    if (widget.parameters.mode != SessionMode.superQuery) {
      _order = sessionItemOrder(
        deck: _document.deck,
        parameters: widget.parameters,
        random: _random,
      );
    }
    _selectNextItem();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Scaffold(
      appBar: AppBar(title: Text(messages.appTitle)),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    final SessionItem? item = _currentItem;
    return Column(
      children: <Widget>[
        _MobileSessionHeader(
          document: _document,
          parameters: widget.parameters,
          attempts: _sessionAttempts,
          correct: _sessionCorrect,
        ),
        Expanded(
          child: switch (_stage) {
            _MobileSessionStage.prompt when item != null => _PromptView(
              document: _document,
              item: item,
              onShowAnswer: () => setState(() => _stage = _MobileSessionStage.reveal),
            ),
            _MobileSessionStage.reveal when item != null => _RevealView(
              document: _document,
              item: item,
              onRate: _rate,
            ),
            _ => _CompletedView(onExtend: _extendSession),
          },
        ),
      ],
    );
  }

  void _extendSession() {
    setState(() {
      if (widget.parameters.mode == SessionMode.onceThrough) {
        _order = sessionItemOrder(
          deck: _document.deck,
          parameters: widget.parameters,
          random: _random,
        );
        _orderPosition = 0;
      }
      _selectNextItem();
    });
  }

  Future<void> _rate(AttemptRating rating) async {
    final SessionItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final List<UnitStats> updated = _recordRating(_document, item, rating);
    final MobileDeckDocument updatedDocument = _document.copyWith(
      statistics: updated,
    );
    setState(() {
      _document = updatedDocument;
      if (rating != AttemptRating.noCount) {
        _sessionAttempts += 1;
      }
      if (rating == AttemptRating.correct) {
        _sessionCorrect += 1;
      }
      _selectNextItem();
    });
    await widget.fileService.saveStatistics(updatedDocument, updated);
  }

  List<UnitStats> _recordRating(
    MobileDeckDocument document,
    SessionItem item,
    AttemptRating rating,
  ) {
    final List<UnitStats> stats = _normalizedStats(document);
    final UnitStats current = stats[item.unitIndex - 1];
    stats[item.unitIndex - 1] = current.withDirectionStats(
      item.direction,
      recordAttempt(
        current.statsFor(item.direction),
        rating,
        wrongAnswerCeiling: widget.wrongAnswerCeiling,
      ),
    );
    return List<UnitStats>.unmodifiable(stats);
  }

  List<UnitStats> _normalizedStats(MobileDeckDocument document) {
    return resizeUnitStats(document.statistics, document.deck.units.length);
  }

  void _selectNextItem() {
    final SessionItem? next = widget.parameters.mode == SessionMode.superQuery
        ? pickAvoidingRepeat(
            activeSuperQueryPool(
              deck: _document.deck,
              statistics: _document.statistics,
              parameters: widget.parameters,
            ),
            _random,
            lastItem: _currentItem,
          )
        : _nextOrderedItem();
    if (next == null) {
      _currentItem = null;
      _stage = _MobileSessionStage.completed;
      return;
    }
    _currentItem = next;
    _stage = _MobileSessionStage.prompt;
  }

  /// Returns the next item from the precomputed presentation order.
  ///
  /// In once-through mode each item is served once, then `null` ends the
  /// session; in endless mode the order restarts — reshuffled when shuffle is
  /// on, so successive passes differ — and the first item of a new pass is
  /// never the one just shown (unless it is the only item). Mirrors desktop's
  /// `_nextOrderedItem`/`_avoidRepeatAtOrderStart`.
  SessionItem? _nextOrderedItem() {
    if (_order.isEmpty) {
      return null;
    }
    if (widget.parameters.mode == SessionMode.onceThrough) {
      if (_orderPosition >= _order.length) {
        return null;
      }
      return _order[_orderPosition++];
    }
    if (_orderPosition >= _order.length) {
      _orderPosition = 0;
      if (widget.parameters.shuffle) {
        _order = sessionItemOrder(
          deck: _document.deck,
          parameters: widget.parameters,
          random: _random,
        );
      }
      _avoidRepeatAtOrderStart();
    }
    return _order[_orderPosition++];
  }

  /// Swaps the upcoming first item away when it repeats the one just shown.
  ///
  /// Only relevant at a pass boundary; a single-item order must still repeat.
  void _avoidRepeatAtOrderStart() {
    final SessionItem? last = _currentItem;
    if (last == null || _order.length < 2 || _order.first != last) {
      return;
    }
    final List<SessionItem> reordered = _order.toList();
    final int swapWith = 1 + _random.nextInt(reordered.length - 1);
    reordered[0] = reordered[swapWith];
    reordered[swapWith] = last;
    _order = List<SessionItem>.unmodifiable(reordered);
  }
}

final class _MobileSessionHeader extends StatelessWidget {
  const _MobileSessionHeader({
    required this.document,
    required this.parameters,
    required this.attempts,
    required this.correct,
  });

  final MobileDeckDocument document;
  final SessionParameters parameters;
  final int attempts;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final int total = _totalItems(document.deck, parameters);
    final int remaining = activeSuperQueryPool(
      deck: document.deck,
      statistics: document.statistics,
      parameters: parameters,
    ).length;
    final int mastered = max(0, total - remaining);
    final int accuracy = attempts == 0
        ? 0
        : ((correct / attempts) * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LearnAnywhereTokens.gapMedium,
        LearnAnywhereTokens.gapSmall,
        LearnAnywhereTokens.gapMedium,
        LearnAnywhereTokens.gapSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  document.deck.mask.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${messages.message(LearnAnywhereMessage.mobileUnits)}: '
                '${document.deck.units.length}',
              ),
            ],
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          LinearProgressIndicator(
            value: total == 0 ? 0 : mastered / total,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          Wrap(
            spacing: LearnAnywhereTokens.gapSmall,
            runSpacing: LearnAnywhereTokens.gapSmall,
            children: <Widget>[
              _InfoChip(
                label: messages.message(LearnAnywhereMessage.learnLiveMastered),
                value: mastered.toString(),
              ),
              _InfoChip(
                label: messages.message(
                  LearnAnywhereMessage.learnLiveRemaining,
                ),
                value: remaining.toString(),
              ),
              _InfoChip(
                label: messages.message(LearnAnywhereMessage.learnLiveAccuracy),
                value: '$accuracy%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LearnAnywhereTokens.gapSmall,
          vertical: 6,
        ),
        child: Text('$label: $value'),
      ),
    );
  }
}

final class _PromptView extends StatelessWidget {
  const _PromptView({
    required this.document,
    required this.item,
    required this.onShowAnswer,
  });

  final MobileDeckDocument document;
  final SessionItem item;
  final VoidCallback onShowAnswer;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    return _UnitScaffold(
      document: document,
      item: item,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
                child: _FieldGroup(
                  title: messages.message(LearnAnywhereMessage.learnPrompt),
                  fields: promptFields(document.deck, unit, item.direction),
                  large: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onShowAnswer,
                icon: const Icon(Icons.visibility),
                label: Text(
                  messages.message(LearnAnywhereMessage.mobileShowAnswer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.document,
    required this.item,
    required this.onRate,
  });

  final MobileDeckDocument document;
  final SessionItem item;
  final ValueChanged<AttemptRating> onRate;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    return _UnitScaffold(
      document: document,
      item: item,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
              children: <Widget>[
                _FieldGroup(
                  title: messages.message(LearnAnywhereMessage.learnSolution),
                  fields: answerFields(document.deck, unit, item.direction),
                  highlight: true,
                ),
                const SizedBox(height: LearnAnywhereTokens.gapLarge),
                _FieldGroup(
                  title: messages.message(LearnAnywhereMessage.learnRemarks),
                  fields: remarkFields(document.deck, unit, item.direction),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: <Widget>[
                FilledButton(
                  onPressed: () => onRate(AttemptRating.correct),
                  child: Text(
                    messages.message(LearnAnywhereMessage.learnRatingKnewIt),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => onRate(AttemptRating.wrong),
                  child: Text(
                    messages.message(
                      LearnAnywhereMessage.learnRatingDidNotKnow,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => onRate(AttemptRating.noCount),
                  child: Text(
                    messages.message(LearnAnywhereMessage.learnRatingNoCount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.onExtend});

  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.emoji_events_outlined, size: 56),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              messages.message(LearnAnywhereMessage.superQueryCompleted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            FilledButton(
              onPressed: onExtend,
              child: Text(
                messages.message(LearnAnywhereMessage.learnExtendSession),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _UnitScaffold extends StatelessWidget {
  const _UnitScaffold({
    required this.document,
    required this.item,
    required this.child,
  });

  final MobileDeckDocument document;
  final SessionItem item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    final String header = _learnUnitHeader(
      LearnAnywhereLocalizations.of(context),
      item.unitIndex,
      document.deck.units.length,
      document.deck.categoryForUnit(unit).name,
      _directionLabel(document.deck, item.direction),
    );
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LearnAnywhereTokens.gapMedium,
            LearnAnywhereTokens.gapSmall,
            LearnAnywhereTokens.gapMedium,
            0,
          ),
          child: Text(
            header,
            style: Theme.of(context).textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

final class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.title,
    required this.fields,
    this.large = false,
    this.highlight = false,
  });

  final String title;
  final Map<FieldDefinition, FieldValue> fields;
  final bool large;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            if (fields.isEmpty)
              Text('', style: textTheme.bodyLarge)
            else
              ...fields.entries.map(
                (MapEntry<FieldDefinition, FieldValue> entry) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: LearnAnywhereTokens.gapMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(entry.key.name, style: textTheme.labelLarge),
                      const SizedBox(height: LearnAnywhereTokens.gapSmall),
                      LearnAnywhereRichText(
                        value: entry.value,
                        style: LearnAnywhereTokens.monospace(
                          large
                              ? textTheme.displaySmall
                              : textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
