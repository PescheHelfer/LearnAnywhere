import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.levelStatistics,
    required this.allTimeStatistics,
    required this.allTimeLevelStatistics,
    required this.allTimeIsRefused,
    required this.levelNames,
    required this.onLoadStatistics,
    required this.onSaveStatistics,
    required this.onSaveStatisticsAs,
    required this.onClearStatistics,
    required this.onClearAllTimeStatistics,
    required this.onSaveSelectedUnits,
    required this.onClose,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

  /// Current Level-Learning statistics (empty when the deck has none).
  final List<LevelUnitStats> levelStatistics;

  /// The deck's all-time per-unit counters (empty when nothing was recorded).
  final List<UnitStats> allTimeStatistics;

  /// The deck's all-time Level-Learning counters, each carrying the last level
  /// reached rather than where the ladder stands now.
  final List<LevelUnitStats> allTimeLevelStatistics;

  /// Whether the deck's all-time record has been refused a write, so the
  /// numbers under the all-time scope are counting into memory only.
  ///
  /// The refusal itself is silent by design — it happens on a queued write
  /// that must not interrupt a live session — which is exactly why the state
  /// has to be visible where the record is looked at.
  final bool allTimeIsRefused;

  /// Custom level names for the active locale, ordered level 3 → 0.
  final List<String> levelNames;

  /// Loads statistics from disk.
  final Future<void> Function() onLoadStatistics;

  /// Saves statistics to disk (to existing path if known).
  final Future<void> Function() onSaveStatistics;

  /// Saves statistics to a new path chosen by the user.
  final Future<void> Function() onSaveStatisticsAs;

  /// Clears in-memory statistics.
  final Future<void> Function() onClearStatistics;

  /// Clears the deck's all-time record, in memory and in its file.
  ///
  /// The one destructive action on this screen: it is offered only under the
  /// all-time numbers, and only inside the overflow menu there, so nothing on
  /// the screen itself can be pressed by accident. The shell confirms it
  /// before anything is erased.
  final Future<void> Function() onClearAllTimeStatistics;

  /// Saves selected unit indices as a new deck.
  final SaveSelectedUnitsCallback onSaveSelectedUnits;

  /// Called when the user closes this page.
  final VoidCallback onClose;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

