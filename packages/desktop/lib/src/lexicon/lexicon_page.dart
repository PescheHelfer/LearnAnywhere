import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Loads decks for a file-oriented Lexicon search.
typedef LoadDecksByPattern =
    Future<Map<String, LearningDeck>> Function(String pattern);

/// Desktop Lexicon search page.
final class LexiconPage extends StatefulWidget {
  /// Creates a Lexicon page.
  const LexiconPage({
    required this.deck,
    required this.textOptions,
    required this.loadDecksByPattern,
    required this.onLoadFoundDeck,
    required this.onClose,
    super.key,
  });

  /// Current in-memory deck.
  final LearningDeck deck;

  /// Search normalization options.
  final TextMatchOptions textOptions;

  /// Loads deck files matching a simple mask.
  final LoadDecksByPattern loadDecksByPattern;

  /// Replaces the in-memory deck with found units.
  final ValueChanged<LearningDeck> onLoadFoundDeck;

  /// Called when the user closes this page.
  final VoidCallback onClose;

  @override
  State<LexiconPage> createState() => _LexiconPageState();
}

final class _LexiconPageState extends State<LexiconPage> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _patternController = TextEditingController(
    text: '*.vok',
  );
  int? _categoryId;
  bool _loadFoundUnits = false;
  List<SearchResult> _results = const <SearchResult>[];
  Map<String, LearningDeck> _fileDecks = const <String, LearningDeck>{};
  bool _lastSearchWasFileSearch = false;

  @override
  void dispose() {
    _queryController.dispose();
    _patternController.dispose();
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
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _patternController,
                    decoration: InputDecoration(
                      labelText: messages.message(
                        LearnAnywhereMessage.lexiconFilePattern,
                      ),
                    ),
                    onSubmitted: (_) => _searchFiles(),
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
              '${messages.message(LearnAnywhereMessage.lexiconResults)}: ${_results.length}',
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
                : _ResultList(deck: widget.deck, results: _results),
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
                if (_lastSearchWasFileSearch &&
                    _loadFoundUnits &&
                    _results.isNotEmpty)
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

  void _searchMemory() {
    setState(() {
      _results = searchDeck(
        deck: widget.deck,
        query: _queryController.text,
        options: widget.textOptions,
        categoryId: _categoryId,
      );
      _fileDecks = const <String, LearningDeck>{};
      _lastSearchWasFileSearch = false;
    });
  }

  Future<void> _searchFiles() async {
    try {
      final Map<String, LearningDeck> decks = await widget.loadDecksByPattern(
        _patternController.text,
      );
      setState(() {
        _fileDecks = decks;
        _results = searchDeckFiles(
          decksBySource: decks,
          query: _queryController.text,
          options: widget.textOptions,
          categoryId: _categoryId,
        );
        _lastSearchWasFileSearch = true;
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
      widget.onLoadFoundDeck(_deckFromFileResults());
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
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  LearningDeck _deckFromFileResults() {
    if (_results.isEmpty) {
      return LearningDeck(
        mask: widget.deck.mask,
        units: const <LearningUnit>[],
      );
    }
    final String? firstSource = _results.first.sourceFile;
    final LearningDeck? firstDeck = firstSource == null
        ? null
        : _fileDecks[firstSource];
    if (firstDeck == null) {
      throw StateError('Missing source deck for search result.');
    }
    final String maskJson = encodeMaskJson(firstDeck.mask);
    final List<LearningUnit> units = <LearningUnit>[];
    for (final SearchResult result in _results) {
      final String? source = result.sourceFile;
      final LearningDeck? sourceDeck = source == null
          ? null
          : _fileDecks[source];
      if (sourceDeck == null) {
        throw StateError('Missing source deck for search result.');
      }
      if (encodeMaskJson(sourceDeck.mask) != maskJson) {
        throw StateError(
          'Cannot load found units from decks with different masks.',
        );
      }
      units.add(sourceDeck.units[result.unitIndex - 1]);
    }
    return LearningDeck(
      mask: firstDeck.mask,
      units: List<LearningUnit>.unmodifiable(units),
    );
  }
}

final class _ResultList extends StatelessWidget {
  const _ResultList({required this.deck, required this.results});

  final LearningDeck deck;
  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final SearchResult result = results[index];
        final CategoryDefinition? category = deck.mask.categoryById(
          result.categoryId,
        );
        return ListTile(
          title: Text(
            '${messages.message(LearnAnywhereMessage.statisticsUnit)} ${result.unitIndex} - ${category?.name ?? result.categoryId}',
          ),
          subtitle: Text(
            <String>[
              if (result.sourceFile != null)
                '${messages.message(LearnAnywhereMessage.lexiconSourceFile)}: ${result.sourceFile}',
              '${messages.message(LearnAnywhereMessage.lexiconMatchedFields)}: ${result.matchedFieldNames.join(', ')}',
            ].join('\n'),
          ),
          isThreeLine: result.sourceFile != null,
        );
      },
    );
  }
}
