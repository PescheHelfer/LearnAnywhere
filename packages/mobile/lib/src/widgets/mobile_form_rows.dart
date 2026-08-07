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
    super.key,
  });

  /// Field label.
  final String label;

  /// Current toggle state.
  final bool value;

  /// Called when the toggle changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
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
    super.key,
  });

  /// Field label.
  final String label;

  /// Current value.
  final int value;

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(MobileNumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String text = widget.value.toString();
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LearnAnywhereTokens.gapSmall,
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (String value) {
          var parsed = int.tryParse(value) ?? widget.minimum;
          if (parsed < widget.minimum) {
            parsed = widget.minimum;
          }
          final int? maximum = widget.maximum;
          if (maximum != null && parsed > maximum) {
            parsed = maximum;
          }
          widget.onChanged(parsed);
        },
      ),
    );
  }
}
