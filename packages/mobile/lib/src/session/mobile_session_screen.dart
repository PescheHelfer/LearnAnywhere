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
  });

  final MobileDeckDocument document;
  final SessionParameters parameters;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    // Deck total in the session's direction, matching desktop's live pills and
    // the statistics screen for this deck — never a narrower, range-restricted
    // slice and never a per-sitting counter. See deckWideScope/directionViewFor
    // in engine.dart.
    final SessionParameters readoutScope = deckWideScope(parameters);
    final StatisticsDirectionView view = directionViewFor(
      parameters.directionSelection,
    );
    final int total = sessionItemCount(
      unitCount: document.deck.units.length,
      parameters: readoutScope,
    );
    final int remaining = activeSuperQueryPool(
      deck: document.deck,
      statistics: document.statistics,
      parameters: readoutScope,
    ).length;
    final int mastered = (total - remaining).clamp(0, total);
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: document.deck.units.length,
      statistics: document.statistics,
      view: view,
    );
    final int accuracyPct = summary.totalAttempts == 0
        ? 0
        : ((summary.totalCorrect / summary.totalAttempts) * 100).round();
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
                value:
                    '${summary.totalCorrect}/${summary.totalAttempts} '
                    '($accuracyPct%)',
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
    return _UnitScaffold(
      document: document,
      item: item,
      child: Column(
        children: <Widget>[
          Expanded(child: _QuestionPanel(document: document, item: item)),
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

/// The prompt fields, top-anchored and filling the card's width so a short
/// question and a long one leave consecutive cards the same shape.
///
/// Shrink-then-scroll: the value style is sized down toward
/// [_kCardMinFontSize] until the group fits the available height, and the
/// group stays inside a scroll view so a unit that is still too big at the
/// floor (a long prompt, or a category with many fields) reaches the reader
/// instead of overflowing off the bottom.
final class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({required this.document, required this.item});

  final MobileDeckDocument document;
  final SessionItem item;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    final Map<FieldDefinition, FieldValue> fields = promptFields(
      document.deck,
      unit,
      item.direction,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const EdgeInsets padding = EdgeInsets.all(
          LearnAnywhereTokens.gapLarge,
        );
        final TextStyle style = _fittedCardStyle(
          context: context,
          fields: fields,
          available: Size(
            constraints.maxWidth - padding.horizontal,
            constraints.maxHeight - padding.vertical,
          ),
        );
        return SingleChildScrollView(
          padding: padding,
          // SizedBox forces the group to the card's full width regardless of
          // content length — a vertical SingleChildScrollView's own width
          // constraint on its child is loose, not tight, so without this a
          // short question would size down to its own content width instead
          // of matching the next (possibly longer) card.
          child: SizedBox(
            width: constraints.maxWidth - padding.horizontal,
            child: _FieldGroup(
              title: messages.message(LearnAnywhereMessage.learnPrompt),
              fields: fields,
              valueStyle: style,
            ),
          ),
        );
      },
    );
  }
}

final class _RevealView extends StatefulWidget {
  const _RevealView({
    required this.document,
    required this.item,
    required this.onRate,
  });

  final MobileDeckDocument document;
  final SessionItem item;
  final ValueChanged<AttemptRating> onRate;

  @override
  State<_RevealView> createState() => _RevealViewState();
}

