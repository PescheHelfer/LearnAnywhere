import 'package:flutter/material.dart';

/// The speaker icon that reads one field aloud.
///
/// Small enough to sit beside a field row without pushing it past the width
/// the unit editor's counter already claims. Its size is fixed at every zoom
/// level, as `docs/adr/0002-zoom-scales-the-theme-not-the-text-scaler.md`
/// requires of icons and chrome: the text beside it grows, the icon does not.
/// Shared by both shells; the rule for when it appears lives in the core
/// speech policy, never here.
///
/// It never takes focus. A learner clicking it mid-answer is asking to hear a
/// word, not to leave the box they are typing in.
final class SpeakerButton extends StatefulWidget {
  /// Creates a speaker button labelled [tooltip].
  const SpeakerButton({
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  /// Speaks the field this button sits beside.
  ///
  /// Always live, including when no voice was found for the field's language:
  /// pressing it then explains the silence, which a disabled button could not.
  final VoidCallback onPressed;

  /// What the button says it does, on hover and to a screen reader.
  final String tooltip;

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

final class _SpeakerButtonState extends State<SpeakerButton> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  /// The icon size, at every zoom level.
  static const double _iconSize = 18;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      focusNode: _focusNode,
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      icon: const Icon(Icons.volume_up),
      iconSize: _iconSize,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(
        width: _iconSize + 6,
        height: _iconSize + 6,
      ),
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