final class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsDirectionView _view = StatisticsDirectionView.direction1;

  /// Which of the deck's two records the three tabs read.
  ///
  /// Deliberately not persisted anywhere. The current statistics are the ones
  /// that decide what gets practised, so they are what the learner came to
  /// read; the all-time record is for looking at deliberately. Opening on the
  /// current statistics every visit also means a scope-specific action can
  /// never be reached by accident from a scope left over from last time.
  StatisticsScope _scope = StatisticsScope.session;

  final Set<int> _selectedUnitIndices = <int>{};

  /// The per-unit record [_scope] selects.
  List<UnitStats> get _statistics => _scope == StatisticsScope.allTime
      ? widget.allTimeStatistics
      : widget.statistics;

  /// The Level-Learning record [_scope] selects.
  List<LevelUnitStats> get _levelStatistics =>
      _scope == StatisticsScope.allTime
          ? widget.allTimeLevelStatistics
          : widget.levelStatistics;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool allTime = _scope == StatisticsScope.allTime;
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: widget.deck.units.length,
      statistics: _statistics,
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
              // Row one — what is on screen: which direction, which record.
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
                  _ScopeSelector(
                    scope: _scope,
                    onChanged: (StatisticsScope value) {
                      setState(() => _scope = value);
                    },
                  ),
                  // The one destructive command in the program, kept out of
                  // sight rather than made to look frightening: prominence is
                  // not deterrence, and a filled red button beside the scope
                  // reads as *the* action of the screen and invites the press.
                  // The deterrent is the shell's confirmation, which names the
                  // deck and focuses Cancel.
                  if (allTime)
                    _AllTimeOverflowMenu(
                      onClear: widget.onClearAllTimeStatistics,
                    ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapSmall),
              // Row two — what can be done to it. Load, save, save-as and the
              // everyday clear all act on the working record, so none of them
              // belongs under the all-time numbers, which leaves Cancel alone
              // there: the all-time scope offers no button that changes
              // anything.
              Wrap(
                spacing: LearnAnywhereTokens.gapMedium,
                runSpacing: LearnAnywhereTokens.gapSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (!allTime)
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
              // The one thing the numbers themselves cannot say: that they are
              // not reaching the file. It sits above the tabs so it is on
              // screen whichever view is open, and only under the all-time
              // scope, because the current record saves as it always did.
              if (allTime && widget.allTimeIsRefused) ...<Widget>[
                const SizedBox(height: LearnAnywhereTokens.gapMedium),
                const _AllTimeNotRecordedNotice(),
              ],
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: <Widget>[
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsOverview,
                    ),
                  ),
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsUnitList,
                    ),
                  ),
                  Tab(
                    text: messages.message(
                      LearnAnywhereMessage.statisticsLevelLearning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _DetailedStats(summary: summary),
                    _PracticeList(
                      deck: widget.deck,
                      statistics: _statistics,
                      view: _view,
                      selectedUnitIndices: _selectedUnitIndices,
                      onSelectionChanged: _replaceSelection,
                      onSaveSelected: _saveSelected,
                      showBucketColumn: true,
                      unitIndices: null,
                    ),
                    _LevelLearningStats(
                      deck: widget.deck,
                      levelStatistics: _levelStatistics,
                      levelNames: widget.levelNames,
                      view: _view,
                      lastLevelColumn: allTime,
                      selectedUnitIndices: _selectedUnitIndices,
                      onSelectionChanged: _replaceSelection,
                      onSaveSelected: _saveSelected,
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

/// The Current / All-time scope control.
///
/// A segmented button rather than a second dropdown: both choices show at
/// once, so a learner who has never heard of the all-time record can see that
/// it exists, and switching between the two is a single click.
final class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.scope, required this.onChanged});

  final StatisticsScope scope;
  final ValueChanged<StatisticsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return SegmentedButton<StatisticsScope>(
      showSelectedIcon: false,
      segments: <ButtonSegment<StatisticsScope>>[
        ButtonSegment<StatisticsScope>(
          value: StatisticsScope.session,
          label: Text(
            messages.message(LearnAnywhereMessage.statisticsScopeCurrent),
          ),
        ),
        ButtonSegment<StatisticsScope>(
          value: StatisticsScope.allTime,
          label: Text(
            messages.message(LearnAnywhereMessage.statisticsScopeAllTime),
          ),
        ),
      ],
      selected: <StatisticsScope>{scope},
      onSelectionChanged: (Set<StatisticsScope> selection) =>
          onChanged(selection.first),
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
    this.levelStatsOverride,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final StatisticsDirectionView view;
  final Set<int> selectedUnitIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final VoidCallback onSaveSelected;

  /// Whether to show the Bucket column (hidden when the bucket is constant
  /// for all shown rows, e.g. a Level×Bucket cell). The bucket filter chips are
  /// hidden alongside it, since they cannot vary the result.
  final bool showBucketColumn;

  /// Explicit one-based unit indices to show; defaults to every deck unit.
  final List<int>? unitIndices;

  /// Per-index stats to show instead of the mode's per-unit counters.
  ///
  /// Used by the Level-Learning drill-down to display *that level's* attempts
  /// and accuracy. When set, each row's Attempts/Accuracy and bucket come from
  /// this map (missing indices fall back to empty stats) rather than [view].
  final Map<int, DirectionStats>? levelStatsOverride;

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

  /// Column the table is sorted by, and its direction.
  _PracticeSortKey _sortKey = _PracticeSortKey.unit;
  bool _sortAscending = true;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  /// The sortable columns in display order.
  ///
  /// Keyed by enum rather than by column index so hiding the Bucket column
  /// (the Level-Learning drill-down) cannot silently shift the mapping. The
  /// leading checkbox column is not sortable, so a column's table index is its
  /// position here plus one.
  List<_PracticeSortKey> get _sortableKeys => <_PracticeSortKey>[
    _PracticeSortKey.unit,
    _PracticeSortKey.question,
    _PracticeSortKey.answer,
    if (widget.showBucketColumn) _PracticeSortKey.bucket,
    _PracticeSortKey.attempts,
    _PracticeSortKey.accuracy,
  ];

  /// Table column index currently sorted, or `null` when the active key is not
  /// among the visible columns.
  int? get _sortColumnIndex {
    final int position = _sortableKeys.indexOf(_sortKey);
    return position < 0 ? null : position + 1;
  }

  void _sortBy(int columnIndex, bool ascending) {
    final List<_PracticeSortKey> keys = _sortableKeys;
    final int position = columnIndex - 1;
    if (position < 0 || position >= keys.length) {
      return;
    }
    setState(() {
      _sortKey = keys[position];
      _sortAscending = ascending;
    });
  }

  /// Returns [rows] sorted by the active column.
  ///
  /// Ties fall back to unit order (always ascending) so the listing stays
  /// stable. Units with no attempts have no hit rate; they sort as the lowest
  /// accuracy, i.e. first ascending and last descending.
  List<_UnitStatisticsRow> _applySort(List<_UnitStatisticsRow> rows) {
    final List<_UnitStatisticsRow> sorted = <_UnitStatisticsRow>[...rows];
    sorted.sort((_UnitStatisticsRow a, _UnitStatisticsRow b) {
      final int result = switch (_sortKey) {
        _PracticeSortKey.unit => a.index.compareTo(b.index),
        _PracticeSortKey.question => a.question.toLowerCase().compareTo(
          b.question.toLowerCase(),
        ),
        _PracticeSortKey.answer => a.answer.toLowerCase().compareTo(
          b.answer.toLowerCase(),
        ),
        _PracticeSortKey.bucket => a.bucket.index.compareTo(b.bucket.index),
        _PracticeSortKey.attempts => a.stats.attempts.compareTo(
          b.stats.attempts,
        ),
        _PracticeSortKey.accuracy => (a.stats.hitRate ?? -1).compareTo(
          b.stats.hitRate ?? -1,
        ),
      };
      if (result != 0) {
        return _sortAscending ? result : -result;
      }
      return a.index.compareTo(b.index);
    });
    return sorted;
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
      statsOverride: widget.levelStatsOverride,
    );
    final List<_UnitStatisticsRow> visibleRows = _applySort(_applyFilters(rows));
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
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: <DataColumn>[
                const DataColumn(label: SizedBox.shrink()),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsUnit),
                  ),
                  onSort: _sortBy,
                ),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsQuestion),
                  ),
                  onSort: _sortBy,
                ),
                DataColumn(
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAnswer),
                  ),
                  onSort: _sortBy,
                ),
                if (widget.showBucketColumn)
                  DataColumn(
                    label: Text(
                      messages.message(LearnAnywhereMessage.statisticsBucket),
                    ),
                    onSort: _sortBy,
                  ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAttempts),
                  ),
                  onSort: _sortBy,
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    messages.message(LearnAnywhereMessage.statisticsAccuracy),
                  ),
                  onSort: _sortBy,
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
        if (widget.showBucketColumn) ...<Widget>[
          Text(
            messages.message(LearnAnywhereMessage.statisticsFilterBuckets),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            messages.message(LearnAnywhereMessage.statisticsFilterIsolateHint),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            messages.message(LearnAnywhereMessage.statisticsIncludesLevelZero),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
        ],
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          runSpacing: LearnAnywhereTokens.gapSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (widget.showBucketColumn)
              for (final HitRateBucket bucket in HitRateBucket.values)
                FilterChip(
                  label: Text(_bucketLabel(messages, bucket)),
                  selected: _visibleBuckets.contains(bucket),
                  onSelected: (bool selected) {
                    setState(() {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        _visibleBuckets
                          ..clear()
                          ..add(bucket);
                      } else if (selected) {
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

/// Level-Learning statistics tab: a Level×Bucket matrix with a cell drill-down.
///
/// Rows are the four support levels (3 → 0, most → least support) plus a Total
/// row; columns are the seven hit-rate buckets plus a Total column. The scope is
/// the whole deck (the Statistics page has no range selector); the direction
/// [view] is shared with the other tabs. Tapping a non-total cell opens the
/// filtered unit list (a [_PracticeList] with the Bucket column hidden) showing
/// that level's own attempts/accuracy.
final class _LevelLearningStats extends StatefulWidget {
  const _LevelLearningStats({
    required this.deck,
    required this.levelStatistics,
    required this.levelNames,
    required this.view,
    required this.lastLevelColumn,
    required this.selectedUnitIndices,
    required this.onSelectionChanged,
    required this.onSaveSelected,
  });

  final LearningDeck deck;
  final List<LevelUnitStats> levelStatistics;
  final List<String> levelNames;
  final StatisticsDirectionView view;

  /// Whether the row-header column names the *last* level reached rather than
  /// the level the ladder currently stands at.
  ///
  /// The all-time record carries the level most recently written, because a
  /// level is a state and not a counter: after a fresh start the learner is
  /// back at full support, and summing that with last month's free recall
  /// would mean nothing. Labelling the column "Level" there would invite
  /// reading it as the live ladder position.
  final bool lastLevelColumn;

  final Set<int> selectedUnitIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final VoidCallback onSaveSelected;

  @override
  State<_LevelLearningStats> createState() => _LevelLearningStatsState();
}

final class _LevelLearningStatsState extends State<_LevelLearningStats> {
  /// Levels ordered most → least support, top to bottom.
  static const List<int> _levelsTopDown = <int>[3, 2, 1, 0];

  /// The drilled-into cell, or null while the matrix is shown.
  int? _drillLevel;
  HitRateBucket? _drillBucket;

  @override
  void didUpdateWidget(covariant _LevelLearningStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A direction-view switch, a scope switch or a stats change can invalidate
    // the open cell; drop back to the matrix rather than show a stale,
    // mismatched list. The scope is checked in its own right: two empty
    // records are the same canonical const list, so identity alone would miss
    // the switch.
    if (_drillLevel != null &&
        (oldWidget.view != widget.view ||
            oldWidget.lastLevelColumn != widget.lastLevelColumn ||
            !identical(oldWidget.levelStatistics, widget.levelStatistics))) {
      _drillLevel = null;
      _drillBucket = null;
    }
  }

  List<int> get _scopeIndices =>
      List<int>.generate(widget.deck.units.length, (int i) => i + 1);

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LevelBucketMatrix matrix = levelBucketMatrix(
      levelStatistics: widget.levelStatistics,
      unitIndices: _scopeIndices,
      view: widget.view,
    );
    if (_drillLevel != null && _drillBucket != null) {
      return _buildDrillDown(messages, matrix, _drillLevel!, _drillBucket!);
    }
    return _buildMatrix(messages, matrix);
  }

  Widget _buildMatrix(
    LearnAnywhereLocalizations messages,
    LevelBucketMatrix matrix,
  ) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: LearnAnywhereTokens.gapSmall,
          horizontalMargin: LearnAnywhereTokens.gapSmall,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          headingRowHeight: 40,
          columns: <DataColumn>[
            DataColumn(
              label: Text(
                messages.message(
                  widget.lastLevelColumn
                      ? LearnAnywhereMessage.statisticsLastLevel
                      : LearnAnywhereMessage.statisticsLevel,
                ),
              ),
            ),
            for (final HitRateBucket bucket in HitRateBucket.values)
              DataColumn(
                numeric: true,
                label: Text(_bucketLabel(messages, bucket)),
              ),
            DataColumn(
              numeric: true,
              label: Text(messages.message(LearnAnywhereMessage.statisticsTotal)),
            ),
          ],
          rows: <DataRow>[
            for (final int level in _levelsTopDown)
              _levelRow(messages, matrix, level),
            _totalRow(messages, matrix),
          ],
        ),
      ),
    );
  }

  DataRow _levelRow(
    LearnAnywhereLocalizations messages,
    LevelBucketMatrix matrix,
    int level,
  ) {
    final int rowTotal = matrix.rowTotals[level] ?? 0;
    return DataRow(
      cells: <DataCell>[
        DataCell(_levelHeader(messages, level)),
        for (final HitRateBucket bucket in HitRateBucket.values)
          _matrixCell(matrix, level, bucket, rowTotal),
        DataCell(Text('$rowTotal', style: _boldStyle)),
      ],
    );
  }

  /// A clickable `count (row-%)` cell, or a plain `0` when the cell is empty.
  DataCell _matrixCell(
    LevelBucketMatrix matrix,
    int level,
    HitRateBucket bucket,
    int rowTotal,
  ) {
    final int count = matrix.countAt(level, bucket);
    if (count == 0) {
      return const DataCell(Text('0'));
    }
    final int percent = rowTotal == 0 ? 0 : (count / rowTotal * 100).round();
    return DataCell(
      Text('$count ($percent%)'),
      onTap: () => setState(() {
        _drillLevel = level;
        _drillBucket = bucket;
      }),
    );
  }

  DataRow _totalRow(
    LearnAnywhereLocalizations messages,
    LevelBucketMatrix matrix,
  ) {
    return DataRow(
      cells: <DataCell>[
        DataCell(
          Text(
            messages.message(LearnAnywhereMessage.statisticsTotal),
            style: _boldStyle,
          ),
        ),
        for (final HitRateBucket bucket in HitRateBucket.values)
          DataCell(_totalCell(matrix, bucket)),
        DataCell(Text('${matrix.grandTotal}', style: _boldStyle)),
      ],
    );
  }

  /// A `count (deck-wide-%)` total-row cell for [bucket].
  Widget _totalCell(LevelBucketMatrix matrix, HitRateBucket bucket) {
    final int colTotal = matrix.columnTotals[bucket] ?? 0;
    if (matrix.grandTotal == 0) {
      return Text('0', style: _boldStyle);
    }
    final int percent = (colTotal / matrix.grandTotal * 100).round();
    return Text('$colTotal ($percent%)', style: _boldStyle);
  }

  /// Level row header: the custom name with the numeric level as a subtitle.
  Widget _levelHeader(LearnAnywhereLocalizations messages, int level) {
    final String name = levelNameFor(widget.levelNames, level);
    final String numberLabel = _levelNumberLabel(messages, level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(name.isEmpty ? numberLabel : name),
        if (name.isNotEmpty)
          Text(
            '($numberLabel)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }

  Widget _buildDrillDown(
    LearnAnywhereLocalizations messages,
    LevelBucketMatrix matrix,
    int level,
    HitRateBucket bucket,
  ) {
    final List<LevelMatrixEntry> entries = matrix.entriesAt(level, bucket);
    // In combined view a unit can reach one cell via both directions; list it
    // once, using the first direction's level stats for its Attempts/Accuracy.
    final List<int> unitIndices = <int>[];
    final Map<int, DirectionStats> override = <int, DirectionStats>{};
    for (final LevelMatrixEntry entry in entries) {
      if (override.containsKey(entry.unitIndex)) {
        continue;
      }
      override[entry.unitIndex] = entry.stats;
      unitIndices.add(entry.unitIndex);
    }
    final String name = levelNameFor(widget.levelNames, level);
    final String crumbLevel = name.isEmpty
        ? _levelNumberLabel(messages, level)
        : name;
    final String breadcrumb = '$crumbLevel — ${_bucketLabel(messages, bucket)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () => setState(() {
                _drillLevel = null;
                _drillBucket = null;
              }),
              icon: const Icon(Icons.arrow_back),
              label: Text(messages.message(LearnAnywhereMessage.statisticsBack)),
            ),
            const SizedBox(width: LearnAnywhereTokens.gapMedium),
            Expanded(
              child: Text(
                breadcrumb,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Expanded(
          child: _PracticeList(
            deck: widget.deck,
            statistics: const <UnitStats>[],
            view: widget.view,
            selectedUnitIndices: widget.selectedUnitIndices,
            onSelectionChanged: widget.onSelectionChanged,
            onSaveSelected: widget.onSaveSelected,
            showBucketColumn: false,
            unitIndices: unitIndices,
            levelStatsOverride: override,
          ),
        ),
      ],
    );
  }

  String _levelNumberLabel(LearnAnywhereLocalizations messages, int level) {
    return messages
        .message(LearnAnywhereMessage.statisticsLevelNumber)
        .replaceAll('{level}', '$level');
  }

  static const TextStyle _boldStyle = TextStyle(fontWeight: FontWeight.bold);
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
    final double practicedFraction = summary.totalUnits == 0
        ? 0
        : summary.queriedUnits / summary.totalUnits;
    final int maxCount = math.max(
      1,
      summary.buckets
          .map((BucketSummary bucket) => bucket.count)
          .fold(0, math.max),
    );
    return ListView(
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.statisticsIncludesLevelZero),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
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
              value: '${summary.queriedUnits} (${_percent(practicedFraction)})',
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
              value:
                  '${summary.totalCorrect} '
                  '(${_percent(summary.attemptsHitRate ?? 0)})',
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: LearnAnywhereTokens.gapSmall,
            horizontalMargin: LearnAnywhereTokens.gapSmall,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 32,
            headingRowHeight: 32,
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
              const DataColumn(label: SizedBox.shrink()),
            ],
            rows: summary.buckets
                .map((BucketSummary bucket) {
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(_bucketLabel(messages, bucket.bucket))),
                      DataCell(Text(_bucketRange(bucket.bucket))),
                      DataCell(Text(bucket.count.toString())),
                      DataCell(Text(_percent(bucket.percentageOfAll))),
                      // "% of practiced" is meaningless for the units that
                      // have not been practiced at all — the engine reports a
                      // hard 0 there, so show nothing instead (same
                      // convention as _bucketRange for this bucket).
                      DataCell(
                        Text(
                          bucket.bucket == HitRateBucket.notYetQueried
                              ? ''
                              : _percent(bucket.percentageOfQueried),
                        ),
                      ),
                      DataCell(
                        _BucketBar(
                          fraction: bucket.count / maxCount,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
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

/// A compact inline horizontal bar sized to [fraction] (0..1), used beside a
/// bucket row to show its relative count without a separate chart tab.
final class _BucketBar extends StatelessWidget {
  const _BucketBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const double _maxWidth = 96;
  static const double _height = 14;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _maxWidth,
      height: _height,
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
          label: Text(
            messages.message(LearnAnywhereMessage.statisticsClearCurrent),
          ),
        ),
      ],
    );
  }
}

