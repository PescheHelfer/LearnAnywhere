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
  final ValueChanged<LearningDeck> onChanged;

  /// Called when the user closes the editor.
  final VoidCallback onDone;

  /// Called when the user cancels the editor.
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
    final List<LearningUnit> units = widget.deck.units.toList();
    units.insert(_currentIndex, _newUnitFor(category));
    _replaceUnits(units);
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
    final List<LearningUnit> units = widget.deck.units.toList()
      ..removeAt(_currentIndex);
    _replaceUnits(units);
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

  void _updateCurrentUnitField(String fieldName, FieldValue value) {
    final LearningUnit unit = widget.deck.units[_currentIndex];
    final Map<String, FieldValue> fields = Map<String, FieldValue>.from(
      unit.fields,
    );
    fields[fieldName] = value;
    final LearningUnit updated = LearningUnit(
      categoryId: unit.categoryId,
      fields: Map<String, FieldValue>.unmodifiable(fields),
    );
    final List<LearningUnit> units = widget.deck.units.toList();
    units[_currentIndex] = updated;
    _replaceUnits(units);
  }

  LearningUnit _newUnitFor(CategoryDefinition category) {
    return LearningUnit(
      categoryId: category.id,
      fields: <String, FieldValue>{
        for (final FieldDefinition field in category.fields)
          if (!field.isHidden) field.name: FieldValue.empty,
      },
    );
  }

  void _replaceUnits(List<LearningUnit> units) {
    widget.onChanged(
      LearningDeck(
        mask: widget.deck.mask,
        units: List<LearningUnit>.unmodifiable(units),
      ),
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

final class _EditorBody extends StatelessWidget {
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
  final void Function(String fieldName, FieldValue value) onFieldChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onJump;
  final VoidCallback onInsertBefore;
  final VoidCallback onDelete;
  final VoidCallback onSearch;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = deck.units[currentIndex];
    final CategoryDefinition category = deck.categoryForUnit(unit);
    final List<FieldDefinition> fields = category.fields
        .where((FieldDefinition field) => !field.isHidden)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _unitHeader(
              messages,
              currentIndex + 1,
              deck.units.length,
              category.name,
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          Wrap(
            spacing: LearnAnywhereTokens.gapSmall,
            runSpacing: LearnAnywhereTokens.gapSmall,
            children: <Widget>[
              _ActionButton(
                icon: Icons.arrow_back,
                label: messages.message(LearnAnywhereMessage.editorPrevious),
                shortcut: 'F2',
                onPressed: currentIndex == 0 ? null : onPrevious,
              ),
              _ActionButton(
                icon: Icons.arrow_forward,
                label: messages.message(LearnAnywhereMessage.editorNext),
                shortcut: 'F3',
                onPressed: onNext,
              ),
              _ActionButton(
                icon: Icons.numbers,
                label: messages.message(LearnAnywhereMessage.editorJump),
                shortcut: 'F6',
                onPressed: onJump,
              ),
              _ActionButton(
                icon: Icons.add,
                label: messages.message(
                  LearnAnywhereMessage.editorInsertBefore,
                ),
                shortcut: 'F8',
                onPressed: onInsertBefore,
              ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: messages.message(LearnAnywhereMessage.editorDelete),
                shortcut: 'F7',
                onPressed: onDelete,
              ),
              _ActionButton(
                icon: Icons.search,
                label: messages.message(LearnAnywhereMessage.editorSearch),
                shortcut: 'F5',
                onPressed: onSearch,
              ),
              _ActionButton(
                icon: Icons.check,
                label: messages.message(LearnAnywhereMessage.editorDone),
                shortcut: 'F10',
                onPressed: onDone,
              ),
              _ActionButton(
                icon: Icons.close,
                label: messages.message(LearnAnywhereMessage.editorCancel),
                shortcut: 'Esc',
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: LearnAnywhereTokens.gapLarge),
          Expanded(
            child: ListView.separated(
              itemCount: fields.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: LearnAnywhereTokens.gapMedium),
              itemBuilder: (BuildContext context, int index) {
                final FieldDefinition field = fields[index];
                final bool isLastField = index == fields.length - 1;
                return _FieldValueEditor(
                  key: ValueKey<String>(
                    'editor-field-${currentIndex}-${index}-${field.name}',
                  ),
                  field: field,
                  value: unit.valueForField(field.name),
                  colorMemory: colorMemory,
                  onNext: isLastField ? onNext : null,
                  onChanged: (FieldValue value) {
                    onFieldChanged(field.name, value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _FieldValueEditor extends StatefulWidget {
  const _FieldValueEditor({
    required this.field,
    required this.value,
    required this.colorMemory,
    required this.onChanged,
    this.onNext,
    super.key,
  });

  final FieldDefinition field;
  final FieldValue value;
  final _ColorMemory colorMemory;
  final ValueChanged<FieldValue> onChanged;

  /// When non-null, Enter and Tab (without Shift) in this field call [onNext].
  final VoidCallback? onNext;

  @override
  State<_FieldValueEditor> createState() => _FieldValueEditorState();
}

final class _FieldValueEditorState extends State<_FieldValueEditor> {
  late final LearnAnywhereRichTextEditingController _controller;
  late final FocusNode _focusNode;
  late FieldValue _lastReported;

  @override
  void initState() {
    super.initState();
    _controller = LearnAnywhereRichTextEditingController(value: widget.value);
    _lastReported = widget.value;
    _controller.addListener(_onControllerChanged);
    _focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (widget.onNext != null &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isShiftPressed) {
          widget.onNext!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void didUpdateWidget(_FieldValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload only when the host swapped in a genuinely different value (e.g. a
    // unit change), not when our own edits round-tripped back unchanged.
    if (widget.value != _controller.fieldValue) {
      _lastReported = widget.value;
      _controller.loadValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final FieldValue value = _controller.fieldValue;
    if (value != _lastReported) {
      _lastReported = value;
      widget.onChanged(value);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;
    final RunFormat active = _controller.activeFormat;
    final double width = math.min(
      780,
      math.max(260, widget.field.length * 12 + 32),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.field.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            ExcludeFocus(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: LearnAnywhereTokens.gapSmall,
                runSpacing: LearnAnywhereTokens.gapSmall,
                children: <Widget>[
                  Text(messages.message(LearnAnywhereMessage.editorFormatting)),
                  _FormatIconButton(
                    tooltip: messages.message(LearnAnywhereMessage.editorBold),
                    icon: Icons.format_bold,
                    selected: _controller.selectionSatisfies(
                      (RunFormat f) => f.bold,
                    ),
                    onPressed: () => _toggleBold(),
                  ),
                  _FormatIconButton(
                    tooltip: messages.message(LearnAnywhereMessage.editorItalic),
                    icon: Icons.format_italic,
                    selected: _controller.selectionSatisfies(
                      (RunFormat f) => f.italic,
                    ),
                    onPressed: () => _toggleItalic(),
                  ),
                  _FormatIconButton(
                    tooltip: messages.message(
                      LearnAnywhereMessage.editorUnderline,
                    ),
                    icon: Icons.format_underline,
                    selected: _controller.selectionSatisfies(
                      (RunFormat f) => f.underline,
                    ),
                    onPressed: () => _toggleUnderline(),
                  ),
                  _ColorPickerButton(
                    tooltip: messages.message(LearnAnywhereMessage.editorColor),
                    icon: Icons.format_color_text,
                    swatches: LearnAnywherePalette.textColors,
                    selectedHex: active.color,
                    indicator: active.color == null
                        ? null
                        : colorFromHex(active.color!),
                    onSelected: _applyColor,
                  ),
                  _ColorPickerButton(
                    tooltip: messages.message(
                      LearnAnywhereMessage.editorHighlight,
                    ),
                    icon: Icons.format_color_fill,
                    swatches: LearnAnywherePalette.highlightsFor(brightness),
                    selectedHex: active.highlight,
                    indicator: active.highlight == null
                        ? null
                        : colorFromHex(
                            LearnAnywherePalette.highlightForBrightness(
                              active.highlight!,
                              brightness,
                            ),
                          ),
                    onSelected: _applyHighlight,
                  ),
                  _FormatIconButton(
                    tooltip: messages.message(
                      LearnAnywhereMessage.editorClearFormatting,
                    ),
                    icon: Icons.format_clear,
                    selected: false,
                    onPressed: _controller.clearFormatting,
                  ),
                ],
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            SizedBox(
              width: width,
              child: TextField(
                key: ValueKey<String>('editor-input-${widget.field.name}'),
                focusNode: _focusNode,
                controller: _controller,
                maxLines: 1,
                textInputAction: widget.onNext != null
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: widget.onNext != null
                    ? (String _) => widget.onNext!()
                    : null,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(widget.field.length),
                ],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
                ),
                decoration: InputDecoration(
                  counterText:
                      '${_controller.text.length}/${widget.field.length}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBold() {
    final bool active = _controller.selectionSatisfies((RunFormat f) => f.bold);
    _controller.formatSelection((RunFormat f) => f.copyWith(bold: !active));
  }

  void _toggleItalic() {
    final bool active = _controller.selectionSatisfies(
      (RunFormat f) => f.italic,
    );
    _controller.formatSelection((RunFormat f) => f.copyWith(italic: !active));
  }

  void _toggleUnderline() {
    final bool active = _controller.selectionSatisfies(
      (RunFormat f) => f.underline,
    );
    _controller.formatSelection(
      (RunFormat f) => f.copyWith(underline: !active),
    );
  }

  void _applyColor(String? hex) {
    widget.colorMemory.lastTextColor = hex;
    _controller.formatSelection((RunFormat f) => f.withColor(hex));
  }

  void _applyHighlight(String? hex) {
    widget.colorMemory.lastHighlight = hex;
    _controller.formatSelection((RunFormat f) => f.withHighlight(hex));
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

final class _FormatIconButton extends StatelessWidget {
  const _FormatIconButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      icon: Icon(icon),
      selectedIcon: Icon(icon),
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
final class _ColorPickerButton extends StatelessWidget {
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
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return MenuAnchor(
      menuChildren: swatches.map((LearnAnywhereColorSwatch swatch) {
        final bool selected = swatch.hex == selectedHex;
        return MenuItemButton(
          leadingIcon: _SwatchDot(
            color: swatch.color,
            selected: selected,
          ),
          onPressed: () => onSelected(swatch.hex),
          child: Text(messages.message(swatch.label)),
        );
      }).toList(growable: false),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              tooltip: tooltip,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon),
                  Container(
                    width: 20,
                    height: 3,
                    margin: const EdgeInsets.only(top: 1),
                    color: indicator ?? colors.outlineVariant,
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
