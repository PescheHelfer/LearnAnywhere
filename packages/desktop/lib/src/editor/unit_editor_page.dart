import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Desktop deck/unit editor with legacy shortcut parity.
final class UnitEditorPage extends StatefulWidget {
  /// Creates a unit editor for [deck].
  const UnitEditorPage({
    required this.deck,
    required this.onChanged,
    required this.onDone,
    required this.onCancel,
    this.initialIndex,
    this.onCurrentIndexChanged,
    super.key,
  });

  /// Current in-memory deck.
  final LearningDeck deck;

  /// Called whenever the deck units change.
  ///
  /// The `insertedAt` / `deletedAt` arguments carry the 1-based unit position
  /// of a structural change so the host can remap per-unit statistics; both are
  /// null for an in-place field edit or an append (the host keeps/pads stats).
  final void Function(LearningDeck deck, {int? insertedAt, int? deletedAt})
  onChanged;

  /// Called when the user finishes editing (F10/Done), keeping changes.
  final VoidCallback onDone;

  /// Called when the user cancels the editor (Esc); the host confirms and
  /// reverts to the snapshot taken when the editor opened.
  final VoidCallback onCancel;

  /// If non-null, the editor opens at this 0-based unit index on construction
  /// and whenever the value changes. Clamped to the valid range automatically.
  final int? initialIndex;

  /// Called whenever the user navigates to a different unit.
  final ValueChanged<int>? onCurrentIndexChanged;

