import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_file_service.dart';

/// Mobile statistics screen for one deck: totals, seven mastery buckets as
/// labelled rows with proportional bars, and Clear statistics.
///
/// Deliberately simpler than desktop's: no per-unit list, no filters, no
/// save, plain widgets only (no charting library, no `CustomPainter`).
final class MobileStatisticsScreen extends StatefulWidget {
  /// Creates the mobile statistics screen.
  const MobileStatisticsScreen({
    required this.document,
    required this.fileService,
    super.key,
  });

  /// Deck opened from the library, plus its loaded statistics.
  final MobileDeckDocument document;

  /// File service used to persist a statistics clear.
  final MobileFileService fileService;

  @override
  State<MobileStatisticsScreen> createState() =>
      _MobileStatisticsScreenState();
}

final class _MobileStatisticsScreenState
    extends State<MobileStatisticsScreen> {
  late MobileDeckDocument _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  Future<void> _clearStatistics() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
              content: Text(
                messages.message(LearnAnywhereMessage.confirmClearStatistics),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    messages.message(LearnAnywhereMessage.actionCancel),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    messages.message(LearnAnywhereMessage.actionClear),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    final List<UnitStats> cleared = clearStatistics(_document.deck);
    final MobileDeckDocument updated = _document.copyWith(
      statistics: cleared,
    );
    setState(() => _document = updated);
    await widget.fileService.saveStatistics(updated, cleared);
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: _document.deck.units.length,
      statistics: _document.statistics,
    );
    final double practicedFraction = summary.totalUnits == 0
        ? 0
        : summary.queriedUnits / summary.totalUnits;
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.statisticsTitle)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          children: <Widget>[
            Wrap(
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: <Widget>[
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.statisticsTotalUnits,
                  ),
                  value: summary.totalUnits.toString(),
                ),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.statisticsQueriedUnits,
                  ),
                  value:
                      '${summary.queriedUnits} (${_percent(practicedFraction)})',
                ),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.statisticsTotalAttempts,
                  ),
                  value: summary.totalAttempts.toString(),
                ),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.statisticsCorrectAttempts,
                  ),
                  value: summary.totalCorrect.toString(),
                ),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.statisticsAccuracy,
                  ),
                  value: _percent(summary.attemptsHitRate ?? 0),
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            for (final BucketSummary bucket in summary.buckets)
              _BucketRow(
                label: _bucketLabel(messages, bucket.bucket),
                count: bucket.count,
                fraction: bucket.percentageOfAll,
              ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            FilledButton.icon(
              onPressed: _clearStatistics,
              icon: const Icon(Icons.delete_outline),
              label: Text(
                messages.message(LearnAnywhereMessage.statisticsClear),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

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
          horizontal: LearnAnywhereTokens.gapMedium,
          vertical: LearnAnywhereTokens.gapSmall,
        ),
        child: Text('$label: $value'),
      ),
    );
  }
}

/// One mastery-bucket row: label, a bar showing its share of the whole deck
/// (a full bar is 100 %), and raw count.
final class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String label;
  final int count;

  /// The bucket's share of all units, 0..1.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LearnAnywhereTokens.gapSmall / 2,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: SizedBox(
              height: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: LearnAnywhereTokens.smallRadius,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: LearnAnywhereTokens.smallRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: LearnAnywhereTokens.gapSmall),
          SizedBox(
            width: 32,
            child: Text(count.toString(), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

String _bucketLabel(LearnAnywhereLocalizations messages, HitRateBucket bucket) {
  return switch (bucket) {
    HitRateBucket.perfect => messages.message(
      LearnAnywhereMessage.statisticsBucketPerfect,
    ),
    HitRateBucket.good => messages.message(
      LearnAnywhereMessage.statisticsBucketGood,
    ),
    HitRateBucket.fair => messages.message(
      LearnAnywhereMessage.statisticsBucketFair,
    ),
    HitRateBucket.unsure => messages.message(
      LearnAnywhereMessage.statisticsBucketUnsure,
    ),
    HitRateBucket.veryUnsure => messages.message(
      LearnAnywhereMessage.statisticsBucketVeryUnsure,
    ),
    HitRateBucket.neverKnown => messages.message(
      LearnAnywhereMessage.statisticsBucketNeverKnown,
    ),
    HitRateBucket.notYetQueried => messages.message(
      LearnAnywhereMessage.statisticsBucketNotYetQueried,
    ),
  };
}

String _percent(double value) {
  return '${(value * 100).round()}%';
}
