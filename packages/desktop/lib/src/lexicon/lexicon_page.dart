import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Opens a folder picker and loads every `.vok` deck beneath the chosen folder
/// (recursively), keyed by source path. Returns null when the user cancels.
typedef PickFolderDecks =
    Future<Map<String, LearningDeck>?> Function();

/// Desktop Lexicon search page.
final class LexiconPage extends StatefulWidget {
  /// Creates a Lexicon page.
  const LexiconPage({
    required this.deck,
    required this.textOptions,
    required this.onPickFolderDecks,
    required this.onLoadFoundDeck,
    required this.onClose,
    this.maxResults = maxSearchResults,
    super.key,
  });

  /// Current in-memory deck.
  final LearningDeck deck;

  /// Search normalization options.
  final TextMatchOptions textOptions;

  /// Prompts for a folder and loads its `.vok` decks for a file search.
  final PickFolderDecks onPickFolderDecks;

  /// Replaces the in-memory deck with found units.
  final ValueChanged<LearningDeck> onLoadFoundDeck;

  /// Called when the user closes this page.
  final VoidCallback onClose;

  /// How many hits this screen is willing to show.
  ///
  /// The result table builds every row eagerly, so the cap is the screen's
  /// policy rather than the engine's; the engine enforces whatever it is told.
  /// Tests lower it to reach the truncated result line without 2000 units.
  final int maxResults;

  @override
  State<LexiconPage> createState() => _LexiconPageState();
}

final class _LexiconPageState extends State<LexiconPage> {
  final TextEditingController _queryController = TextEditingController();
  int? _categoryId;
  bool _loadFoundUnits = false;
  List<SearchResult> _results = const <SearchResult>[];

  /// Whether the last search had more hits than [LexiconPage.maxResults].
  bool _isTruncated = false;

  /// Decks loaded during the last file search, keyed by source path. Empty for
  /// a memory search (results then resolve against the in-memory deck).
  Map<String, LearningDeck> _fileDecks = const <String, LearningDeck>{};

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              messages.message(LearnAnywhereMessage.lexiconTitle),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Wrap(
              spacing: LearnAnywhereTokens.gapMedium,
              runSpacing: LearnAnywhereTokens.gapMedium,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      labelText: messages.message(
                        LearnAnywhereMessage.lexiconSearchText,
                      ),
                    ),
                    onSubmitted: (_) => _searchMemory(),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: messages.message(
                        LearnAnywhereMessage.lexiconCategoryScope,
                      ),
                    ),
                    initialValue: _categoryId,
                    items: <DropdownMenuItem<int?>>[
                      DropdownMenuItem<int?>(
                        child: Text(
                          messages.message(
                            LearnAnywhereMessage.lexiconAnyCategory,
                          ),
                        ),
                      ),
                      for (final CategoryDefinition category
                          in widget.deck.mask.categories)
                        DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (int? value) {
                      setState(() => _categoryId = value);
                    },
                  ),
                ),
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(
                        messages.message(
                          LearnAnywhereMessage.lexiconDisplayOnly,
                        ),
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(
                        messages.message(
                          LearnAnywhereMessage.lexiconLoadFoundUnits,
                        ),
                      ),
                    ),
                  ],
                  selected: <bool>{_loadFoundUnits},
                  onSelectionChanged: (Set<bool> value) {
                    setState(() => _loadFoundUnits = value.single);
                  },
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              _resultCountLine(messages),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: LearnAnywhereTokens.gapLarge,
                    ),
                    child: Text(
                      messages.message(LearnAnywhereMessage.lexiconNoResults),
                    ),
                  )
                : _ResultTable(
                    deck: widget.deck,
                    results: _results,
                    fileDecks: _fileDecks,
                  ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Wrap(
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _searchMemory,
                  icon: const Icon(Icons.memory),
                  label: Text(
                    messages.message(LearnAnywhereMessage.lexiconMemorySearch),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _searchFiles,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    messages.message(LearnAnywhereMessage.lexiconFileSearch),
                  ),
                ),
                if (_loadFoundUnits && _results.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _confirmLoadFoundUnits,
                    icon: const Icon(Icons.download),
                    label: Text(
                      messages.message(LearnAnywhereMessage.lexiconLoadResults),
                    ),
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
          ],
        ),
      ),
    );
  }

  /// The line above the result table: the hit count, or — when the cap cut the
  /// set short — a wording that says hits were left out, which a plain count
  /// could not distinguish from a complete set of exactly the cap's size.
  String _resultCountLine(LearnAnywhereLocalizations messages) {
    if (_isTruncated) {
      return messages
          .message(LearnAnywhereMessage.lexiconResultsTruncated)
          .replaceAll('{count}', '${_results.length}');
    }
    return '${messages.message(LearnAnywhereMessage.lexiconResults)}: '
        '${_results.length}';
  }

  void _searchMemory() {
    final SearchOutcome outcome = searchDeck(
      deck: widget.deck,
      query: _queryController.text,
      options: widget.textOptions,
      categoryId: _categoryId,
      maxResults: widget.maxResults,
    );
    setState(() {
      _results = outcome.results;
      _isTruncated = outcome.isTruncated;
      _fileDecks = const <String, LearningDeck>{};
    });
  }

  Future<void> _searchFiles() async {
    try {
      final Map<String, LearningDeck>? decks = await widget.onPickFolderDecks();
      if (decks == null || !mounted) {
        return;
      }
      final SearchOutcome outcome = searchDeckFiles(
        decksBySource: decks,
        query: _queryController.text,
        options: widget.textOptions,
        categoryId: _categoryId,
        maxResults: widget.maxResults,
      );
      setState(() {
        _fileDecks = decks;
        _results = outcome.results;
        _isTruncated = outcome.isTruncated;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _confirmLoadFoundUnits() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(
            messages.message(LearnAnywhereMessage.lexiconLoadWarning),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      widget.onLoadFoundDeck(_deckFromResults());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messages.message(LearnAnywhereMessage.lexiconLoadedResults),
          ),
        ),
      );
    } on _LexiconLoadException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messages.message(error.messageId))),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  /// Builds an in-memory deck from the current search hits.
  ///
  /// Memory-search hits resolve against the in-memory deck; file-search hits
  /// resolve against their own source deck ([_fileDecks]). All hits must
  /// describe the SAME mask (equal [LearningMask.maskId]); the first hit's mask
  /// is the reference. Each hit's unit is re-keyed onto the reference mask via
  /// [applyMaskToDeck], but only when that is lossless (per
  /// [checkMaskCompatibility]). A different maskId, or a lossy conversion, is
  /// refused with a localized [_LexiconLoadException].
  LearningDeck _deckFromResults() {
    if (_results.isEmpty) {
      return LearningDeck(
        mask: widget.deck.mask,
        units: const <LearningUnit>[],
      );
    }
    final LearningMask reference = _sourceDeckFor(_results.first).mask;
    final List<LearningUnit> units = <LearningUnit>[];
    for (final SearchResult result in _results) {
      final LearningDeck sourceDeck = _sourceDeckFor(result);
      if (sourceDeck.mask.maskId != reference.maskId) {
        throw const _LexiconLoadException(
          LearnAnywhereMessage.lexiconLoadMaskMismatch,
        );
      }
      final LearningUnit unit = sourceDeck.units[result.unitIndex - 1];
      final MaskCompatibilityResult compat = checkMaskCompatibility(
        oldMask: sourceDeck.mask,
        newMask: reference,
        units: <LearningUnit>[unit],
      );
      if (!compat.isCompatible) {
        throw const _LexiconLoadException(
          LearnAnywhereMessage.lexiconLoadWouldLoseData,
        );
      }
      final LearningDeck converted = applyMaskToDeck(
        LearningDeck(mask: sourceDeck.mask, units: <LearningUnit>[unit]),
        reference,
      );
      if (converted.units.isNotEmpty) {
        units.add(converted.units.first);
      }
    }
    return LearningDeck(
      mask: reference,
      units: List<LearningUnit>.unmodifiable(units),
    );
  }

  /// Resolves the deck a [result] came from: its file-search source deck, or
  /// the in-memory deck for a memory-search hit.
  LearningDeck _sourceDeckFor(SearchResult result) {
    final String? source = result.sourceFile;
    if (source == null) {
      return widget.deck;
    }
    final LearningDeck? deck = _fileDecks[source];
    if (deck == null) {
      throw StateError('Missing source deck for search result.');
    }
    return deck;
  }
}