/// The overflow control beside the all-time scope selector, holding that
/// scope's single action: clear the deck's lifetime record.
///
/// Nothing destructive is visible on the screen; the command has to be opened
/// for. The trigger is a neutral icon precisely because the command behind it
/// is not — a filled, error-coloured button reads as *the* action of the
/// screen and invites the press it was meant to warn about. What actually
/// deters is the shell's confirmation: it names the deck, spells out that the
/// history goes, and holds the focus on Cancel.
///
/// Deliberately without an ALT mnemonic. The menu-bar accelerators are scoped
/// by hand in `main.dart` and gated on the *menu bar's* open count only (see
/// `docs/menu-alt-mnemonics.md`); a `MenuAcceleratorLabel` here would register
/// its letter into the app-wide registry from a menu that gating cannot see,
/// and collide with the top bar. Keyboard operation comes from ordinary
/// traversal instead: Tab reaches the trigger, Enter or Space opens it, the
/// single item takes the focus, Enter runs it and Escape closes.
final class _AllTimeOverflowMenu extends StatefulWidget {
  const _AllTimeOverflowMenu({required this.onClear});

  final Future<void> Function() onClear;

  @override
  State<_AllTimeOverflowMenu> createState() => _AllTimeOverflowMenuState();
}

final class _AllTimeOverflowMenuState extends State<_AllTimeOverflowMenu> {
  /// The trigger's own node, handed to [MenuAnchor.childFocusNode] so closing
  /// the menu puts the focus back where the learner opened it.
  final FocusNode _triggerFocusNode = FocusNode();

