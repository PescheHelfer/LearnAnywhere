import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// A labelled dropdown row shared by the setup and settings screens.
final class MobileDropdownRow<T> extends StatelessWidget {
  /// Creates a dropdown row.
  const MobileDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  /// Field label.
  final String label;

  /// Currently selected value.
  final T value;

  /// Selectable items.
  final List<DropdownMenuItem<T>> items;

  /// Called when the selection changes.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LearnAnywhereTokens.gapSmall,
      ),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(labelText: label),
        initialValue: value,
        items: items,
        onChanged: (T? next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

/// A labelled switch row shared by the setup and settings screens.
final class MobileToggleRow extends StatelessWidget {
  /// Creates a toggle row.
  const MobileToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
    super.key,
  });

  /// Field label.
  final String label;

  /// Current toggle state.
  final bool value;

  /// Called when the toggle changes.
  final ValueChanged<bool> onChanged;

  /// Shown on a long press, or nothing when null.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget row = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
    final String? tooltip = this.tooltip;
    return tooltip == null ? row : Tooltip(message: tooltip, child: row);
  }
}

/// A labelled bounded-integer text field shared by the setup and settings
/// screens.
final class MobileNumberRow extends StatefulWidget {
  /// Creates a number row.
  const MobileNumberRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum,
    this.enabled = true,
    this.onEditingDone,
    super.key,
  });

  /// Field label.
  final String label;

  /// Current value.
  final int value;

  /// Called once editing ends (the field loses focus, which "Done" on the
  /// keyboard also does), after the value has settled.
  final VoidCallback? onEditingDone;

  /// Inclusive lower bound.
  final int minimum;

  /// Inclusive upper bound, or unbounded when null.
  final int? maximum;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called with the clamped parsed value on every edit.
  final ValueChanged<int> onChanged;

  @override
  State<MobileNumberRow> createState() => _MobileNumberRowState();
}

final class _MobileNumberRowState extends State<MobileNumberRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(MobileNumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Never rewrite the field the user is typing in. Doing so is what made the
    // leading digit undeletable: clearing "45" down to "" reported the minimum
    // back up, which came straight back as text and refilled the field.
    if (_focusNode.hasFocus) {
      return;
    }
    _setText(widget.value.toString());
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Replaces the field's text, keeping the caret at the end.
  ///
  /// `TextEditingController.text =` collapses the selection to offset -1, which
  /// renders as a caret pinned before the first character — the reason editing
  /// previously required typing ahead of the old digit and deleting backwards.
  void _setText(String text) {
    if (_controller.text == text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Normalizes the field once editing ends, so an empty or out-of-range entry
  /// settles on a legal value instead of fighting the user mid-keystroke.
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      return;
    }
    final int settled = _clamp(int.tryParse(_controller.text));
    _setText(settled.toString());
    if (settled != widget.value) {
      widget.onChanged(settled);
    }
    widget.onEditingDone?.call();
  }

  int _clamp(int? value) {
    if (value == null) {
      // Left empty: keep whatever the parent already holds rather than
      // snapping to the minimum, which silently discarded a range the user had
      // only meant to retype.
      return widget.value;
    }
    if (value < widget.minimum) {
      return widget.minimum;
    }
    final int? maximum = widget.maximum;
    if (maximum != null && value > maximum) {
      return maximum;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LearnAnywhereTokens.gapSmall,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (String _) => _focusNode.unfocus(),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (String value) {
          // While typing, report only what parses, clamped, and leave the text
          // alone. An empty field reports nothing at all, so it can stay empty
          // long enough to type a replacement.
          final int? parsed = int.tryParse(value);
          if (parsed == null) {
            return;
          }
          widget.onChanged(_clamp(parsed));
        },
      ),
    );
  }
}