  /// Shows the jump-to-unit dialog and returns the selected 0-based index, or
  /// null if cancelled. [currentIndex] pre-fills the unit-number input.
  static Future<int?> openJumpDialog(
    BuildContext context,
    LearningDeck deck, {
    int currentIndex = 0,
  }) async {
    if (deck.units.isEmpty) return null;
    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    final TextEditingController controller = TextEditingController(
      text: (currentIndex + 1).toString(),
    );
    final int? target = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.editorJumpTitle)),
          content: TextField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: messages.message(
                LearnAnywhereMessage.editorJumpLabel,
              ),
            ),
            onSubmitted: (String value) =>
                Navigator.of(ctx).pop(int.tryParse(value)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(int.tryParse(controller.text)),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    if (target == null) return null;
    return (target - 1).clamp(0, deck.units.length - 1);
  }

  /// Shows the search dialog (and a results dialog on match) and returns the
  /// selected 0-based unit index, or null if cancelled or no result chosen.
  static Future<int?> openSearchDialog(
    BuildContext context,
    LearningDeck deck,
  ) async {
    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    final String? query = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.editorSearchTitle),
          ),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(
              labelText: messages.message(
                LearnAnywhereMessage.editorSearchQuery,
              ),
            ),
            onSubmitted: (String value) =>
                Navigator.of(ctx).pop(value.trim()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(messages.message(LearnAnywhereMessage.editorSearch)),
            ),
          ],
        );
      },
    );
    if (query == null || query.isEmpty) return null;

    final List<SearchResult> results = searchDeck(deck: deck, query: query);
    if (results.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              messages.message(LearnAnywhereMessage.editorNoMatches),
            ),
          ),
        );
      }
      return null;
    }

    if (!context.mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.editorSearchResults),
          ),
          content: SizedBox(
            width: 520,
            height: 360,
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (BuildContext _, int index) {
                final SearchResult result = results[index];
                final CategoryDefinition? category =
                    deck.mask.categoryById(result.categoryId);
                return ListTile(
                  title: Text(
                    _unitHeader(
                      messages,
                      result.unitIndex,
                      deck.units.length,
                      category?.name ?? result.categoryId.toString(),
                    ),
                  ),
                  subtitle: Text(result.matchedFieldNames.join(', ')),
                  onTap: () => Navigator.of(ctx).pop(result.unitIndex - 1),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<UnitEditorPage> createState() => _UnitEditorPageState();
}

final class _UnitEditorPageState extends State<UnitEditorPage> {
  static const Map<ShortcutActivator, Intent> _kShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): _EnterIntent(),
    SingleActivator(LogicalKeyboardKey.f1): _HelpIntent(),
    SingleActivator(LogicalKeyboardKey.f2): _PreviousIntent(),
    SingleActivator(LogicalKeyboardKey.f3): _NextIntent(),
    SingleActivator(LogicalKeyboardKey.f5): _SearchIntent(),
    SingleActivator(LogicalKeyboardKey.f6): _JumpIntent(),
    SingleActivator(LogicalKeyboardKey.f7): _DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.f8): _InsertIntent(),
    SingleActivator(LogicalKeyboardKey.f10): _DoneIntent(),
    SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
  };

  int _currentIndex = 0;
  CategoryDefinition? _lastUsedCategory;
  final FocusNode _rootFocusNode = FocusNode();
  final _ColorMemory _colorMemory = _ColorMemory();

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!.clamp(
        0,
        math.max(0, widget.deck.units.length - 1),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(UnitEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != null &&
        widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = widget.initialIndex!.clamp(
        0,
        math.max(0, widget.deck.units.length - 1),
      );
    } else {
      _clampCurrentIndex();
    }
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _kShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _EnterIntent: CallbackAction<_EnterIntent>(
            onInvoke: (_) {
              if (widget.deck.units.isEmpty) _appendUnit();
              return null;
            },
          ),
          _HelpIntent: CallbackAction<_HelpIntent>(
            onInvoke: (_) {
              _showHelp();
              return null;
            },
          ),
          _PreviousIntent: CallbackAction<_PreviousIntent>(
            onInvoke: (_) {
              _previous();
              return null;
            },
          ),
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_) {
              _next();
              return null;
            },
          ),
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) {
              _search();
              return null;
            },
          ),
          _JumpIntent: CallbackAction<_JumpIntent>(
            onInvoke: (_) {
              _jump();
              return null;
            },
          ),
          _DeleteIntent: CallbackAction<_DeleteIntent>(
            onInvoke: (_) {
              _delete();
              return null;
            },
          ),
          _InsertIntent: CallbackAction<_InsertIntent>(
            onInvoke: (_) {
              _insertBefore();
              return null;
            },
          ),
          _DoneIntent: CallbackAction<_DoneIntent>(
            onInvoke: (_) {
              widget.onDone();
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) {
              widget.onCancel();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _rootFocusNode,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: widget.deck.units.isEmpty
                ? _EmptyEditor(onInsert: _appendUnit)
                : _EditorBody(
                    deck: widget.deck,
                    currentIndex: _currentIndex,
                    colorMemory: _colorMemory,
                    onFieldChanged: _updateCurrentUnitField,
                    onPrevious: _previous,
                    onNext: _next,
                    onJump: _jump,
                    onInsertBefore: _insertBefore,
                    onDelete: _delete,
                    onSearch: _search,
                    onDone: widget.onDone,
                    onCancel: widget.onCancel,
                  ),
          ),
        ),
      ),
    );
  }

  void _clampCurrentIndex() {
    final int count = widget.deck.units.length;
    if (count == 0) {
      _currentIndex = 0;
      return;
    }
    _currentIndex = _currentIndex.clamp(0, count - 1);
  }

  Future<void> _appendUnit() async {
    final CategoryDefinition? category = await _chooseCategory();
    if (category == null) {
      return;
    }
    final List<LearningUnit> units = widget.deck.units.toList();
    units.add(_newUnitFor(category));
    // Append: no existing unit index shifts, so the host keeps stats as-is.
    _replaceUnits(units);
    setState(() => _currentIndex = units.length - 1);
    widget.onCurrentIndexChanged?.call(_currentIndex);
  }

  Future<void> _insertBefore() async {
    if (widget.deck.units.isEmpty) {
      await _appendUnit();
      return;
    }
    final CategoryDefinition? category = await _chooseCategory();
    if (category == null) {
      return;
    }
    // 1-based position of the newly inserted unit (units.insert at 0-based
    // _currentIndex puts it there, i.e. 1-based _currentIndex + 1).
    final int insertedAt = _currentIndex + 1;
    final List<LearningUnit> units = widget.deck.units.toList();
    units.insert(_currentIndex, _newUnitFor(category));
    _replaceUnits(units, insertedAt: insertedAt);
    setState(() => _currentIndex = _currentIndex.clamp(0, units.length - 1));
    widget.onCurrentIndexChanged?.call(_currentIndex);
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex -= 1);
      widget.onCurrentIndexChanged?.call(_currentIndex);
    }
  }

  Future<void> _next() async {
    if (widget.deck.units.isEmpty ||
        _currentIndex == widget.deck.units.length - 1) {
      await _appendUnit();
      return;
    }
    setState(() => _currentIndex += 1);
    widget.onCurrentIndexChanged?.call(_currentIndex);
  }

  Future<void> _jump() async {
    if (widget.deck.units.isEmpty) return;
    final int? index = await UnitEditorPage.openJumpDialog(
      context,
      widget.deck,
      currentIndex: _currentIndex,
    );
    if (index != null && mounted) {
      setState(() => _currentIndex = index);
      widget.onCurrentIndexChanged?.call(_currentIndex);
    }
  }

  Future<void> _delete() async {
    if (widget.deck.units.isEmpty) {
      return;
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(
            messages.message(LearnAnywhereMessage.editorDeleteConfirm),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(messages.message(LearnAnywhereMessage.editorDelete)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    // 1-based position of the unit being removed, captured before mutation.
    final int deletedAt = _currentIndex + 1;
    final List<LearningUnit> units = widget.deck.units.toList()
      ..removeAt(_currentIndex);
    _replaceUnits(units, deletedAt: deletedAt);
    setState(() {
      if (units.isEmpty) {
        _currentIndex = 0;
      } else {
        _currentIndex = _currentIndex.clamp(0, units.length - 1);
      }
    });
    widget.onCurrentIndexChanged?.call(_currentIndex);
  }

  Future<void> _search() async {
    final int? index = await UnitEditorPage.openSearchDialog(
      context,
      widget.deck,
    );
    if (index != null && mounted) {
      setState(() => _currentIndex = index);
    }
  }

  Future<CategoryDefinition?> _chooseCategory() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<CategoryDefinition> categories = widget.deck.mask.categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messages.message(LearnAnywhereMessage.editorNoCategories),
          ),
        ),
      );
      return null;
    }
    // Pre-select the last-used category if still present, otherwise the first.
    CategoryDefinition selected = categories.firstWhere(
      (CategoryDefinition c) => c.id == (_lastUsedCategory?.id ?? -1),
      orElse: () => categories.first,
    );
    final CategoryDefinition? result = await showDialog<CategoryDefinition>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            return AlertDialog(
              title: Text(
                messages.message(
                  LearnAnywhereMessage.editorChooseCategoryTitle,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (BuildContext _, int index) {
                    final CategoryDefinition cat = categories[index];
                    return ListTile(
                      title: Text(cat.name),
                      selected: cat == selected,
                      trailing: cat == selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => setInnerState(() => selected = cat),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    messages.message(LearnAnywhereMessage.actionCancel),
                  ),
                ),
                FilledButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: Text(
                    messages.message(LearnAnywhereMessage.actionContinue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      _lastUsedCategory = result;
    }
    return result;
  }

  void _showHelp() {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.editorHelpTitle)),
          content: Text(messages.message(LearnAnywhereMessage.desktopHintBar)),
          actions: <Widget>[
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateCurrentUnitField(int fieldId, FieldValue value) {
    final LearningUnit unit = widget.deck.units[_currentIndex];
    final Map<int, FieldValue> fields = Map<int, FieldValue>.from(unit.fields);
    fields[fieldId] = value;
    final LearningUnit updated = LearningUnit(
      categoryId: unit.categoryId,
      fields: Map<int, FieldValue>.unmodifiable(fields),
    );
    final List<LearningUnit> units = widget.deck.units.toList();
    units[_currentIndex] = updated;
    _replaceUnits(units);
  }

  LearningUnit _newUnitFor(CategoryDefinition category) {
    return LearningUnit(
      categoryId: category.id,
      fields: <int, FieldValue>{
        for (final FieldDefinition field in category.fields)
          if (!field.isHidden) field.id: FieldValue.empty,
      },
    );
  }

  void _replaceUnits(
    List<LearningUnit> units, {
    int? insertedAt,
    int? deletedAt,
  }) {
    widget.onChanged(
      LearningDeck(
        mask: widget.deck.mask,
        units: List<LearningUnit>.unmodifiable(units),
      ),
      insertedAt: insertedAt,
      deletedAt: deletedAt,
    );
  }
}

final class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor({required this.onInsert});

  final VoidCallback onInsert;

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
            messages.message(LearnAnywhereMessage.editorEmptyTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          Text(messages.message(LearnAnywhereMessage.editorEmptyBody)),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          FilledButton.icon(
            onPressed: onInsert,
            icon: const Icon(Icons.add),
            label: Text(
              messages.message(LearnAnywhereMessage.editorInsertUnit),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editor body (stateful to host the shared formatting toolbar) ────────────

final class _EditorBody extends StatefulWidget {
  const _EditorBody({
    required this.deck,
    required this.currentIndex,
    required this.colorMemory,
    required this.onFieldChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
    required this.onInsertBefore,
    required this.onDelete,
    required this.onSearch,
    required this.onDone,
    required this.onCancel,
  });

  final LearningDeck deck;
  final int currentIndex;
  final _ColorMemory colorMemory;
  final void Function(int fieldId, FieldValue value) onFieldChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onJump;
  final VoidCallback onInsertBefore;
  final VoidCallback onDelete;
  final VoidCallback onSearch;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

final class _EditorBodyState extends State<_EditorBody> {
  // The controller and focus node that currently have keyboard focus — drive toolbar state.
  LearnAnywhereRichTextEditingController? _activeController;
  _ColorMemory? _activeColorMemory;
  FocusNode? _activeFocusNode;

  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_EditorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the user navigates to a different unit the grid rows are rebuilt
    // from scratch, so the previously-registered controller is gone.
    if (widget.currentIndex != oldWidget.currentIndex) {
      _activeController?.removeListener(_onActiveControllerChanged);
      _activeController = null;
      _activeColorMemory = null;
    }
  }

  @override
  void dispose() {
    _activeController?.removeListener(_onActiveControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _registerActive(
    LearnAnywhereRichTextEditingController controller,
    _ColorMemory colorMemory,
    FocusNode focusNode,
  ) {
    if (_activeController == controller) return;
    _activeController?.removeListener(_onActiveControllerChanged);
    _activeController = controller;
    _activeColorMemory = colorMemory;
    _activeFocusNode = focusNode;
    _activeController!.addListener(_onActiveControllerChanged);
    if (mounted) setState(() {});
  }

  void _onActiveControllerChanged() {
    if (mounted) setState(() {});
  }

  // ── Toolbar formatting helpers ───────────────────────────────────────────

  void _toggleBold() {
    final LearnAnywhereRichTextEditingController? c = _activeController;
    if (c == null) return;
    final bool active = c.selectionSatisfies((RunFormat f) => f.bold);
    c.formatSelection((RunFormat f) => f.copyWith(bold: !active));
    _activeFocusNode?.requestFocus();
  }

  void _toggleItalic() {
    final LearnAnywhereRichTextEditingController? c = _activeController;
    if (c == null) return;
    final bool active = c.selectionSatisfies((RunFormat f) => f.italic);
    c.formatSelection((RunFormat f) => f.copyWith(italic: !active));
    _activeFocusNode?.requestFocus();
  }

  void _toggleUnderline() {
    final LearnAnywhereRichTextEditingController? c = _activeController;
    if (c == null) return;
    final bool active = c.selectionSatisfies((RunFormat f) => f.underline);
    c.formatSelection((RunFormat f) => f.copyWith(underline: !active));
    _activeFocusNode?.requestFocus();
  }

  void _applyColor(String? hex) {
    _activeColorMemory?.lastTextColor = hex;
    _activeController?.formatSelection((RunFormat f) => f.withColor(hex));
    _activeFocusNode?.requestFocus();
  }

  void _applyHighlight(String? hex) {
    _activeColorMemory?.lastHighlight = hex;
    _activeController?.formatSelection((RunFormat f) => f.withHighlight(hex));
    _activeFocusNode?.requestFocus();
  }

  void _clearFormatting() {
    _activeController?.clearFormatting();
    _activeFocusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    final LearningUnit unit = widget.deck.units[widget.currentIndex];
    final CategoryDefinition category = widget.deck.categoryForUnit(unit);
    final List<FieldDefinition> fields = category.fields
        .where((FieldDefinition f) => !f.isHidden)
        .toList(growable: false);

    // Which field index should receive initial focus for this unit?
    // First blank field wins; if all filled, focus the last field with cursor at end.
    int autoFocusIndex = 0;
    bool allFilled = true;
    for (int k = 0; k < fields.length; k++) {
      if (unit.valueForFieldId(fields[k].id).isBlank) {
        autoFocusIndex = k;
        allFilled = false;
        break;
      }
    }
    if (allFilled && fields.isNotEmpty) {
      autoFocusIndex = fields.length - 1;
    }

    final LearnAnywhereRichTextEditingController? ac = _activeController;
    final RunFormat activeFormat = ac?.activeFormat ?? RunFormat.none;

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Compact header with inline formatting toolbar ──────────────
            Row(
              children: <Widget>[
                ExcludeFocus(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: LearnAnywhereTokens.gapSmall,
                    runSpacing: LearnAnywhereTokens.gapSmall,
                    children: <Widget>[
                      _FormatIconButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorBold,
                        ),
                        icon: Icons.format_bold,
                        selected:
                            ac?.selectionSatisfies(
                              (RunFormat f) => f.bold,
                            ) ??
                            false,
                        onPressed: ac != null ? _toggleBold : null,
                      ),
                      _FormatIconButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorItalic,
                        ),
                        icon: Icons.format_italic,
                        selected:
                            ac?.selectionSatisfies(
                              (RunFormat f) => f.italic,
                            ) ??
                            false,
                        onPressed: ac != null ? _toggleItalic : null,
                      ),
                      _FormatIconButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorUnderline,
                        ),
                        icon: Icons.format_underline,
                        selected:
                            ac?.selectionSatisfies(
                              (RunFormat f) => f.underline,
                            ) ??
                            false,
                        onPressed: ac != null ? _toggleUnderline : null,
                      ),
                      _ColorPickerButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorColor,
                        ),
                        icon: Icons.format_color_text,
                        swatches: LearnAnywherePalette.textColors,
                        selectedHex: activeFormat.color,
                        indicator: activeFormat.color == null
                            ? null
                            : colorFromHex(activeFormat.color!),
                        onSelected: ac != null ? _applyColor : null,
                      ),
                      _ColorPickerButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorHighlight,
                        ),
                        icon: Icons.format_color_fill,
                        swatches: LearnAnywherePalette.highlightsFor(
                          brightness,
                        ),
                        selectedHex: activeFormat.highlight,
                        indicator: activeFormat.highlight == null
                            ? null
                            : colorFromHex(
                                LearnAnywherePalette.highlightForBrightness(
                                  activeFormat.highlight!,
                                  brightness,
                                ),
                              ),
                        onSelected: ac != null ? _applyHighlight : null,
                      ),
                      _FormatIconButton(
                        tooltip: messages.message(
                          LearnAnywhereMessage.editorClearFormatting,
                        ),
                        icon: Icons.format_clear,
                        selected: false,
                        onPressed: ac != null ? _clearFormatting : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LearnAnywhereTokens.gapSmall),
                Flexible(
                  child: Text(
                    _unitHeader(
                      messages,
                      widget.currentIndex + 1,
                      widget.deck.units.length,
                      category.name,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            // ── Field grid ────────────────────────────────────────────────
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < fields.length; i++) ...<Widget>[
                      if (i > 0)
                        Container(height: 1, color: colors.outlineVariant),
                      _GridRow(
                        key: ValueKey<String>(
                          'editor-field-${widget.currentIndex}-$i-${fields[i].name}',
                        ),
                        field: fields[i],
                        value: unit.valueForFieldId(fields[i].id),
                        colorMemory: widget.colorMemory,
                        autofocus: i == autoFocusIndex,
                        moveToEnd: allFilled && i == autoFocusIndex,
                        onNext: i == fields.length - 1
                            ? widget.onNext
                            : null,
                        onChanged: (FieldValue v) {
                          widget.onFieldChanged(fields[i].id, v);
                        },
                        onFocusGained: _registerActive,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            // ── Action buttons (bottom) ────────────────────────────────────
            Wrap(
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: <Widget>[
                _ActionButton(
                  icon: Icons.arrow_back,
                  label: messages.message(LearnAnywhereMessage.editorPrevious),
                  shortcut: 'F2',
                  onPressed: widget.currentIndex == 0 ? null : widget.onPrevious,
                ),
                _ActionButton(
                  icon: Icons.arrow_forward,
                  label: messages.message(LearnAnywhereMessage.editorNext),
                  shortcut: 'F3',
                  onPressed: widget.onNext,
                ),
                _ActionButton(
                  icon: Icons.numbers,
                  label: messages.message(LearnAnywhereMessage.editorJump),
                  shortcut: 'F6',
                  onPressed: widget.onJump,
                ),
                _ActionButton(
                  icon: Icons.add,
                  label: messages.message(
                    LearnAnywhereMessage.editorInsertBefore,
                  ),
                  shortcut: 'F8',
                  onPressed: widget.onInsertBefore,
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: messages.message(LearnAnywhereMessage.editorDelete),
                  shortcut: 'F7',
                  onPressed: widget.onDelete,
                ),
                _ActionButton(
                  icon: Icons.search,
                  label: messages.message(LearnAnywhereMessage.editorSearch),
                  shortcut: 'F5',
                  onPressed: widget.onSearch,
                ),
                _ActionButton(
                  icon: Icons.check,
                  label: messages.message(LearnAnywhereMessage.editorDone),
                  shortcut: 'F10',
                  onPressed: widget.onDone,
                ),
                _ActionButton(
                  icon: Icons.close,
                  label: messages.message(LearnAnywhereMessage.editorCancel),
                  shortcut: 'Esc',
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact two-column grid row ─────────────────────────────────────────────

final class _GridRow extends StatefulWidget {
  const _GridRow({
    required this.field,
    required this.value,
    required this.colorMemory,
    required this.onChanged,
    required this.onFocusGained,
    this.autofocus = false,
    this.moveToEnd = false,
    this.onNext,
    super.key,
  });

  final FieldDefinition field;
  final FieldValue value;
  final _ColorMemory colorMemory;
  final ValueChanged<FieldValue> onChanged;

  /// Called when this row's text field gains focus; lets the parent toolbar
  /// track which controller is currently active.
  final void Function(
    LearnAnywhereRichTextEditingController,
    _ColorMemory,
    FocusNode,
  ) onFocusGained;

  /// Whether this field should claim keyboard focus when it first appears.
  final bool autofocus;

  /// When true together with [autofocus], moves the cursor to the end of the
  /// existing text after focus is claimed.
  final bool moveToEnd;

  /// When non-null, Enter/Tab on this (last) field calls [onNext] instead of
  /// advancing within the grid.
  final VoidCallback? onNext;

  @override
  State<_GridRow> createState() => _GridRowState();
}

final class _GridRowState extends State<_GridRow> {
  late final LearnAnywhereRichTextEditingController _controller;
  late final FocusNode _focusNode;
  late FieldValue _lastReported;

  @override
  void initState() {
    super.initState();
    _controller = LearnAnywhereRichTextEditingController(value: widget.value);
    _lastReported = widget.value;
    _controller.addListener(_onControllerChanged);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _focusNode.addListener(_onFocusChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        if (widget.moveToEnd) {
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(_GridRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.fieldValue) {
      _lastReported = widget.value;
      _controller.loadValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onFocusGained(_controller, widget.colorMemory, _focusNode);
    }
  }

  void _onControllerChanged() {
    final FieldValue value = _controller.fieldValue;
    if (value != _lastReported) {
      _lastReported = value;
      widget.onChanged(value);
    }
    if (mounted) setState(() {});
  }

  // Enter and forward-Tab both advance focus; on the last field they hand off
  // to onNext (next unit). Shift+Tab uses Flutter's default backward traversal.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    final bool isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    final bool isForwardTab =
        key == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed;
    if (!isEnter && !isForwardTab) return KeyEventResult.ignored;
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      node.nextFocus();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double bgOpacity =
        Theme.of(context).brightness == Brightness.light ? 0.15 : 0.10;

    final Color accentColor;
    switch (widget.field.role1) {
      case FieldRole.question:
        accentColor = const Color.fromRGBO(0, 150, 180, 1);
      case FieldRole.answer:
        accentColor = const Color.fromRGBO(0, 160, 80, 1);
      case FieldRole.remark:
        accentColor = const Color.fromRGBO(200, 140, 0, 1);
    }
    final Color bgColor = accentColor.withValues(alpha: bgOpacity);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Left accent bar
          Container(width: 4, color: accentColor),
          // Label (fixed width)
          Container(
            width: 120,
            color: bgColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.field.name,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(width: 1, color: colors.outlineVariant),
          // Editable cell
          Expanded(
            child: ColoredBox(
              color: bgColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _controller,
                        maxLines: 1,
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(widget.field.length),
                        ],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamilyFallback:
                              LearnAnywhereTokens.monospaceFallback,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 0,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.text.length}/${widget.field.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.shortcut,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final Widget labelWidget = shortcut != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label),
              Text(shortcut!, style: const TextStyle(fontSize: 10)),
            ],
          )
        : Text(label);
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: labelWidget,
    );
  }
}

final class _FormatIconButton extends StatefulWidget {
  const _FormatIconButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  State<_FormatIconButton> createState() => _FormatIconButtonState();
}

final class _FormatIconButtonState extends State<_FormatIconButton> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      focusNode: _focusNode,
      tooltip: widget.tooltip,
      isSelected: widget.selected,
      onPressed: widget.onPressed,
      iconSize: 15,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(8.5),
      icon: Icon(widget.icon),
      selectedIcon: Icon(widget.icon),
    );
  }
}

/// Session-scoped, in-memory record of the last colors the user picked.
final class _ColorMemory {
  /// Last-used text color hex, or null for the default option.
  String? lastTextColor;

  /// Last-used highlight hex, or null for the no-highlight option.
  String? lastHighlight;
}

/// A toolbar button that opens a palette popover and applies the chosen color.
///
/// Selecting a swatch applies that color to the current selection (or stores it
/// as the active insertion-point color when nothing is selected).
final class _ColorPickerButton extends StatefulWidget {
  const _ColorPickerButton({
    required this.tooltip,
    required this.icon,
    required this.swatches,
    required this.selectedHex,
    required this.indicator,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final List<LearnAnywhereColorSwatch> swatches;
  final String? selectedHex;
  final Color? indicator;
  final ValueChanged<String?>? onSelected;

  @override
  State<_ColorPickerButton> createState() => _ColorPickerButtonState();
}

final class _ColorPickerButtonState extends State<_ColorPickerButton> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return MenuAnchor(
      menuChildren: widget.swatches.map((LearnAnywhereColorSwatch swatch) {
        final bool selected = swatch.hex == widget.selectedHex;
        return MenuItemButton(
          leadingIcon: _SwatchDot(
            color: swatch.color,
            selected: selected,
          ),
          onPressed: widget.onSelected == null
              ? null
              : () => widget.onSelected!(swatch.hex),
          child: Text(messages.message(swatch.label)),
        );
      }).toList(growable: false),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              focusNode: _focusNode,
              tooltip: widget.tooltip,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              iconSize: 15,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(8.5),
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(widget.icon, size: 15),
                  Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(top: 1),
                    color: widget.indicator ?? colors.outlineVariant,
                  ),
                ],
              ),
            );
          },
    );
  }
}

/// A small color dot used inside the picker palette, with a checkered backdrop
/// for the default/none (null color) entry.
final class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color, required this.selected});

  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 3 : 1,
        ),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: color == null
            ? Icon(Icons.format_color_reset, size: 12, color: colors.outline)
            : null,
      ),
    );
  }
}

String _unitHeader(
  LearnAnywhereLocalizations messages,
  int index,
  int total,
  String category,
) {
  return messages
      .message(LearnAnywhereMessage.editorUnitHeader)
      .replaceAll('{index}', index.toString())
      .replaceAll('{total}', total.toString())
      .replaceAll('{category}', category);
}

final class _EnterIntent extends Intent {
  const _EnterIntent();
}

final class _HelpIntent extends Intent {
  const _HelpIntent();
}

final class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

final class _NextIntent extends Intent {
  const _NextIntent();
}

final class _SearchIntent extends Intent {
  const _SearchIntent();
}

final class _JumpIntent extends Intent {
  const _JumpIntent();
}

final class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

final class _InsertIntent extends Intent {
  const _InsertIntent();
}

final class _DoneIntent extends Intent {
  const _DoneIntent();
}

final class _CancelIntent extends Intent {
  const _CancelIntent();
}
