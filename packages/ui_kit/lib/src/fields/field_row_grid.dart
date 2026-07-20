import 'package:flutter/material.dart';

/// A bordered, horizontally-scrollable frame around a column of field rows.
///
/// Rows use fixed monospace column widths (see `FieldRow`) that can exceed the
/// viewport for long fields, so the grid scrolls horizontally rather than
/// shrinking the value boxes to fit. A hover/scroll scrollbar is shown, and the
/// rows are left-aligned so every row shares the same left edge regardless of
/// its width. Focused cells inside the rows can call
/// [Scrollable.ensureVisible] to auto-scroll themselves into view.
final class FieldRowGrid extends StatefulWidget {
  /// Creates a field-row grid around [rows].
  const FieldRowGrid({required this.rows, super.key});

  /// The pre-built field rows (typically `FieldRow` or `Builder` widgets). A
  /// 1px divider is inserted between consecutive rows.
  final List<Widget> rows;

  @override
  State<FieldRowGrid> createState() => _FieldRowGridState();
}

final class _FieldRowGridState extends State<FieldRowGrid> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < widget.rows.length; i++) {
      if (i > 0) {
        children.add(Container(height: 1, color: colors.outlineVariant));
      }
      children.add(widget.rows[i]);
    }
    return Scrollbar(
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
