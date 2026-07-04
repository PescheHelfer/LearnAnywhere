import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Integrated schema editor for a deck's embedded mask.
final class MaskEditorPage extends StatefulWidget {
  /// Creates the mask editor.
  const MaskEditorPage({
    required this.mask,
    required this.onChanged,
    this.onClose,
    super.key,
  });

  /// Mask currently edited in memory.
  final LearningMask mask;

  /// Called whenever the edited mask changes.
  final ValueChanged<LearningMask> onChanged;

  /// Called when the user closes this page.
  final VoidCallback? onClose;

  @override
  State<MaskEditorPage> createState() => _MaskEditorPageState();
}

final class _MaskEditorPageState extends State<MaskEditorPage> {
  int _selectedCategoryIndex = 0;

  @override
  void didUpdateWidget(MaskEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCategoryIndex >= widget.mask.categories.length) {
      _selectedCategoryIndex = widget.mask.categories.isEmpty
          ? 0
          : widget.mask.categories.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningMask mask = widget.mask;
    final CategoryDefinition? selectedCategory = mask.categories.isEmpty
        ? null
        : mask.categories[_selectedCategoryIndex];
    final VoidCallback? close = widget.onClose;
    final Widget page = SingleChildScrollView(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.routeMaskEditorTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          _MaskHeader(mask: mask, onChanged: _emitMask),
          const SizedBox(height: LearnAnywhereTokens.gapLarge),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 900;
              final Widget categories = _CategoryList(
                mask: mask,
                selectedIndex: _selectedCategoryIndex,
                onSelected: (int index) {
                  setState(() => _selectedCategoryIndex = index);
                },
                onAdd: _addCategory,
                onDelete: _deleteCategory,
                onRename: _renameCategory,
              );
              final Widget fields = _FieldGrid(
                category: selectedCategory,
                onAddField: _addField,
                onDeleteField: _deleteField,
                onFieldChanged: _changeField,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    categories,
                    const SizedBox(height: LearnAnywhereTokens.gapLarge),
                    fields,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 320, child: categories),
                  const SizedBox(width: LearnAnywhereTokens.gapLarge),
                  Expanded(child: fields),
                ],
              );
            },
          ),
          if (close != null) ...<Widget>[
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const ValueKey<String>('mask-editor-close-button'),
                onPressed: close,
                child: Text(messages.message(LearnAnywhereMessage.actionClose)),
              ),
            ),
          ],
        ],
      ),
    );
    if (close == null) {
      return page;
    }
    // The Close button is styled as the screen's default action, so Enter
    // should activate it the same way Esc (handled globally in main.dart)
    // already does.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _CloseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) {
              close();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: page),
      ),
    );
  }

  void _emitMask(LearningMask mask) {
    widget.onChanged(mask);
  }

  void _replaceCategories(List<CategoryDefinition> categories) {
    _emitMask(
      LearningMask(
        // Preserve the mask's identity: editing schema never mints a new
        // maskId (a fork is an explicit action) and never changes the revision
        // here (the revision is bumped when the .inf is saved).
        maskId: widget.mask.maskId,
        revision: widget.mask.revision,
        name: widget.mask.name,
        direction1Label: widget.mask.direction1Label,
        direction2Label: widget.mask.direction2Label,
        categories: List<CategoryDefinition>.unmodifiable(categories),
      ),
    );
  }

  void _addCategory() {
    if (widget.mask.categories.length >= maxCategoriesPerMask) {
      return;
    }
    final List<CategoryDefinition> categories = widget.mask.categories.toList();
    final int nextId = _nextCategoryId(categories);
    categories.add(
      CategoryDefinition(
        id: nextId,
        name: 'Category $nextId',
        fields: const <FieldDefinition>[],
      ),
    );
    setState(() => _selectedCategoryIndex = categories.length - 1);
    _replaceCategories(categories);
  }

  void _deleteCategory(int index) {
    if (index < 0 || index >= widget.mask.categories.length) {
      return;
    }
    final List<CategoryDefinition> categories = widget.mask.categories.toList()
      ..removeAt(index);
    setState(() {
      _selectedCategoryIndex = categories.isEmpty
          ? 0
          : _selectedCategoryIndex.clamp(0, categories.length - 1);
    });
    _replaceCategories(categories);
  }

  void _renameCategory(int index, String name) {
    final List<CategoryDefinition> categories = widget.mask.categories.toList();
    final CategoryDefinition category = categories[index];
    categories[index] = CategoryDefinition(
      id: category.id,
      name: name,
      fields: category.fields,
    );
    _replaceCategories(categories);
  }

  void _addField() {
    if (widget.mask.categories.isEmpty) {
      return;
    }
    final CategoryDefinition category =
        widget.mask.categories[_selectedCategoryIndex];
    if (category.fields.length >= maxFieldsPerCategory) {
      return;
    }
    final List<FieldDefinition> fields = category.fields.toList()
      ..add(
        FieldDefinition(
          id: _nextFieldId(widget.mask),
          name: '',
          length: 20,
          equalGroup: 0,
          role1: FieldRole.question,
          role2: FieldRole.answer,
        ),
      );
    _replaceSelectedCategory(category, fields);
  }

  void _deleteField(int index) {
    final CategoryDefinition category =
        widget.mask.categories[_selectedCategoryIndex];
    final List<FieldDefinition> fields = category.fields.toList()
      ..removeAt(index);
    _replaceSelectedCategory(category, fields);
  }

  void _changeField(int index, FieldDefinition field) {
    final CategoryDefinition category =
        widget.mask.categories[_selectedCategoryIndex];
    final List<FieldDefinition> fields = category.fields.toList();
    fields[index] = field;
    _replaceSelectedCategory(category, fields);
  }

  void _replaceSelectedCategory(
    CategoryDefinition category,
    List<FieldDefinition> fields,
  ) {
    final List<CategoryDefinition> categories = widget.mask.categories.toList();
    categories[_selectedCategoryIndex] = CategoryDefinition(
      id: category.id,
      name: category.name,
      fields: List<FieldDefinition>.unmodifiable(fields),
    );
    _replaceCategories(categories);
  }

  int _nextCategoryId(List<CategoryDefinition> categories) {
    // 0-based, never recycled: the next id is `max existing + 1`, or 0 when the
    // mask has no categories. Deleting a category does not renumber the rest.
    if (categories.isEmpty) {
      return 0;
    }
    return categories
            .map((CategoryDefinition category) => category.id)
            .reduce((int left, int right) => left > right ? left : right) +
        1;
  }

  int _nextFieldId(LearningMask mask) {
    // Field ids are unique across the WHOLE mask (see [FieldDefinition.id]), so
    // scan every category. 0-based, never recycled: `max existing + 1`, or 0
    // when the mask has no fields yet.
    var maxId = -1;
    for (final CategoryDefinition category in mask.categories) {
      for (final FieldDefinition field in category.fields) {
        if (field.id > maxId) {
          maxId = field.id;
        }
      }
    }
    return maxId + 1;
  }
}

