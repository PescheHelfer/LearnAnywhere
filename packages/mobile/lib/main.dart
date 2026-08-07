import 'dart:math';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'src/mobile_file_service.dart';

void main() {
  runApp(const LearnAnywhereMobileApp());
}

/// Android companion app for read-only Learn Anywhere practice.
final class LearnAnywhereMobileApp extends StatefulWidget {
  /// Creates the Android companion app.
  const LearnAnywhereMobileApp({this.fileService, super.key});

  /// File service used to manage the library and persist statistics.
  final MobileFileService? fileService;

  @override
  State<LearnAnywhereMobileApp> createState() => _LearnAnywhereMobileAppState();
}

final class _LearnAnywhereMobileAppState extends State<LearnAnywhereMobileApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          LearnAnywhereLocalizations.of(context).appTitle,
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: MobileLibraryScreen(fileService: widget.fileService ?? MobileFileService()),
    );
  }
}

/// Library home screen: lists decks, and imports, opens or deletes them.
final class MobileLibraryScreen extends StatefulWidget {
  /// Creates the library screen.
  const MobileLibraryScreen({required this.fileService, super.key});

  /// File service used to list, import, open and delete decks.
  final MobileFileService fileService;

  @override
  State<MobileLibraryScreen> createState() => _MobileLibraryScreenState();
}

final class _MobileLibraryScreenState extends State<MobileLibraryScreen> {
  List<LibraryDeckEntry>? _entries;
  String? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final List<LibraryDeckEntry> entries = await widget.fileService
        .listDecks();
    if (!mounted) {
      return;
    }
    setState(() => _entries = entries);
  }

  Future<void> _import() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    try {
      final int count = await widget.fileService.importDecks();
      if (count == 0) {
        return;
      }
      await _refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages
            .message(LearnAnywhereMessage.mobileImportSuccess)
            .replaceAll('{count}', count.toString());
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages.message(LearnAnywhereMessage.mobileImportFailed);
      });
    }
  }

  Future<void> _open(LibraryDeckEntry entry) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    try {
      final MobileDeckDocument document = await widget.fileService.openDeck(
        entry.path,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => MobileSessionScreen(
            document: document,
            fileService: widget.fileService,
          ),
        ),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages.message(LearnAnywhereMessage.mobileDeckLoadFailed);
      });
    }
  }

  Future<void> _delete(LibraryDeckEntry entry) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              messages.message(
                LearnAnywhereMessage.mobileDeleteDeckConfirmTitle,
              ),
            ),
            content: Text(
              messages.message(
                LearnAnywhereMessage.mobileDeleteDeckConfirmBody,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  messages.message(LearnAnywhereMessage.mobileDeleteDeck),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await widget.fileService.deleteDeck(entry.path);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<LibraryDeckEntry>? entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.mobileLibraryTitle)),
        actions: <Widget>[
          IconButton(
            tooltip: messages.message(LearnAnywhereMessage.mobileImportDecks),
            onPressed: _import,
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: entries == null
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
            ? _LibraryEmptyState(status: _status, onImport: _import)
            : _LibraryList(
                entries: entries,
                status: _status,
                onOpen: _open,
                onDelete: _delete,
              ),
      ),
    );
  }
}

final class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.onImport, this.status});

  final VoidCallback onImport;
  final String? status;

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
            const Icon(Icons.school_outlined, size: 56),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              messages.message(LearnAnywhereMessage.mobileLibraryEmptyTitle),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            Text(
              messages.message(LearnAnywhereMessage.mobileLibraryEmptyBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                messages.message(LearnAnywhereMessage.mobileImportDecks),
              ),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Text(status!),
            ],
          ],
        ),
      ),
    );
  }
}