/// A localizable failure while loading found Lexicon units into memory.
final class _LexiconLoadException implements Exception {
  const _LexiconLoadException(this.messageId);

  /// Catalog id of the user-facing message.
  final LearnAnywhereMessage messageId;
}

/// Renders search hits in the Keep-Practicing table style: Unit / Question /
/// Answer / Matched fields (plus Source file for a file search), each row
/// carrying a full-unit hover tooltip.
final class _ResultTable extends StatelessWidget {
  const _ResultTable({
    required this.deck,
    required this.results,
    required this.fileDecks,
  });

  final LearningDeck deck;
  final List<SearchResult> results;

  /// Decks loaded for a file-oriented search, keyed by source path. Used to
  /// resolve each hit's unit and category against its OWN deck (indices and
  /// category ids are only meaningful within one deck), falling back to the
  /// in-memory deck for a memory search.
  final Map<String, LearningDeck> fileDecks;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool showSource = results.any(
      (SearchResult result) => result.sourceFile != null,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: LearnAnywhereTokens.gapSmall,
        horizontalMargin: LearnAnywhereTokens.gapSmall,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 36,
        headingRowHeight: 36,
        columns: <DataColumn>[
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
          DataColumn(
            label: Text(
              messages.message(LearnAnywhereMessage.lexiconMatchedFields),
            ),
          ),
          if (showSource)
            DataColumn(
              label: Text(
                messages.message(LearnAnywhereMessage.lexiconSourceFile),
              ),
            ),
        ],
        rows: results.map((SearchResult result) {
          final LearningDeck source = _sourceDeck(result);
          final LearningUnit unit = source.units[result.unitIndex - 1];
          final CategoryDefinition category = source.categoryForUnit(unit);
          final String tooltip = _fieldsTooltip(unit, category);
          return DataRow(
            cells: <DataCell>[
              _tipCell(tooltip, Text(result.unitIndex.toString())),
              _tipCell(
                tooltip,
                Text(_fieldPreview(unit, category, FieldRole.question)),
              ),
              _tipCell(
                tooltip,
                Text(_fieldPreview(unit, category, FieldRole.answer)),
              ),
              _tipCell(tooltip, Text(result.matchedFieldNames.join(', '))),
              if (showSource)
                _tipCell(tooltip, Text(result.sourceFile ?? '')),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }

  LearningDeck _sourceDeck(SearchResult result) {
    final String? source = result.sourceFile;
    return (source == null ? null : fileDecks[source]) ?? deck;
  }
}

/// Wraps a table cell in a [Tooltip] showing the full unit listing.
DataCell _tipCell(String tooltip, Widget child) {
  return DataCell(Tooltip(message: tooltip, child: child));
}

/// Returns the truncated plain text of the first [role] field in direction 1.
String _fieldPreview(
  LearningUnit unit,
  CategoryDefinition category,
  FieldRole role,
) {
  final List<FieldDefinition> fields = category.fieldsForRole(
    QueryDirection.direction1,
    role,
  );
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