final class _RevealViewState extends State<_RevealView> {
  // Resets to the answer (false) every time a fresh _RevealView is built for
  // a new card — the stage machine in MobileSessionScreen always returns to
  // _MobileSessionStage.prompt before a new reveal, so this state never
  // survives to the next card.
  bool _showQuestion = false;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit =
        widget.document.deck.units[widget.item.unitIndex - 1];
    return _UnitScaffold(
      document: widget.document,
      item: widget.item,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LearnAnywhereTokens.gapMedium,
              LearnAnywhereTokens.gapSmall,
              LearnAnywhereTokens.gapMedium,
              0,
            ),
            child: SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  label: Text(messages.message(LearnAnywhereMessage.learnPrompt)),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(
                    messages.message(LearnAnywhereMessage.learnSolution),
                  ),
                ),
              ],
              selected: <bool>{_showQuestion},
              onSelectionChanged: (Set<bool> selection) =>
                  setState(() => _showQuestion = selection.single),
            ),
          ),
          Expanded(
            child: _showQuestion
                ? _QuestionPanel(document: widget.document, item: widget.item)
                : ListView(
                    padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
                    children: <Widget>[
                      _FieldGroup(
                        title: messages.message(
                          LearnAnywhereMessage.learnSolution,
                        ),
                        fields: answerFields(
                          widget.document.deck,
                          unit,
                          widget.item.direction,
                        ),
                        // Same size as the prompt: the two are one card the
                        // eye compares, so the solution is set apart by the
                        // tinted panel and its label, not by being smaller.
                        valueStyle: _cardValueStyle(context),
                        highlight: true,
                      ),
                      const SizedBox(height: LearnAnywhereTokens.gapLarge),
                      _FieldGroup(
                        title: messages.message(
                          LearnAnywhereMessage.learnRemarks,
                        ),
                        fields: remarkFields(
                          widget.document.deck,
                          unit,
                          widget.item.direction,
                        ),
                        // Remarks are supporting notes, not the thing being
                        // recalled, so they stay at body size.
                        valueStyle: LearnAnywhereTokens.monospace(
                          Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
          ),
          // Rating stays reachable and enabled regardless of the toggle above
          // — it rates the card the learner was shown, not the panel state.
          Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: <Widget>[
                FilledButton(
                  onPressed: () => widget.onRate(AttemptRating.correct),
                  child: Text(
                    messages.message(LearnAnywhereMessage.learnRatingKnewIt),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => widget.onRate(AttemptRating.wrong),
                  child: Text(
                    messages.message(
                      LearnAnywhereMessage.learnRatingDidNotKnow,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => widget.onRate(AttemptRating.noCount),
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

/// Largest size a prompt or solution value is set at.
///
/// Chosen over the theme's `displaySmall` (36): at 36 the bundled fixed-width
/// face fits barely fourteen characters across a phone, so ordinary vocabulary
/// wrapped into a wall of text and anything longer ran off the card.
const double _kCardFontSize = 24;

/// Floor the prompt is allowed to shrink to before it scrolls instead.
const double _kCardMinFontSize = 14;

/// The full-size style for a prompt or solution value.
TextStyle _cardValueStyle(BuildContext context) {
  return LearnAnywhereTokens.monospace(
    Theme.of(context).textTheme.headlineSmall,
  ).copyWith(fontSize: _kCardFontSize);
}

/// The largest style at or below [_kCardFontSize] that lays [fields] out
/// within [available], down to [_kCardMinFontSize].
///
/// Only the field values are measured. The group's chrome — title, per-field
/// labels, padding and gaps — keeps a fixed size and is accounted for as a
/// constant, so this is an estimate; being an estimate is harmless because the
/// caller scrolls whatever still does not fit.
TextStyle _fittedCardStyle({
  required BuildContext context,
  required Map<FieldDefinition, FieldValue> fields,
  required Size available,
}) {
  final TextStyle base = _cardValueStyle(context);
  if (fields.isEmpty || available.width <= 0 || available.height <= 0) {
    return base;
  }
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  // Group padding (top and bottom), title line, and the gap under it.
  const double groupChrome = LearnAnywhereTokens.gapMedium * 2 + 24 +
      LearnAnywhereTokens.gapMedium;
  // Per field: the label line, the gap under it, and the trailing gap.
  const double fieldChrome =
      20 + LearnAnywhereTokens.gapSmall + LearnAnywhereTokens.gapMedium;
  final double budget =
      available.height - groupChrome - fieldChrome * fields.length;
  if (budget <= 0) {
    return base.copyWith(fontSize: _kCardMinFontSize);
  }
  final double contentWidth = available.width - LearnAnywhereTokens.gapMedium * 2;
  for (double size = _kCardFontSize; size > _kCardMinFontSize; size -= 1) {
    final TextStyle candidate = base.copyWith(fontSize: size);
    double total = 0;
    for (final FieldValue value in fields.values) {
      total += _measuredHeight(
        text: value.plainText,
        style: candidate,
        maxWidth: contentWidth,
        scaler: scaler,
      );
    }
    if (total <= budget) {
      return candidate;
    }
  }
  return base.copyWith(fontSize: _kCardMinFontSize);
}

double _measuredHeight({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextScaler scaler,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text.isEmpty ? ' ' : text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: maxWidth < 0 ? 0 : maxWidth);
  final double height = painter.height;
  painter.dispose();
  return height;
}

final class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.title,
    required this.fields,
    required this.valueStyle,
    this.highlight = false,
  });

  final String title;
  final Map<FieldDefinition, FieldValue> fields;

  /// Style for the field values. Sized by the caller so the prompt can shrink
  /// to fit while the solution stays at its full size.
  final TextStyle valueStyle;

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
                        style: valueStyle,
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

