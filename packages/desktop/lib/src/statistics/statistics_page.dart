import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Saves selected units from the statistics page.
typedef SaveSelectedUnitsCallback =
    Future<void> Function(List<int> unitIndices);

/// Desktop statistics page with bucket tables, chart, and unit export.
final class StatisticsPage extends StatefulWidget {
  /// Creates the statistics page.
  const StatisticsPage({
    required this.deck,
    required this.statistics,
    required this.onLoadStatistics,
    required this.onSaveStatistics,
    required this.onClearStatistics,
    required this.onSaveSelectedUnits,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

  /// Loads statistics from disk.
  final Future<void> Function() onLoadStatistics;

  /// Saves statistics to disk.
  final Future<void> Function() onSaveStatistics;

  /// Clears in-memory statistics.
  final Future<void> Function() onClearStatistics;

  /// Saves selected unit indices as a new deck.
  final SaveSelectedUnitsCallback onSaveSelectedUnits;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

final class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsDirectionView _view = StatisticsDirectionView.combined;
  final Set<int> _selectedUnitIndices = <int>{};

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: widget.deck.units.length,
      statistics: widget.statistics,
      view: _view,
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 3,
        child: Padding(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                messages.message(LearnAnywhereMessage.statisticsTitle),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Wrap(
                spacing: LearnAnywhereTokens.gapSmall,
                runSpacing: LearnAnywhereTokens.gapSmall,
                children: <Widget>[
                  _DirectionViewMenu(
                    view: _view,
                    onChanged: (StatisticsDirectionView value) {
                      setState(() => _view = value);
                    },
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onLoadStatistics,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      messages.message(LearnAnywhereMessage.statisticsLoad),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onSaveStatistics,
                    icon: const Icon(Icons.save),
                    label: Text(
                      messages.message(LearnAnywhereMessage.statisticsSave),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onClearStatistics,
                    icon: const Icon(Icons.clear),
                    label: Text(
                      messages.message(LearnAnywhereMessage.statisticsClear),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              TabBar(
                tabs: <Widget>[
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsKeepPracticing,
                    ),
                  ),
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsDetailed,
                    ),
                  ),
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsChart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _PracticeList(
                      deck: widget.deck,
                      statistics: widget.statistics,
                      view: _view,
                      selectedUnitIndices: _selectedUnitIndices,
                      onSelectionChanged: _replaceSelection,
                      onSaveSelected: _saveSelected,
                    ),
                    _DetailedStats(summary: summary),
                    _BucketChart(summary: summary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _replaceSelection(Set<int> value) {
    setState(() {
      _selectedUnitIndices
        ..clear()
        ..addAll(value);
    });
  }

  Future<void> _saveSelected() async {
    await widget.onSaveSelectedUnits(_selectedUnitIndices.toList()..sort());
  }
}

final class _DirectionViewMenu extends StatelessWidget {
  const _DirectionViewMenu({required this.view, required this.onChanged});

  final StatisticsDirectionView view;
  final ValueChanged<StatisticsDirectionView> onChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<StatisticsDirectionView>(
        decoration: InputDecoration(
          labelText: messages.message(
            LearnAnywhereMessage.statisticsDirectionView,
          ),
        ),
        initialValue: view,
        items: <DropdownMenuItem<StatisticsDirectionView>>[
          DropdownMenuItem<StatisticsDirectionView>(
            value: StatisticsDirectionView.combined,
            child: Text(
              messages.message(LearnAnywhereMessage.statisticsCombined),
            ),
          ),
          DropdownMenuItem<StatisticsDirectionView>(
            value: StatisticsDirectionView.direction1,
            child: Text(
              messages.message(LearnAnywhereMessage.statisticsDirection1),
            ),
          ),
          DropdownMenuItem<StatisticsDirectionView>(
            value: StatisticsDirectionView.direction2,
            child: Text(
              messages.message(LearnAnywhereMessage.statisticsDirection2),
            ),
          ),
        ],
        onChanged: (StatisticsDirectionView? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

final class _PracticeList extends StatelessWidget {
  const _PracticeList({
    required this.deck,
    required this.statistics,
    required this.view,
    required this.selectedUnitIndices,
    required this.onSelectionChanged,
    required this.onSaveSelected,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final StatisticsDirectionView view;
  final Set<int> selectedUnitIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final VoidCallback onSaveSelected;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<_UnitStatisticsRow> rows = _rowsFor(deck, statistics, view);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          runSpacing: LearnAnywhereTokens.gapSmall,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () {
                onSelectionChanged(
                  rows.map((_UnitStatisticsRow row) => row.index).toSet(),
                );
              },
              icon: const Icon(Icons.select_all),
              label: Text(
                messages.message(LearnAnywhereMessage.statisticsSelectAll),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onSelectionChanged(<int>{}),
              icon: const Icon(Icons.deselect),
              label: Text(
                messages.message(LearnAnywhereMessage.statisticsClearSelection),
              ),
            ),
            FilledButton.icon(
              onPressed: onSaveSelected,
              icon: const Icon(Icons.save_alt),
              label: Text(
                messages.message(LearnAnywhereMessage.statisticsSaveSelected),
              ),
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Expanded(
          child: ListView(
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: <DataColumn>[
                    const DataColumn(label: SizedBox.shrink()),
                    DataColumn(
                      label: Text(
                        messages.message(LearnAnywhereMessage.statisticsUnit),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        messages.message(
                          LearnAnywhereMessage.statisticsCategory,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        messages.message(LearnAnywhereMessage.statisticsBucket),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        messages.message(
                          LearnAnywhereMessage.statisticsHitRate,
                        ),
                      ),
                    ),
                  ],
                  rows: rows
                      .map((_UnitStatisticsRow row) {
                        return DataRow(
                          selected: selectedUnitIndices.contains(row.index),
                          cells: <DataCell>[
                            DataCell(
                              Checkbox(
                                value: selectedUnitIndices.contains(row.index),
                                onChanged: (bool? value) {
                                  final Set<int> next = <int>{
                                    ...selectedUnitIndices,
                                  };
                                  if (value ?? false) {
                                    next.add(row.index);
                                  } else {
                                    next.remove(row.index);
                                  }
                                  onSelectionChanged(next);
                                },
                              ),
                            ),
                            DataCell(Text(row.index.toString())),
                            DataCell(Text(row.categoryName)),
                            DataCell(Text(_bucketLabel(messages, row.bucket))),
                            DataCell(Text(_hitRateLabel(row.stats))),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _DetailedStats extends StatelessWidget {
  const _DetailedStats({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return ListView(
      children: <Widget>[
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
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
              value: summary.queriedUnits.toString(),
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: <DataColumn>[
              DataColumn(
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsBucket),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsCount),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsPercentAll),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  messages.message(
                    LearnAnywhereMessage.statisticsPercentQueried,
                  ),
                ),
              ),
            ],
            rows: summary.buckets
                .map((BucketSummary bucket) {
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(_bucketLabel(messages, bucket.bucket))),
                      DataCell(Text(bucket.count.toString())),
                      DataCell(Text(_percent(bucket.percentageOfAll))),
                      DataCell(Text(_percent(bucket.percentageOfQueried))),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

final class _BucketChart extends StatelessWidget {
  const _BucketChart({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            painter: _BucketChartPainter(
              buckets: summary.buckets,
              labels: <HitRateBucket, String>{
                for (final HitRateBucket bucket in HitRateBucket.values)
                  bucket: _bucketLabel(messages, bucket),
              },
              color: Theme.of(context).colorScheme.primary,
              textStyle:
                  Theme.of(context).textTheme.bodySmall ??
                  const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

final class _BucketChartPainter extends CustomPainter {
  const _BucketChartPainter({
    required this.buckets,
    required this.labels,
    required this.color,
    required this.textStyle,
  });

  final List<BucketSummary> buckets;
  final Map<HitRateBucket, String> labels;
  final Color color;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    final int maxCount = math.max(
      1,
      buckets.map((BucketSummary bucket) => bucket.count).reduce(math.max),
    );
    final Paint paint = Paint()..color = color;
    final double chartHeight = math.max(0, size.height - 64);
    final double slotWidth = size.width / buckets.length;
    for (var index = 0; index < buckets.length; index += 1) {
      final BucketSummary bucket = buckets[index];
      final double barHeight = chartHeight * (bucket.count / maxCount);
      final double left = index * slotWidth + 8;
      final double right = (index + 1) * slotWidth - 8;
      final double top = chartHeight - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, chartHeight),
          const Radius.circular(4),
        ),
        paint,
      );
      _paintText(
        canvas,
        bucket.count.toString(),
        Offset(left, math.max(0, top - 22)),
        right - left,
      );
      _paintText(
        canvas,
        labels[bucket.bucket] ?? bucket.bucket.name,
        Offset(left, chartHeight + 8),
        right - left,
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, double width) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: math.max(20, width));
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_BucketChartPainter oldDelegate) {
    return oldDelegate.buckets != buckets ||
        oldDelegate.color != color ||
        oldDelegate.textStyle != textStyle;
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

final class _UnitStatisticsRow {
  const _UnitStatisticsRow({
    required this.index,
    required this.categoryName,
    required this.bucket,
    required this.stats,
  });

  final int index;
  final String categoryName;
  final HitRateBucket bucket;
  final DirectionStats stats;
}

List<_UnitStatisticsRow> _rowsFor(
  LearningDeck deck,
  List<UnitStats> statistics,
  StatisticsDirectionView view,
) {
  final Map<int, UnitStats> byIndex = <int, UnitStats>{
    for (final UnitStats stats in statistics) stats.index: stats,
  };
  return List<_UnitStatisticsRow>.generate(deck.units.length, (int offset) {
    final int index = offset + 1;
    final LearningUnit unit = deck.units[offset];
    final UnitStats unitStats = byIndex[index] ?? UnitStats(index: index);
    final DirectionStats stats = _statsForView(unitStats, view);
    return _UnitStatisticsRow(
      index: index,
      categoryName: deck.categoryForUnit(unit).name,
      bucket: bucketFor(stats),
      stats: stats,
    );
  }, growable: false);
}

DirectionStats _statsForView(UnitStats stats, StatisticsDirectionView view) {
  return switch (view) {
    StatisticsDirectionView.direction1 => stats.direction1,
    StatisticsDirectionView.direction2 => stats.direction2,
    StatisticsDirectionView.combined => DirectionStats(
      attempts: stats.direction1.attempts + stats.direction2.attempts,
      correct: stats.direction1.correct + stats.direction2.correct,
    ),
  };
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

String _hitRateLabel(DirectionStats stats) {
  final double? hitRate = stats.hitRate;
  if (hitRate == null) {
    return '-';
  }
  return _percent(hitRate);
}

String _percent(double value) {
  return '${(value * 100).round()}%';
}
