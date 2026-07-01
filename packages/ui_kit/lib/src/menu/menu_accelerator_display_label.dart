import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'menu_accelerator_builder.dart';

/// A display-only counterpart to [MenuAcceleratorLabel].
///
/// Renders the access-key highlight for a menu label exactly like
/// [MenuAcceleratorLabel] (using [menuAcceleratorBuilder] by default): the access
/// letter is highlighted while ALT is held and shown plain otherwise. Crucially,
/// it does **not** register an `Alt+<letter>` shortcut in the global
/// [ShortcutRegistry].
///
/// This widget exists because Flutter's [MenuAcceleratorLabel] registers every
/// accelerator into a single app-wide [ShortcutRegistry] with no per-open-menu
/// scoping, so the top-level menu-bar accelerators collide with the items of
/// whichever submenu is open. The desktop shell instead drives top-level menu
/// opening through a *gated* shortcut layer (a [CallbackShortcuts] that is
/// disabled while a menu is open) and uses this widget for the visual underline
/// only. See `docs/menu-alt-mnemonics.md` for the full rationale and the rules
/// for adding new menus.
class MenuAcceleratorDisplayLabel extends StatefulWidget {
  /// Creates a display-only accelerator label for [label].
  const MenuAcceleratorDisplayLabel(
    this.label, {
    super.key,
    this.builder = menuAcceleratorBuilder,
  });

  /// The label text, including any `&` accelerator markers.
  final String label;

  /// Builds the visual representation; defaults to [menuAcceleratorBuilder].
  final MenuAcceleratorChildBuilder builder;

  /// Returns the lower-case access character for [label], or `null` when the
  /// label carries no `&` accelerator marker.
  ///
  /// Used to wire the gated opening shortcut so the top-bar accelerators stay in
  /// sync with the localized label strings.
  static String? accessKeyOf(String label) {
    int index = -1;
    final String stripped = MenuAcceleratorLabel.stripAcceleratorMarkers(
      label,
      setIndex: (int i) => index = i,
    );
    if (index < 0 || index >= stripped.length) {
      return null;
    }
    return stripped[index].toLowerCase();
  }

  @override
  State<MenuAcceleratorDisplayLabel> createState() =>
      _MenuAcceleratorDisplayLabelState();
}

class _MenuAcceleratorDisplayLabelState
    extends State<MenuAcceleratorDisplayLabel> {
  late String _displayLabel;
  int _acceleratorIndex = -1;
  bool _altIsDown = false;

  /// Accelerators are only an idiom on Windows/Linux desktop, matching Flutter's
  /// own [MenuAcceleratorLabel] platform gate.
  bool get _platformSupportsAccelerators {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateDisplayLabel();
    if (_platformSupportsAccelerators) {
      _altIsDown = _altIsPressed();
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void didUpdateWidget(MenuAcceleratorDisplayLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.label != oldWidget.label) {
      _updateDisplayLabel();
    }
  }

  @override
  void dispose() {
    if (_platformSupportsAccelerators) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  static bool _altIsPressed() {
    return HardwareKeyboard.instance.logicalKeysPressed
        .intersection(<LogicalKeyboardKey>{
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
          LogicalKeyboardKey.alt,
        })
        .isNotEmpty;
  }

  bool _handleKeyEvent(KeyEvent event) {
    final bool alt = _altIsPressed();
    if (alt != _altIsDown && mounted) {
      setState(() => _altIsDown = alt);
    }
    // Only listening for the ALT state; never consumes the event.
    return false;
  }

  void _updateDisplayLabel() {
    _displayLabel = MenuAcceleratorLabel.stripAcceleratorMarkers(
      widget.label,
      setIndex: (int index) => _acceleratorIndex = index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int index =
        (_platformSupportsAccelerators && _altIsDown) ? _acceleratorIndex : -1;
    return widget.builder(context, _displayLabel, index);
  }
}
