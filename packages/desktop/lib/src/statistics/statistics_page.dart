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
    required this.onSaveStatisticsAs,
    required this.onClearStatistics,
    required this.onSaveSelectedUnits,
    required this.onClose,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

  /// Loads statistics from disk.
  final Future<void> Function() onLoadStatistics;

  /// Saves statistics to disk (to existing path if known).
  final Future<void> Function() onSaveStatistics;

  /// Saves statistics to a new path chosen by the user.
  final Future<void> Function() onSaveStatisticsAs;

  /// Clears in-memory statistics.
  final Future<void> Function() onClearStatistics;

  /// Saves selected unit indices as a new deck.
  final SaveSelectedUnitsCallback onSaveSelectedUnits;

  /// Called when the user closes this page.
  final VoidCallback onClose;

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
                spacing: LearnAnywhereTokens.gapMedium,
                runSpacing: LearnAnywhereTokens.gapSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _DirectionViewMenu(
                    view: _view,
                    onChanged: (StatisticsDirectionView value) {
                      setState(() => _view = value);
                    },
                  ),
                  _StatsFileButtons(
                    onLoad: widget.onLoadStatistics,
                    onSave: widget.onSaveStatistics,
                    onSaveAs: widget.onSaveStatisticsAs,
                    onClear: widget.onClearStatistics,
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(messages.message(LearnAnywhereMessage.actionCancel)),
                        const Text('Esc', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              TabBar(
                tabs: <Widget>[
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
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsKeepPracticing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _DetailedStats(summary: summary),
                    _BucketChart(summary: summary),
                    _PracticeList(
                      deck: widget.deck,
                      statistics: widget.statistics,
                      view: _view,
                      selectedUnitIndices: _selectedUnitIndices,
                      onSelectionChanged: _replaceSelection,
                      onSaveSelected: _saveSelected,
                      showBucketColumn: true,
                      unitIndices: null,
                    ),
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

final class _PracticeList extends StatefulWidget {
  const _PracticeList({
    required this.deck,
    required this.statistics,
    required this.view,
    required this.selectedUnitIndices,
    required this.onSelectionChanged,
    required this.onSaveSelected,
    this.showBucketColumn = true,
    this.unitIndices,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final StatisticsDirectionView view;
  final Set<int> selectedUnitIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final VoidCallback onSaveSelected;

  /// Whether to show the Bucket column (hidden when the bucket is constant
  /// for all shown rows, e.g. a Level×Bucket cell).
  final bool showBucketColumn;

  /// Explicit one-based unit indices to show; defaults to every deck unit.
  final List<int>? unitIndices;

  @override
  State<_PracticeList> createState() => _PracticeListState();
}

final class _PracticeListState extends State<_PracticeList> {
  /// Buckets currently shown; all buckets are visible by default.
  final Set<HitRateBucket> _visibleBuckets = <HitRateBucket>{
    ...HitRateBucket.values,
  };
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  /// Returns rows passing the active bucket and numeric hit-rate filters.
  List<_UnitStatisticsRow> _applyFilters(List<_UnitStatisticsRow> rows) {
    final double? min = _parsePercent(_minController.text);
    final double? max = _parsePercent(_maxController.text);
    final bool numericActive = min != null || max != null;
    return rows.where((_UnitStatisticsRow row) {
      if (!_visibleBuckets.contains(row.bucket)) {
        return false;
      }
      if (!numericActive) {
        return true;
      }
      final double? hitRate = row.stats.hitRate;
      if (hitRate == null) {
        // Never-practiced units have no hit rate; exclude when a numeric
        // range filter is active.
        return false;
      }
      final double percent = hitRate * 100;
      if (min != null && percent < min) {
        return false;
      }
      if (max != null && percent > max) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<_UnitStatisticsRow> rows = _rowsFor(
      widget.deck,
      widget.statistics,
      widget.view,
      unitIndices: widget.unitIndices,
    );
    final List<_UnitStatisticsRow> visibleRows = _applyFilters(rows);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFilterControls(messages),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: LearnAnywhereTokens.gapSmall,
              horizontalMargin: LearnAnywhereTokens.gapSmall,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 36,
              headingRowHeight: 36,
              columns: <DataColumn>[
                const DataColumn(label: SizedBox.shrink()),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsUnit),
                  ),
                ),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsQuestion),
                  ),
                ),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAnswer),
                  ),
                ),
                if (widget.showBucketColumn)
                  DataColumn(
                    label: Text(
                      messages.message(LearnAnywhereMessage.statisticsBucket),
                    ),
                  ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAttempts),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAccuracy),
                  ),
                ),
              ],
              rows: visibleRows
                  .map((_UnitStatisticsRow row) {
                    return DataRow(
                      selected: widget.selectedUnitIndices.contains(row.index),
                      cells: <DataCell>[
                        DataCell(
                          Checkbox(
                            value:
                                widget.selectedUnitIndices.contains(row.index),
                            onChanged: (bool? value) {
                              final Set<int> next = <int>{
                                ...widget.selectedUnitIndices,
                              };
                              if (value ?? false) {
                                next.add(row.index);
                              } else {
                                next.remove(row.index);
                              }
                              widget.onSelectionChanged(next);
                            },
                          ),
                        ),
                        _tipCell(row.tooltip, Text(row.index.toString())),
                        _tipCell(row.tooltip, Text(row.question)),
                        _tipCell(row.tooltip, Text(row.answer)),
                        if (widget.showBucketColumn)
                          _tipCell(
                            row.tooltip,
                            Text(_bucketLabel(messages, row.bucket)),
                          ),
                        _tipCell(
                          row.tooltip,
                          Text(row.stats.attempts.toString()),
                        ),
                        _tipCell(row.tooltip, Text(_accuracyLabel(row.stats))),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          Wrap(
            spacing: LearnAnywhereTokens.gapSmall,
            runSpacing: LearnAnywhereTokens.gapSmall,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  widget.onSelectionChanged(
                    visibleRows
                        .map((_UnitStatisticsRow row) => row.index)
                        .toSet(),
                  );
                },
                icon: const Icon(Icons.select_all),
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsSelectAll),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => widget.onSelectionChanged(<int>{}),
                icon: const Icon(Icons.deselect),
                label: Text(
                  messages.message(
                    LearnAnywhereMessage.statisticsClearSelection,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onSaveSelected,
                icon: const Icon(Icons.save_alt),
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsSaveSelected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bucket toggle chips and the optional numeric hit-rate range filter.
  Widget _buildFilterControls(LearnAnywhereLocalizations messages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.statisticsFilterBuckets),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          runSpacing: LearnAnywhereTokens.gapSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final HitRateBucket bucket in HitRateBucket.values)
              FilterChip(
                label: Text(_bucketLabel(messages, bucket)),
                selected: _visibleBuckets.contains(bucket),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _visibleBuckets.add(bucket);
                    } else {
                      _visibleBuckets.remove(bucket);
                    }
                  });
                },
              ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: messages.message(
                    LearnAnywhereMessage.statisticsFilterMin,
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: messages.message(
                    LearnAnywhereMessage.statisticsFilterMax,
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wraps a cell child in a [Tooltip] listing all of the unit's fields.
DataCell _tipCell(String tooltip, Widget child) {
  return DataCell(
    tooltip.isEmpty ? child : Tooltip(message: tooltip, child: child),
  );
}

/// Parses a percentage filter field, returning null when blank or invalid.
double? _parsePercent(String text) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
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
                label: Text(
                  messages.message(LearnAnywhereMessage.statisticsRange),
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
                      DataCell(Text(_bucketRange(bucket.bucket))),
                      DataCell(Text(bucket.count.toString())),
                      DataCell(Text(_percent(bucket.percentageOfAll))),
                      DataCell(Text(_percent(bucket.percentageOfQueried))),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Text(
          _practicedSummary(
            messages,
            practiced: summary.queriedUnits,
            total: summary.totalUnits,
          ),
          style: Theme.of(context).textTheme.titleSmall,
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

final class _StatsFileButtons extends StatelessWidget {
  const _StatsFileButtons({
    required this.onLoad,
    required this.onSave,
    required this.onSaveAs,
    required this.onClear,
  });

  final Future<void> Function() onLoad;
  final Future<void> Function() onSave;
  final Future<void> Function() onSaveAs;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Wrap(
      spacing: LearnAnywhereTokens.gapSmall,
      runSpacing: LearnAnywhereTokens.gapSmall,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: onLoad,
          icon: const Icon(Icons.upload_file),
          label: Text(messages.message(LearnAnywhereMessage.statisticsLoad)),
        ),
        FilledButton.tonalIcon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: Text(messages.message(LearnAnywhereMessage.statisticsSave)),
        ),
        FilledButton.tonalIcon(
          onPressed: onSaveAs,
          icon: const Icon(Icons.save_as),
          label: Text(messages.message(LearnAnywhereMessage.fileSaveStatsAs)),
        ),
        FilledButton.tonalIcon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: Text(messages.message(LearnAnywhereMessage.statisticsClear)),
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
    required this.bucket,
    required this.stats,
    required this.question,
    required this.answer,
    required this.tooltip,
  });

  final int index;
  final HitRateBucket bucket;
  final DirectionStats stats;

  /// Truncated plain-text preview of the first direction-1 question field.
  final String question;

  /// Truncated plain-text preview of the first direction-1 answer field.
  final String answer;

  /// Multi-line "field name: value" listing of all named fields (hover tip).
  final String tooltip;
}

/// Builds display rows for [unitIndices] (defaults to every deck unit).
List<_UnitStatisticsRow> _rowsFor(
  LearningDeck deck,
  List<UnitStats> statistics,
  StatisticsDirectionView view, {
  List<int>? unitIndices,
}) {
  final Map<int, UnitStats> byIndex = <int, UnitStats>{
    for (final UnitStats stats in statistics) stats.index: stats,
  };
  final List<int> indices =
      unitIndices ??
      List<int>.generate(deck.units.length, (int offset) => offset + 1);
  return indices.map((int index) {
    final LearningUnit unit = deck.units[index - 1];
    final CategoryDefinition category = deck.categoryForUnit(unit);
    final UnitStats unitStats = byIndex[index] ?? UnitStats(index: index);
    final DirectionStats stats = _statsForView(unitStats, view);
    return _UnitStatisticsRow(
      index: index,
      bucket: bucketFor(stats),
      stats: stats,
      question: _fieldPreview(
        unit,
        category,
        QueryDirection.direction1,
        FieldRole.question,
      ),
      answer: _fieldPreview(
        unit,
        category,
        QueryDirection.direction1,
        FieldRole.answer,
      ),
      tooltip: _fieldsTooltip(unit, category),
    );
  }).toList(growable: false);
}

/// Returns the truncated plain text of the first [role] field in [direction].
String _fieldPreview(
  LearningUnit unit,
  CategoryDefinition category,
  QueryDirection direction,
  FieldRole role,
) {
  final List<FieldDefinition> fields = category.fieldsForRole(direction, role);
  if (fields.isEmpty) {
    return '';
  }
  return _truncate(unit.valueForFieldId(fields.first.id).plainText);
}

/// Builds a "field name: value" listing of all named (non-hidden) fields.
String _fieldsTooltip(LearningUnit unit, CategoryDefinition category) {
  final List<String> lines = <String>[
    for (final FieldDefinition field in category.fields)
      if (!field.isHidden)
        '${field.name}: ${unit.valueForFieldId(field.id).plainText}',
  ];
  return lines.join('\n');
}

/// Truncates [text] to roughly [max] characters, appending an ellipsis.
String _truncate(String text, [int max = 30]) {
  final String collapsed = text.replaceAll('\n', ' ').trim();
  if (collapsed.length <= max) {
    return collapsed;
  }
  return '${collapsed.substring(0, max)}…';
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

/// Formats "correct (hitRate%)", or a neutral placeholder when not yet
/// queried.
String _accuracyLabel(DirectionStats stats) {
  final double? hitRate = stats.hitRate;
  if (hitRate == null) {
    return '—';
  }
  return '${stats.correct} (${_percent(hitRate)})';
}

String _percent(double value) {
  return '${(value * 100).round()}%';
}

/// Human-readable hit-rate range for a bucket. Empty for "not yet practiced".
String _bucketRange(HitRateBucket bucket) {
  return switch (bucket) {
    HitRateBucket.perfect => '100%',
    HitRateBucket.good => '75 – 99%',
    HitRateBucket.fair => '50 – 74%',
    HitRateBucket.unsure => '25 – 49%',
    HitRateBucket.veryUnsure => '1 – 24%',
    HitRateBucket.neverKnown => '0%',
    HitRateBucket.notYetQueried => '',
  };
}

/// Builds the "Practiced: X of Y units (Z%)" summary line.
String _practicedSummary(
  LearnAnywhereLocalizations messages, {
  required int practiced,
  required int total,
}) {
  final double percent = total == 0 ? 0 : practiced / total * 100;
  return messages
      .message(LearnAnywhereMessage.statisticsPracticedSummary)
      .replaceAll('{practiced}', practiced.toString())
      .replaceAll('{total}', total.toString())
      .replaceAll('{percent}', percent.toStringAsFixed(1));
}