  @override
  void dispose() {
    _triggerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return MenuAnchor(
      childFocusNode: _triggerFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          // The menu opens for this one command, so it takes the focus: a
          // learner who opened it from the keyboard is already on it.
          autofocus: true,
          leadingIcon: Icon(Icons.warning_amber_rounded, color: colors.error),
          style: MenuItemButton.styleFrom(foregroundColor: colors.error),
          onPressed: widget.onClear,
          child: Text(
            messages.message(LearnAnywhereMessage.statisticsClearAllTime),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              focusNode: _triggerFocusNode,
              tooltip: messages.message(
                LearnAnywhereMessage.statisticsAllTimeMenu,
              ),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Icons.more_vert),
            );
          },
    );
  }
}

/// Standing notice that the all-time record has stopped reaching its file.
///
/// Not a status line: the refusal lasts until the deck is reopened, and a
/// message that scrolls away would leave the learner answering into nothing
/// again a minute later. It carries the error colour but not the clear
/// button's filled weight — it warns about a state, it offers no action.
final class _AllTimeNotRecordedNotice extends StatelessWidget {
  const _AllTimeNotRecordedNotice();

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(LearnAnywhereTokens.gapSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapSmall),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: LearnAnywhereTokens.gapSmall),
            Expanded(
              child: Text(
                messages.message(
                  LearnAnywhereMessage.statisticsAllTimeNotRecorded,
                ),
                style: TextStyle(color: colors.onErrorContainer),
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

/// Sortable columns of the Keep-practicing table, in display order.
enum _PracticeSortKey { unit, question, answer, bucket, attempts, accuracy }

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
  Map<int, DirectionStats>? statsOverride,
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
    final DirectionStats stats =
        statsOverride != null
        ? (statsOverride[index] ?? const DirectionStats())
        : statsForDirectionView(unitStats, view);
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