final class _CloseIntent extends Intent {
  const _CloseIntent();
}

final class _MaskHeader extends StatelessWidget {
  const _MaskHeader({required this.mask, required this.onChanged});

  final LearningMask mask;
  final ValueChanged<LearningMask> onChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Wrap(
      spacing: LearnAnywhereTokens.gapMedium,
      runSpacing: LearnAnywhereTokens.gapMedium,
      children: <Widget>[
        SizedBox(
          width: 280,
          child: TextFormField(
            key: const ValueKey<String>('mask-name-field'),
            initialValue: mask.name,
            decoration: InputDecoration(
              labelText: messages.message(
                LearnAnywhereMessage.maskEditorMaskName,
              ),
            ),
            onChanged: (String value) {
              onChanged(
                LearningMask(
                  maskId: mask.maskId,
                  revision: mask.revision,
                  name: value,
                  direction1Label: mask.direction1Label,
                  direction2Label: mask.direction2Label,
                  categories: mask.categories,
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 240,
          child: TextFormField(
            key: const ValueKey<String>('direction-1-field'),
            initialValue: mask.direction1Label,
            decoration: InputDecoration(
              labelText: messages.message(
                LearnAnywhereMessage.maskEditorDirection1,
              ),
            ),
            onChanged: (String value) {
              onChanged(
                LearningMask(
                  maskId: mask.maskId,
                  revision: mask.revision,
                  name: mask.name,
                  direction1Label: value,
                  direction2Label: mask.direction2Label,
                  categories: mask.categories,
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 240,
          child: TextFormField(
            key: const ValueKey<String>('direction-2-field'),
            initialValue: mask.direction2Label,
            decoration: InputDecoration(
              labelText: messages.message(
                LearnAnywhereMessage.maskEditorDirection2,
              ),
            ),
            onChanged: (String value) {
              onChanged(
                LearningMask(
                  maskId: mask.maskId,
                  revision: mask.revision,
                  name: mask.name,
                  direction1Label: mask.direction1Label,
                  direction2Label: value,
                  categories: mask.categories,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.mask,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
    required this.onDelete,
    required this.onRename,
  });

  final LearningMask mask;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final void Function(int index, String name) onRename;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool atLimit = mask.categories.length >= maxCategoriesPerMask;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    messages.message(LearnAnywhereMessage.maskEditorCategories),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _withCount(
                    messages.message(
                      LearnAnywhereMessage.maskEditorCategoryCount,
                    ),
                    mask.categories.length,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            for (var index = 0; index < mask.categories.length; index += 1)
              _CategoryTile(
                category: mask.categories[index],
                selected: index == selectedIndex,
                index: index,
                onSelected: onSelected,
                onDelete: onDelete,
                onRename: onRename,
              ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey<String>('add-category-button'),
                onPressed: atLimit ? null : onAdd,
                icon: const Icon(Icons.add),
                label: Text(
                  atLimit
                      ? messages.message(
                          LearnAnywhereMessage.maskEditorLimitReached,
                        )
                      : messages.message(
                          LearnAnywhereMessage.maskEditorAddCategory,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.index,
    required this.onSelected,
    required this.onDelete,
    required this.onRename,
  });

  final CategoryDefinition category;
  final bool selected;
  final int index;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onDelete;
  final void Function(int index, String name) onRename;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
        borderRadius: LearnAnywhereTokens.smallRadius,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: LearnAnywhereTokens.smallRadius,
          child: Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapSmall),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    // Keyed by the category's stable id (not its list index) so
                    // switching or reordering categories always rebuilds a
                    // fresh controller instead of reusing a stale one that
                    // still holds another category's name.
                    key: ValueKey<String>('category-name-${category.id}'),
                    initialValue: category.name,
                    maxLength: maxCategoryNameLength,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: messages.message(
                        LearnAnywhereMessage.maskEditorCategoryName,
                      ),
                    ),
                    onTap: () => onSelected(index),
                    onChanged: (String value) => onRename(index, value),
                  ),
                ),
                IconButton(
                  tooltip: messages.message(
                    LearnAnywhereMessage.maskEditorDeleteCategory,
                  ),
                  onPressed: () => onDelete(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FieldGrid extends StatelessWidget {
  const _FieldGrid({
    required this.category,
    required this.onAddField,
    required this.onDeleteField,
    required this.onFieldChanged,
  });

  final CategoryDefinition? category;
  final VoidCallback onAddField;
  final ValueChanged<int> onDeleteField;
  final void Function(int index, FieldDefinition field) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final CategoryDefinition? category = this.category;
    final List<FieldDefinition> fields = category == null
        ? const <FieldDefinition>[]
        : category.fields;
    final bool atLimit = fields.length >= maxFieldsPerCategory;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    messages.message(LearnAnywhereMessage.maskEditorFields),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _withCount(
                    messages.message(LearnAnywhereMessage.maskEditorFieldCount),
                    fields.length,
                  ),
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
                      messages.message(
                        LearnAnywhereMessage.maskEditorFieldName,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      messages.message(
                        LearnAnywhereMessage.maskEditorFieldLength,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      messages.message(
                        LearnAnywhereMessage.maskEditorEqualGroup,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      messages.message(LearnAnywhereMessage.maskEditorRole1),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      messages.message(LearnAnywhereMessage.maskEditorRole2),
                    ),
                  ),
                  const DataColumn(label: SizedBox.shrink()),
                ],
                rows: <DataRow>[
                  for (var index = 0; index < fields.length; index += 1)
                    _fieldRow(
                      context,
                      messages,
                      category!.id,
                      index,
                      fields[index],
                    ),
                ],
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey<String>('add-field-button'),
                onPressed: category == null || atLimit ? null : onAddField,
                icon: const Icon(Icons.add),
                label: Text(
                  atLimit
                      ? messages.message(
                          LearnAnywhereMessage.maskEditorLimitReached,
                        )
                      : messages.message(
                          LearnAnywhereMessage.maskEditorAddField,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _fieldRow(
    BuildContext context,
    LearnAnywhereLocalizations messages,
    int categoryId,
    int index,
    FieldDefinition field,
  ) {
    // Row input keys embed the owning category's stable id so that selecting a
    // different category rebuilds fresh controllers. Keying by list index alone
    // let Flutter reuse another category's TextEditingControllers (whose text
    // is only seeded from initialValue once), scrambling the displayed fields.
    return DataRow(
      cells: <DataCell>[
        DataCell(
          SizedBox(
            width: 220,
            child: TextFormField(
              key: ValueKey<String>('field-name-$categoryId-$index'),
              initialValue: field.name,
              decoration: const InputDecoration(counterText: ''),
              onChanged: (String value) {
                onFieldChanged(index, _copyField(field, name: value));
              },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 96,
            child: TextFormField(
              key: ValueKey<String>('field-length-$categoryId-$index'),
              initialValue: field.length.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (String value) {
                final int? parsed = int.tryParse(value);
                if (parsed == null) {
                  return;
                }
                onFieldChanged(
                  index,
                  _copyField(
                    field,
                    length: parsed.clamp(minFieldLength, maxFieldLength),
                  ),
                );
              },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: TextFormField(
              key: ValueKey<String>('field-equal-group-$categoryId-$index'),
              initialValue: field.equalGroup.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (String value) {
                onFieldChanged(
                  index,
                  _copyField(field, equalGroup: int.tryParse(value) ?? 0),
                );
              },
            ),
          ),
        ),
        DataCell(
          _RoleMenu(
            key: ValueKey<String>('field-role1-$categoryId-$index'),
            value: field.role1,
            onChanged: (FieldRole value) {
              onFieldChanged(index, _copyField(field, role1: value));
            },
          ),
        ),
        DataCell(
          _RoleMenu(
            key: ValueKey<String>('field-role2-$categoryId-$index'),
            value: field.role2,
            onChanged: (FieldRole value) {
              onFieldChanged(index, _copyField(field, role2: value));
            },
          ),
        ),
        DataCell(
          IconButton(
            tooltip: messages.message(
              LearnAnywhereMessage.maskEditorDeleteField,
            ),
            onPressed: () => onDeleteField(index),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );
  }
}

final class _RoleMenu extends StatelessWidget {
  const _RoleMenu({required this.value, required this.onChanged, super.key});

  final FieldRole value;
  final ValueChanged<FieldRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<FieldRole>(
      value: value,
      items: FieldRole.values
          .map(
            (FieldRole role) => DropdownMenuItem<FieldRole>(
              value: role,
              child: Text(role.code),
            ),
          )
          .toList(growable: false),
      onChanged: (FieldRole? value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

FieldDefinition _copyField(
  FieldDefinition field, {
  String? name,
  int? length,
  int? equalGroup,
  FieldRole? role1,
  FieldRole? role2,
}) {
  return FieldDefinition(
    // The id is stable: renaming/retyping a field never changes it.
    id: field.id,
    name: name ?? field.name,
    length: length ?? field.length,
    equalGroup: equalGroup ?? field.equalGroup,
    role1: role1 ?? field.role1,
    role2: role2 ?? field.role2,
  );
}

String _withCount(String template, int count) {
  return template.replaceAll('{count}', count.toString());
}