final class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.entries,
    required this.onOpen,
    required this.onDelete,
    this.status,
  });

  final List<LibraryDeckEntry> entries;
  final ValueChanged<LibraryDeckEntry> onOpen;
  final ValueChanged<LibraryDeckEntry> onDelete;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      children: <Widget>[
        if (status != null)
          Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapSmall),
            child: Text(status!, style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final LibraryDeckEntry entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(entry.name),
                subtitle: Text(
                  '${messages.message(LearnAnywhereMessage.mobileUnits)}: '
                  '${entry.unitCount}',
                ),
                onTap: () => onOpen(entry),
                trailing: IconButton(
                  tooltip: messages.message(
                    LearnAnywhereMessage.mobileDeleteDeck,
                  ),
                  onPressed: () => onDelete(entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Mobile read-only learning session for one already-opened deck.
final class MobileSessionScreen extends StatefulWidget {
  /// Creates the mobile learning session screen.
  const MobileSessionScreen({
    required this.document,
    required this.fileService,
    super.key,
  });

  /// Deck opened from the library, plus its loaded statistics.
  final MobileDeckDocument document;

  /// File service used to persist statistics.
  final MobileFileService fileService;

  @override
  State<MobileSessionScreen> createState() => _MobileSessionScreenState();
}

enum _MobileSessionStage { setup, prompt, reveal, rating, completed }

final class _MobileSessionScreenState extends State<MobileSessionScreen> {
  final Random _random = Random();
  final Set<SessionItem> _seenItems = <SessionItem>{};
  final SessionParameters _parameters = const SessionParameters(
    withInput: false,
    mode: SessionMode.onceThrough,
  );

  late MobileDeckDocument _document;
  _MobileSessionStage _stage = _MobileSessionStage.setup;
  SessionItem? _currentItem;
  // Think-only default is "Knew it" (like desktop): the one-tap fast path
  // records a correct attempt unless the user picks otherwise.
  AttemptRating _selectedRating = AttemptRating.correct;
  int _sessionAttempts = 0;
  int _sessionCorrect = 0;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
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
          parameters: _parameters,
          attempts: _sessionAttempts,
          correct: _sessionCorrect,
        ),
        Expanded(
          child: switch (_stage) {
            _MobileSessionStage.setup => _MobileSetupView(
              document: _document,
              onStart: _startSession,
            ),
            _MobileSessionStage.prompt when item != null => _PromptView(
              document: _document,
              item: item,
            ),
            _MobileSessionStage.reveal when item != null => _RevealView(
              document: _document,
              item: item,
            ),
            _MobileSessionStage.rating when item != null => _RatingView(
              selected: _selectedRating,
              onChanged: (AttemptRating value) {
                setState(() => _selectedRating = value);
              },
            ),
            _MobileSessionStage.completed => _CompletedView(
              onExtend: _extendSession,
            ),
            _ => _MobileSetupView(document: _document, onStart: _startSession),
          },
        ),
        if (_stage != _MobileSessionStage.setup &&
            _stage != _MobileSessionStage.completed)
          _MobileBottomAction(
            stage: _stage,
            onNext: _next,
            onContinue: _continueAfterRating,
          ),
      ],
    );
  }

  void _startSession() {
    setState(() {
      _seenItems.clear();
      _sessionAttempts = 0;
      _sessionCorrect = 0;
      _selectNextItem();
    });
  }

  void _extendSession() {
    setState(() {
      _seenItems.clear();
      _selectNextItem();
    });
  }

  void _next() {
    setState(() {
      _stage = switch (_stage) {
        _MobileSessionStage.prompt => _MobileSessionStage.reveal,
        _MobileSessionStage.reveal => _MobileSessionStage.rating,
        _ => _stage,
      };
    });
  }

  Future<void> _continueAfterRating() async {
    final SessionItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final List<UnitStats> updated = _recordRating(
      _document,
      item,
      _selectedRating,
    );
    final MobileDeckDocument updatedDocument = _document.copyWith(
      statistics: updated,
    );
    setState(() {
      _document = updatedDocument;
      if (_selectedRating != AttemptRating.noCount) {
        _sessionAttempts += 1;
      }
      if (_selectedRating == AttemptRating.correct) {
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
      recordAttempt(current.statsFor(item.direction), rating),
    );
    return List<UnitStats>.unmodifiable(stats);
  }

  List<UnitStats> _normalizedStats(MobileDeckDocument document) {
    return resizeUnitStats(document.statistics, document.deck.units.length);
  }

  void _selectNextItem() {
    final SessionItem? next = pickPracticeItem(
      deck: _document.deck,
      parameters: _parameters,
      random: _random,
      seenItems: _seenItems,
    );
    if (next == null) {
      _currentItem = null;
      _stage = _MobileSessionStage.completed;
      return;
    }
    _seenItems.add(next);
    _currentItem = next;
    _selectedRating = AttemptRating.correct;
    _stage = _MobileSessionStage.prompt;
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

final class _MobileSetupView extends StatelessWidget {
  const _MobileSetupView({required this.document, required this.onStart});

  final MobileDeckDocument document;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: Text(messages.message(LearnAnywhereMessage.learnStartSession)),
        ),
      ),
    );
  }
}

final class _PromptView extends StatelessWidget {
  const _PromptView({required this.document, required this.item});

  final MobileDeckDocument document;
  final SessionItem item;

  @override
  Widget build(BuildContext context) {
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    return _UnitScaffold(
      document: document,
      item: item,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          child: _FieldGroup(
            title: LearnAnywhereLocalizations.of(
              context,
            ).message(LearnAnywhereMessage.learnPrompt),
            fields: promptFields(document.deck, unit, item.direction),
            large: true,
          ),
        ),
      ),
    );
  }
}

final class _RevealView extends StatelessWidget {
  const _RevealView({required this.document, required this.item});

  final MobileDeckDocument document;
  final SessionItem item;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = document.deck.units[item.unitIndex - 1];
    return _UnitScaffold(
      document: document,
      item: item,
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
    );
  }
}

final class _RatingView extends StatelessWidget {
  const _RatingView({required this.selected, required this.onChanged});

  final AttemptRating selected;
  final ValueChanged<AttemptRating> onChanged;

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
            Text(
              messages.message(LearnAnywhereMessage.mobileRatePrompt),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Wrap(
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _RatingChip(
                  rating: AttemptRating.correct,
                  selected: selected,
                  label: messages.message(
                    LearnAnywhereMessage.learnRatingKnewIt,
                  ),
                  onChanged: onChanged,
                ),
                _RatingChip(
                  rating: AttemptRating.wrong,
                  selected: selected,
                  label: messages.message(
                    LearnAnywhereMessage.learnRatingDidNotKnow,
                  ),
                  onChanged: onChanged,
                ),
                _RatingChip(
                  rating: AttemptRating.noCount,
                  selected: selected,
                  label: messages.message(
                    LearnAnywhereMessage.learnRatingNoCount,
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final AttemptRating rating;
  final AttemptRating selected;
  final String label;
  final ValueChanged<AttemptRating> onChanged;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == rating,
      onSelected: (_) => onChanged(rating),
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

final class _MobileBottomAction extends StatelessWidget {
  const _MobileBottomAction({
    required this.stage,
    required this.onNext,
    required this.onContinue,
  });

  final _MobileSessionStage stage;
  final VoidCallback onNext;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool rating = stage == _MobileSessionStage.rating;
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: rating ? onContinue : onNext,
          icon: Icon(rating ? Icons.check : Icons.arrow_forward),
          label: Text(
            rating
                ? messages.message(LearnAnywhereMessage.learnContinue)
                : messages.message(LearnAnywhereMessage.mobileNext),
          ),
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
